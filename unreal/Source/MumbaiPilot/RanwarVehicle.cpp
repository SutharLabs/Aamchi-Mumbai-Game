#include "RanwarVehicle.h"

#include "Components/AudioComponent.h"
#include "RanwarAudio.h"

#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "CollisionShape.h"
#include "Components/BoxComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/PoseableMeshComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/CollisionProfile.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "Math/RotationMatrix.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/SpringArmComponent.h"
#include "Misc/PackageName.h"
#include "RanwarGame.h"
#include "ReferenceSkeleton.h"
#include "UObject/ConstructorHelpers.h"

namespace
{
    constexpr double ChassisGroundClearance = 26.0;
    constexpr double StepHeight = 24.0;
    constexpr double ExitSpeed = 75.0;
    constexpr double CameraRestPitch = -12.0;
    constexpr double VisualSteeringLimit = 25.0;
    constexpr double MetaHumanSoleAllowance = 1.4;

    struct FVehicleSetup
    {
        const TCHAR* AssetName;
        FText Name;
        FVector ChassisExtent;
        FVector DriverHip;
        double DriverScale;
        double MaxSpeed;
        double ReverseSpeed;
        double Acceleration;
        double TurnRate;
        double CameraDistance;
        double WheelRadius;
        int32 WheelCount;
    };

    const FVehicleSetup& SetupFor(ERanwarVehicleKind Kind)
    {
        static const FVehicleSetup Hatchback{
            TEXT("Hatchback"), NSLOCTEXT("RanwarVehicle", "Hatchback", "Hatchback"),
            FVector(187.0, 82.0, 62.0), FVector(5.0, 35.0, 99.0), 0.72,
            2200.0, 425.0, 720.0, 92.0, 620.0, 32.0, 4
        };
        static const FVehicleSetup Rickshaw{
            TEXT("Rickshaw"), NSLOCTEXT("RanwarVehicle", "Rickshaw", "Auto-rickshaw"),
            FVector(134.0, 64.0, 76.0), FVector(18.5, 0.0, 74.5), 0.84,
            1300.0, 350.0, 580.0, 115.0, 570.0, 25.0, 3
        };
        static const FVehicleSetup Motorcycle{
            TEXT("Motorcycle"), NSLOCTEXT("RanwarVehicle", "Motorcycle", "Motorcycle"),
            FVector(98.0, 37.0, 74.0), FVector(-10.0, 0.0, 86.5), 0.94,
            2000.0, 200.0, 880.0, 103.0, 530.0, 31.0, 2
        };
        static const FVehicleSetup Scooter{
            TEXT("Scooter"), NSLOCTEXT("RanwarVehicle", "Scooter", "Scooter"),
            FVector(93.0, 35.0, 73.0), FVector(-15.5, 0.0, 89.5), 0.94,
            1500.0, 180.0, 760.0, 116.0, 510.0, 24.5, 2
        };
        switch (Kind)
        {
        case ERanwarVehicleKind::Rickshaw: return Rickshaw;
        case ERanwarVehicleKind::Motorcycle: return Motorcycle;
        case ERanwarVehicleKind::Scooter: return Scooter;
        default: return Hatchback;
        }
    }

    FTransform ToComponentSpace(const FReferenceSkeleton& Reference, const TArray<FTransform>& Pose, int32 Bone)
    {
        FTransform Result = FTransform::Identity;
        while (Bone != INDEX_NONE)
        {
            Result *= Pose[Bone];
            Bone = Reference.GetParentIndex(Bone);
        }
        return Result;
    }

    void AimJoint(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose,
        FName JointName, FName ChildName, const FVector& TargetDirection)
    {
        const int32 Joint = Reference.FindBoneIndex(JointName);
        const int32 Child = Reference.FindBoneIndex(ChildName);
        if (Joint == INDEX_NONE || Child == INDEX_NONE)
        {
            return;
        }
        int32 Parent = Reference.GetParentIndex(Child);
        while (Parent != INDEX_NONE && Parent != Joint)
        {
            Parent = Reference.GetParentIndex(Parent);
        }
        if (Parent == INDEX_NONE)
        {
            return;
        }
        const FTransform Component = ToComponentSpace(Reference, Pose, Joint);
        const FVector CurrentDirection =
            (ToComponentSpace(Reference, Pose, Child).GetLocation() - Component.GetLocation()).GetSafeNormal();
        const FQuat ParentRotation = ToComponentSpace(Reference, Pose, Reference.GetParentIndex(Joint)).GetRotation();
        const FQuat Aim = FQuat::FindBetweenNormals(CurrentDirection, TargetDirection.GetSafeNormal());
        Pose[Joint].SetRotation((ParentRotation.Inverse() * Aim * Component.GetRotation()).GetNormalized());
    }

    void TurnJoint(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose, FName Joint, const FQuat& Turn)
    {
        const int32 Index = Reference.FindBoneIndex(Joint);
        if (Index != INDEX_NONE)
        {
            const FQuat Parent = ToComponentSpace(Reference, Pose, Reference.GetParentIndex(Index)).GetRotation();
            Pose[Index].SetRotation((Parent.Inverse() * Turn * Parent * Pose[Index].GetRotation()).GetNormalized());
        }
    }

    void ReachContact(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose,
        FName Upper, FName Lower, FName Endpoint, const FVector& Target, const FVector& Pole,
        FName Shoulder = NAME_None)
    {
        const int32 UpperIndex = Reference.FindBoneIndex(Upper);
        const int32 LowerIndex = Reference.FindBoneIndex(Lower);
        const int32 EndpointIndex = Reference.FindBoneIndex(Endpoint);
        if (UpperIndex == INDEX_NONE || LowerIndex == INDEX_NONE || EndpointIndex == INDEX_NONE)
        {
            return;
        }
        FVector Start = ToComponentSpace(Reference, Pose, UpperIndex).GetLocation();
        const FVector Middle = ToComponentSpace(Reference, Pose, LowerIndex).GetLocation();
        const FVector End = ToComponentSpace(Reference, Pose, EndpointIndex).GetLocation();
        const double UpperLength = FVector::Distance(Start, Middle);
        const double LowerLength = FVector::Distance(Middle, End);
        // Let the shoulder follow a distant grip before the arm approaches straight extension.
        const double ExtraReach = FVector::Distance(Start, Target) - 0.92 * (UpperLength + LowerLength);
        if (!Shoulder.IsNone() && ExtraReach > 0.0)
        {
            const int32 ShoulderIndex = Reference.FindBoneIndex(Shoulder);
            if (ShoulderIndex != INDEX_NONE)
            {
                const FVector Base = ToComponentSpace(Reference, Pose, ShoulderIndex).GetLocation();
                const FVector ShoulderOffset = Start - Base;
                const FQuat Swing = FQuat::FindBetweenVectors(ShoulderOffset, Target - Base);
                const double Limit = FMath::Min(FMath::DegreesToRadians(33.0),
                    FMath::Atan2(ExtraReach, ShoulderOffset.Size()));
                const double Fraction = FMath::Min(1.0, Limit / FMath::Max(0.01, Swing.GetAngle()));
                TurnJoint(Reference, Pose, Shoulder, FQuat::Slerp(FQuat::Identity, Swing, Fraction));
                Start = ToComponentSpace(Reference, Pose, UpperIndex).GetLocation();
            }
        }
        const FVector Offset = Target - Start;
        const FVector Axis = Offset.GetSafeNormal();
        const FVector Bend = (Pole - Axis * FVector::DotProduct(Pole, Axis)).GetSafeNormal();
        if (Axis.IsNearlyZero() || Bend.IsNearlyZero() || UpperLength < 0.1 || LowerLength < 0.1)
        {
            return;
        }
        const double Reach = FMath::Clamp(Offset.Size(), FMath::Abs(UpperLength - LowerLength) + 0.05,
            UpperLength + LowerLength - 0.05);
        const double Along = (FMath::Square(UpperLength) - FMath::Square(LowerLength) + FMath::Square(Reach)) / (2.0 * Reach);
        const FVector JointOffset = Axis * Along + Bend * FMath::Sqrt(FMath::Max(0.0, FMath::Square(UpperLength) - FMath::Square(Along)));
        AimJoint(Reference, Pose, Upper, Lower, JointOffset);
        const FVector SolvedMiddle = ToComponentSpace(Reference, Pose, LowerIndex).GetLocation();
        AimJoint(Reference, Pose, Lower, Endpoint, Start + Axis * Reach - SolvedMiddle);
    }

    void SetJointOrientation(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose,
        int32 Joint, const FQuat& Orientation)
    {
        const FQuat Parent = ToComponentSpace(Reference, Pose, Reference.GetParentIndex(Joint)).GetRotation();
        Pose[Joint].SetRotation((Parent.Inverse() * Orientation).GetNormalized());
    }

    void WrapFinger(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose, const FName (&Finger)[3],
        const FVector& Center, const FVector& Axis, const FVector& CurlAxis, double Radius, int32 Side)
    {
        for (SIZE_T Segment = 0; Segment < UE_ARRAY_COUNT(Finger); ++Segment)
        {
            const int32 Joint = Reference.FindBoneIndex(Finger[Segment]);
            if (Joint == INDEX_NONE)
            {
                return;
            }
            const FTransform Current = ToComponentSpace(Reference, Pose, Joint);
            const FVector Offset = FVector::VectorPlaneProject(Current.GetLocation() - Center, Axis);
            const double Distance = Offset.Size();
            if (Distance < UE_SMALL_NUMBER)
            {
                return;
            }
            const FVector Radial = Offset / Distance;
            const FVector Tangent = FVector::CrossProduct(CurlAxis, Radial);
            // Aim each phalanx around the cylinder while leaving room for the finger pad.
            const double Near = FMath::Min(1.0, Radius / Distance);
            const FVector Direction = Near * Tangent - FMath::Sqrt(1.0 - Near * Near) * Radial;
            if (Segment + 1 < UE_ARRAY_COUNT(Finger))
            {
                AimJoint(Reference, Pose, Finger[Segment], Finger[Segment + 1], Direction);
            }
            else
            {
                const FVector CurrentTip = Current.TransformVectorNoScale(-Side * FVector::ForwardVector);
                const FQuat Aim = FQuat::FindBetweenNormals(CurrentTip, Direction.GetSafeNormal());
                SetJointOrientation(Reference, Pose, Joint, Aim * Current.GetRotation());
            }
        }
    }

    bool FitMetaHumanGrip(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose,
        const FName Arm, const FName Elbow, const FName Hand, const FName Shoulder, int32 Side,
        const FVector& Center, const FVector& KnuckleAxis, const FVector& Forward, const FVector& ElbowPole, double Radius)
    {
        static const FName Left[][3] = {
            {TEXT("index_01_l"), TEXT("index_02_l"), TEXT("index_03_l")},
            {TEXT("middle_01_l"), TEXT("middle_02_l"), TEXT("middle_03_l")},
            {TEXT("ring_01_l"), TEXT("ring_02_l"), TEXT("ring_03_l")},
            {TEXT("pinky_01_l"), TEXT("pinky_02_l"), TEXT("pinky_03_l")},
            {TEXT("thumb_01_l"), TEXT("thumb_02_l"), TEXT("thumb_03_l")},
        };
        static const FName Right[][3] = {
            {TEXT("index_01_r"), TEXT("index_02_r"), TEXT("index_03_r")},
            {TEXT("middle_01_r"), TEXT("middle_02_r"), TEXT("middle_03_r")},
            {TEXT("ring_01_r"), TEXT("ring_02_r"), TEXT("ring_03_r")},
            {TEXT("pinky_01_r"), TEXT("pinky_02_r"), TEXT("pinky_03_r")},
            {TEXT("thumb_01_r"), TEXT("thumb_02_r"), TEXT("thumb_03_r")},
        };
        const auto& Fingers = Side > 0 ? Right : Left;
        const int32 Wrist = Reference.FindBoneIndex(Hand);
        const int32 Middle = Reference.FindBoneIndex(Fingers[1][0]);
        const int32 Index = Reference.FindBoneIndex(Fingers[0][0]);
        const int32 Pinky = Reference.FindBoneIndex(Fingers[3][0]);
        if (Wrist == INDEX_NONE || Middle == INDEX_NONE || Index == INDEX_NONE || Pinky == INDEX_NONE)
        {
            return false;
        }
        const TArray<FTransform>& Rest = Reference.GetRefBonePose();
        const FTransform RestWrist = ToComponentSpace(Reference, Rest, Wrist);
        const FVector RestPalm = ToComponentSpace(Reference, Rest, Middle).GetLocation() - RestWrist.GetLocation();
        const FVector RestAcross = ToComponentSpace(Reference, Rest, Index).GetLocation()
            - ToComponentSpace(Reference, Rest, Pinky).GetLocation();
        const FVector PalmForward = FVector::VectorPlaneProject(Forward, KnuckleAxis).GetSafeNormal();
        const FVector PalmDown = Side * FVector::CrossProduct(PalmForward, KnuckleAxis);
        if (RestPalm.IsNearlyZero() || RestAcross.IsNearlyZero() || PalmDown.IsNearlyZero())
        {
            return false;
        }

        // Both axes come from the grip. A forward-only wrist aim leaves palm roll dependent on the elbow.
        const FQuat RestFrame = FRotationMatrix::MakeFromXY(RestPalm, RestAcross).ToQuat();
        const FQuat GripFrame = FRotationMatrix::MakeFromXY(PalmForward, KnuckleAxis).ToQuat();
        const FVector WristTarget = Center - PalmForward * (0.75 * RestPalm.Size()) - PalmDown * (Radius + 1.30);
        ReachContact(Reference, Pose, Arm, Elbow, Hand, WristTarget, ElbowPole, Shoulder);
        const FTransform CurrentWrist = ToComponentSpace(Reference, Pose, Wrist);
        if (const int32 ElbowIndex = Reference.FindBoneIndex(Elbow); ElbowIndex != INDEX_NONE)
        {
            const FVector ForearmAxis = (CurrentWrist.GetLocation()
                - ToComponentSpace(Reference, Pose, ElbowIndex).GetLocation()).GetSafeNormal();
            const FVector LocalPalmDown = RestWrist.GetRotation().UnrotateVector(RestFrame.RotateVector(Side * FVector::UpVector));
            const FVector ExistingDown = FVector::VectorPlaneProject(
                CurrentWrist.TransformVectorNoScale(LocalPalmDown), ForearmAxis).GetSafeNormal();
            const FVector DesiredDown = FVector::VectorPlaneProject(PalmDown, ForearmAxis).GetSafeNormal();
            if (!ForearmAxis.IsNearlyZero() && !ExistingDown.IsNearlyZero() && !DesiredDown.IsNearlyZero())
            {
                const double Twist = FMath::Atan2(FVector::DotProduct(ForearmAxis, FVector::CrossProduct(ExistingDown, DesiredDown)),
                    FVector::DotProduct(ExistingDown, DesiredDown));
                TurnJoint(Reference, Pose, Elbow, FQuat(ForearmAxis, FMath::Clamp(Twist, -1.35, 1.35)));
            }
        }
        SetJointOrientation(Reference, Pose, Wrist, GripFrame * RestFrame.Inverse() * RestWrist.GetRotation());

        const FVector CurlAxis = FVector::CrossProduct(PalmForward, PalmDown);
        for (int32 Finger = 0; Finger < 4; ++Finger)
        {
            WrapFinger(Reference, Pose, Fingers[Finger], Center, KnuckleAxis, CurlAxis, Radius + 0.65, Side);
        }
        WrapFinger(Reference, Pose, Fingers[4], Center, KnuckleAxis, -CurlAxis, Radius + 0.60, Side);
        return true;
    }

    void AlignFoot(const FReferenceSkeleton& Reference, TArray<FTransform>& Pose,
        const FName Foot, const FName Toe, const FVector& Direction)
    {
        const int32 Ankle = Reference.FindBoneIndex(Foot);
        const int32 Ball = Reference.FindBoneIndex(Toe);
        if (Ankle == INDEX_NONE || Ball == INDEX_NONE)
        {
            return;
        }
        const TArray<FTransform>& Rest = Reference.GetRefBonePose();
        const FTransform RestAnkle = ToComponentSpace(Reference, Rest, Ankle);
        const FVector RestDirection = ToComponentSpace(Reference, Rest, Ball).GetLocation() - RestAnkle.GetLocation();
        const FQuat Aim = FQuat::FindBetweenNormals(RestDirection.GetSafeNormal(), Direction.GetSafeNormal());
        SetJointOrientation(Reference, Pose, Ankle, Aim * RestAnkle.GetRotation());
    }

    struct FDriverContacts
    {
        // Right-side offsets in centimeters from the ground-centered vehicle mesh origin.
        FVector GripCenter;
        FVector GripInward;
        double GripRadius;
        FVector Ankle;
        double TorsoPitch;
        double KneeSpread;
        double ToeSlope;
    };

    FDriverContacts ContactsFor(ERanwarVehicleKind Kind, bool bDetailed)
    {
        // Grip centerlines/radii come from the visible cylinder or steering wheel mesh.
        switch (Kind)
        {
        case ERanwarVehicleKind::Rickshaw:
            return { FVector(57.5, 21.5, 86.7), FVector(0.0, -1.0, 0.0), 2.4,
                FVector(34.0, 10.5, 55.5), 23.0, 0.25, 0.48 };
        case ERanwarVehicleKind::Motorcycle:
            return bDetailed
                ? FDriverContacts{ FVector(29.55, 32.5, 106.91), FVector(0.40, -1.0, 0.025), 1.8,
                    FVector(-27.0, 21.0, 39.5), 50.0, 0.90, 0.31 }
                : FDriverContacts{ FVector(51.1, 30.95, 101.4), FVector(0.0, -1.0, 0.0), 1.8,
                    FVector(-13.5, 23.0, 37.5), 41.0, 0.90, 0.31 };
        case ERanwarVehicleKind::Scooter:
            return bDetailed
                ? FDriverContacts{ FVector(20.88, 28.8, 97.55), FVector(0.31, -1.0, 0.01), 1.8,
                    FVector(-4.0, 14.8, 41.6), 44.0, 0.26, 0.50 }
                : FDriverContacts{ FVector(33.1, 30.85, 105.8), FVector(0.0, -1.0, 0.0), 1.8,
                    FVector(26.7, 14.1, 36.4), 33.0, 0.26, 0.50 };
        default:
            return { FVector(50.05, 13.2, 120.17), FVector(0.283, -0.442, 0.852), 1.8,
                FVector(47.5, 8.5, 65.0), 35.0, 0.18, 0.31 };
        }
    }

    void FitSeatedPose(UPoseableMeshComponent& Rider, const USkeletalMesh& Rig, ERanwarVehicleKind Kind,
        bool bMetaHuman, const URanwarVehicleVisualProfile* Profile, const USceneComponent* Fork, double SteerAngle)
    {
        const FReferenceSkeleton& Reference = Rig.GetRefSkeleton();
        TArray<FTransform>& Pose = Rider.BoneSpaceTransforms;
        Pose = Reference.GetRefBonePose();
        const FDriverContacts Contacts = ContactsFor(Kind, Profile != nullptr);
        const FTransform& RiderTransform = Rider.GetRelativeTransform();
        const FVector Right = RiderTransform.InverseTransformVectorNoScale(FVector::RightVector);
        const FVector Up = RiderTransform.InverseTransformVectorNoScale(FVector::UpVector);
        const FQuat Lean(Right, FMath::DegreesToRadians(Contacts.TorsoPitch + FMath::Abs(SteerAngle) * 0.28));
        const FQuat Twist(Up, FMath::DegreesToRadians(SteerAngle * 0.8));
        const FQuat Torso = Twist * Lean;
        const FQuat CounterTurn = Torso.Inverse();
        if (bMetaHuman)
        {
            // Spread the lean through the clothed spine and keep the gaze forward without a sharp bend at the collar.
            static const FName Spine[] = {TEXT("spine_01"), TEXT("spine_02"), TEXT("spine_03"), TEXT("spine_04"), TEXT("spine_05")};
            static constexpr double SpineWeights[] = {0.52, 0.25, 0.14, 0.07, 0.02};
            for (SIZE_T Index = 0; Index < UE_ARRAY_COUNT(Spine); ++Index)
            {
                TurnJoint(Reference, Pose, Spine[Index], FQuat::Slerp(FQuat::Identity, Torso, SpineWeights[Index]));
            }
            TurnJoint(Reference, Pose, TEXT("neck_01"), FQuat::Slerp(FQuat::Identity, CounterTurn, 0.28));
            TurnJoint(Reference, Pose, TEXT("neck_02"), FQuat::Slerp(FQuat::Identity, CounterTurn, 0.32));
            TurnJoint(Reference, Pose, TEXT("head"), FQuat::Slerp(FQuat::Identity, CounterTurn, 0.22));
        }
        else
        {
            TurnJoint(Reference, Pose, TEXT("Spine"), Torso);
            TurnJoint(Reference, Pose, TEXT("Neck"), CounterTurn);
        }

        // The hatchback has right-hand drive. The other cockpits are centered.
        const double CenterY = SetupFor(Kind).DriverHip.Y;
        for (int32 Side = -1; Side <= 1; Side += 2)
        {
            const bool bRight = Side > 0;
            const auto Bone = [bMetaHuman, bRight](const TCHAR* LeftBone, const TCHAR* RightBone,
                const TCHAR* MetaHumanLeft, const TCHAR* MetaHumanRight)
            {
                return FName(bMetaHuman ? (bRight ? MetaHumanRight : MetaHumanLeft) : (bRight ? RightBone : LeftBone));
            };
            FVector GripCenter(Contacts.GripCenter.X, CenterY + Side * Contacts.GripCenter.Y, Contacts.GripCenter.Z);
            FVector GripInward(Contacts.GripInward.X, Side * Contacts.GripInward.Y, Contacts.GripInward.Z);
            const FVector Ankle(Contacts.Ankle.X, CenterY + Side * Contacts.Ankle.Y,
                Contacts.Ankle.Z + (bMetaHuman ? MetaHumanSoleAllowance : 0.0));
            FVector HandDirection = FVector::ForwardVector;
            FVector LegacyWrist = GripCenter - FVector(4.0, 0.0, -0.6);
            if (Profile && Fork)
            {
                const FTransform& ForkTransform = Fork->GetRelativeTransform();
                GripCenter = ForkTransform.TransformPosition(GripCenter - Profile->ForkPivot);
                LegacyWrist = ForkTransform.TransformPosition(LegacyWrist - Profile->ForkPivot);
                GripInward = ForkTransform.TransformVectorNoScale(GripInward);
                HandDirection = ForkTransform.TransformVectorNoScale(HandDirection);
            }
            const FName Arm = Bone(TEXT("LeftUpperArm"), TEXT("RightUpperArm"), TEXT("upperarm_l"), TEXT("upperarm_r"));
            const FName Shoulder = Bone(TEXT("LeftShoulder"), TEXT("RightShoulder"), TEXT("clavicle_l"), TEXT("clavicle_r"));
            const FName Elbow = Bone(TEXT("LeftLowerArm"), TEXT("RightLowerArm"), TEXT("lowerarm_l"), TEXT("lowerarm_r"));
            const FName Hand = Bone(TEXT("LeftHand"), TEXT("RightHand"), TEXT("hand_l"), TEXT("hand_r"));
            const FVector ElbowPole = RiderTransform.InverseTransformVectorNoScale(FVector(-0.20, Side * 0.65, -1.0));
            const FVector HandForward = RiderTransform.InverseTransformVectorNoScale(HandDirection);
            const bool bFitGrip = bMetaHuman && FitMetaHumanGrip(Reference, Pose, Arm, Elbow, Hand, Shoulder, Side,
                RiderTransform.InverseTransformPosition(GripCenter),
                RiderTransform.InverseTransformVectorNoScale(GripInward).GetSafeNormal(), HandForward, ElbowPole,
                Contacts.GripRadius / RiderTransform.GetScale3D().X);
            if (const int32 HandIndex = Reference.FindBoneIndex(Hand); !bFitGrip && HandIndex != INDEX_NONE)
            {
                ReachContact(Reference, Pose, Arm, Elbow, Hand, RiderTransform.InverseTransformPosition(LegacyWrist),
                    ElbowPole, Shoulder);
                const FQuat Facing = FQuat::FindBetweenNormals(Side * Right, HandForward);
                const FQuat Rest = ToComponentSpace(Reference, Reference.GetRefBonePose(), HandIndex).GetRotation();
                const FQuat Current = ToComponentSpace(Reference, Pose, HandIndex).GetRotation();
                TurnJoint(Reference, Pose, Hand, Facing * Rest * Current.Inverse());
            }

            const FName Leg = Bone(TEXT("LeftUpperLeg"), TEXT("RightUpperLeg"), TEXT("thigh_l"), TEXT("thigh_r"));
            const FName Knee = Bone(TEXT("LeftLowerLeg"), TEXT("RightLowerLeg"), TEXT("calf_l"), TEXT("calf_r"));
            const FName Foot = Bone(TEXT("LeftFoot"), TEXT("RightFoot"), TEXT("foot_l"), TEXT("foot_r"));
            const FName Toe = Bone(TEXT("LeftToes"), TEXT("RightToes"), TEXT("ball_l"), TEXT("ball_r"));
            ReachContact(Reference, Pose, Leg, Knee, Foot, RiderTransform.InverseTransformPosition(Ankle),
                RiderTransform.InverseTransformVectorNoScale(FVector(1.0, Side * Contacts.KneeSpread, 0.28)));
            const FVector ToeDirection = RiderTransform.InverseTransformVectorNoScale(
                FVector(1.0, Side * 0.12, -Contacts.ToeSlope));
            AlignFoot(Reference, Pose, Foot, Toe, ToeDirection);
        }
        Rider.MarkRefreshTransformDirty();
        Rider.RefreshBoneTransforms();
    }
}

bool RanwarDriverPose::FitAmbient(UPoseableMeshComponent& Rider, USkeletalMesh& Mesh, ERanwarVehicleKind Kind)
{
    const FReferenceSkeleton& Reference = Mesh.GetRefSkeleton();
    const TArray<FTransform>& Pose = Reference.GetRefBonePose();
    const bool bMetaHuman = Reference.FindBoneIndex(TEXT("pelvis")) != INDEX_NONE;
    const int32 Hip = Reference.FindBoneIndex(bMetaHuman ? TEXT("pelvis") : TEXT("Hips"));
    const int32 Foot = Reference.FindBoneIndex(bMetaHuman ? TEXT("foot_l") : TEXT("LeftFoot"));
    const int32 Toe = Reference.FindBoneIndex(bMetaHuman ? TEXT("ball_l") : TEXT("LeftToes"));
    if (Hip == INDEX_NONE || Foot == INDEX_NONE || Toe == INDEX_NONE)
    {
        return false;
    }
    const FVector Forward = (ToComponentSpace(Reference, Pose, Toe).GetLocation()
        - ToComponentSpace(Reference, Pose, Foot).GetLocation()).GetSafeNormal2D();
    if (Forward.IsNearlyZero())
    {
        return false;
    }
    const FVehicleSetup& Spec = SetupFor(Kind);
    const FQuat Facing(FVector::UpVector, -FMath::Atan2(Forward.Y, Forward.X));
    Rider.SetSkinnedAssetAndUpdate(&Mesh, true);
    Rider.SetRelativeScale3D(FVector(Spec.DriverScale));
    Rider.SetRelativeRotation(Facing);
    Rider.SetRelativeLocation(Spec.DriverHip
        - Facing.RotateVector(ToComponentSpace(Reference, Pose, Hip).GetLocation() * Spec.DriverScale));
    FitSeatedPose(Rider, Mesh, Kind, bMetaHuman, nullptr, nullptr, 0.0);
    Rider.SetVisibility(true);
    return true;
}

bool URanwarVehicleVisualProfile::HasValidGeometry() const
{
    return Body && Fork && FrontWheel && RearWheel
        && !ForkPivot.ContainsNaN() && !FrontWheelPivot.ContainsNaN() && !RearWheelPivot.ContainsNaN()
        && !SteeringAxis.ContainsNaN() && SteeringAxis.IsNormalized() && !DriverHip.ContainsNaN()
        && FrontWheelRadius >= 10.0 && FrontWheelRadius <= 60.0
        && RearWheelRadius >= 10.0 && RearWheelRadius <= 60.0;
}

ARanwarVehicle::ARanwarVehicle()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.bStartWithTickEnabled = false;

    Chassis = CreateDefaultSubobject<UBoxComponent>(TEXT("Chassis"));
    SetRootComponent(Chassis);
    Chassis->InitBoxExtent(SetupFor(VehicleKind).ChassisExtent);
    Chassis->SetCollisionProfileName(UCollisionProfile::BlockAllDynamic_ProfileName);
    Chassis->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    Chassis->SetGenerateOverlapEvents(false);

    VehicleMesh = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("VehicleMesh"));
    VehicleMesh->SetupAttachment(Chassis);
    VehicleMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    VisualFork = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("VisualFork"));
    VisualFork->SetupAttachment(VehicleMesh);
    VisualFrontWheel = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("VisualFrontWheel"));
    VisualFrontWheel->SetupAttachment(VisualFork);
    VisualRearWheel = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("VisualRearWheel"));
    VisualRearWheel->SetupAttachment(VehicleMesh);
    for (UStaticMeshComponent* Visual : {VisualFork.Get(), VisualFrontWheel.Get(), VisualRearWheel.Get()})
    {
        Visual->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Visual->SetGenerateOverlapEvents(false);
        Visual->SetCanEverAffectNavigation(false);
    }

    StandInBody = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("StandInBody"));
    StandInBody->SetupAttachment(VehicleMesh);
    StandInBody->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Body(TEXT("/Engine/BasicShapes/Sphere.Sphere"));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> Wheel(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    StandInBody->SetStaticMesh(Body.Object);
    for (int32 Index = 0; Index < 4; ++Index)
    {
        const FName ComponentName(*FString::Printf(TEXT("StandInWheel%d"), Index));
        UStaticMeshComponent* Part = CreateDefaultSubobject<UStaticMeshComponent>(ComponentName);
        Part->SetupAttachment(VehicleMesh);
        Part->SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Part->SetStaticMesh(Wheel.Object);
        Part->SetRelativeRotation(FRotator(0.0, 0.0, 90.0));
        StandInWheels.Add(Part);
    }

    SeatedDriver = CreateDefaultSubobject<UPoseableMeshComponent>(TEXT("SeatedDriver"));
    SeatedDriver->SetupAttachment(VehicleMesh);
    SeatedDriver->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SeatedDriver->SetVisibility(false);

    Arm = CreateDefaultSubobject<USpringArmComponent>(TEXT("VehicleFollowArm"));
    Arm->SetupAttachment(Chassis);
    Arm->SetRelativeLocation(FVector(0.0, 0.0, 58.0));
    Arm->SetRelativeRotation(FRotator(CameraRestPitch, 0.0, 0.0));
    Arm->ProbeSize = 16.0f;
    Arm->bUsePawnControlRotation = false;
    Arm->bDoCollisionTest = true;
    Arm->bEnableCameraLag = true;
    Arm->CameraLagSpeed = 8.0f;
    Arm->CameraLagMaxDistance = 65.0f;
    UCameraComponent* Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("VehicleCamera"));
    Camera->SetupAttachment(Arm, USpringArmComponent::SocketName);
    Camera->SetFieldOfView(78.0f);
}

void ARanwarVehicle::BeginPlay()
{
    Super::BeginPlay();
    SetVehicleKind(VehicleKind);
}

void ARanwarVehicle::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    StopEngineAudio();
    if (EndPlayReason == EEndPlayReason::Destroyed)
    {
        if (ARanwarCharacter* Character = Driver.Get())
        {
            AController* Player = GetController();
            FVector ExitLocation;
            const bool bClear = FindExitLocation(*Character, ExitLocation);
            Driver.Reset();
            RestoreDriver(*Character, bClear ? &ExitLocation : nullptr);
            if (IsValid(Player))
            {
                Player->Possess(Character);
            }
        }
    }
    Super::EndPlay(EndPlayReason);
}

void ARanwarVehicle::SetVehicleKind(ERanwarVehicleKind Kind)
{
    if (HasDriver())
    {
        return;
    }
    const FVehicleSetup& Spec = SetupFor(Kind);
    const bool bKeepAssignedMesh = VehicleKind == Kind && VehicleMesh->GetStaticMesh() != nullptr;
    VehicleKind = Kind;
    Chassis->SetBoxExtent(Spec.ChassisExtent);
    VehicleMesh->SetRelativeLocation(FVector(0.0, 0.0, -RideHeight()));
    Arm->TargetArmLength = static_cast<float>(Spec.CameraDistance);

    if (!bKeepAssignedMesh)
    {
        const FString Package = FString(TEXT("/Game/Ranwar/Vehicles/")) + Spec.AssetName;
        const FString ProfileName = FString(Spec.AssetName) + TEXT("VinishProfile");
        const FString ProfilePackage = FString(TEXT("/Game/Ranwar/Vehicles/")) + ProfileName;
        URanwarVehicleVisualProfile* Detailed = Spec.WheelCount == 2
            && FPackageName::DoesPackageExist(ProfilePackage, nullptr, false)
            ? LoadObject<URanwarVehicleVisualProfile>(nullptr, *(ProfilePackage + TEXT(".") + ProfileName)) : nullptr;
        SetDetailedVisual(Detailed && Detailed->HasValidGeometry() ? Detailed : nullptr);
        if (!VisualProfile)
        {
            UStaticMesh* Asset = FPackageName::DoesPackageExist(Package, nullptr, false)
                ? LoadObject<UStaticMesh>(nullptr, *(Package + TEXT(".") + Spec.AssetName)) : nullptr;
            VehicleMesh->SetStaticMesh(Asset);
        }
    }
    const bool bShowStandIn = VehicleMesh->GetStaticMesh() == nullptr;
    StandInBody->SetVisibility(bShowStandIn);
    StandInBody->SetRelativeLocation(FVector(0.0, 0.0, Spec.WheelRadius + Spec.ChassisExtent.Z * 0.55));
    StandInBody->SetRelativeScale3D(FVector(
        Spec.ChassisExtent.X * 0.019, Spec.ChassisExtent.Y * 0.017, Spec.ChassisExtent.Z * 0.017));
    const double AxleOffset = Spec.ChassisExtent.X * 0.65;
    const double Track = Spec.ChassisExtent.Y * 0.84;
    for (int32 Index = 0; Index < StandInWheels.Num(); ++Index)
    {
        UStaticMeshComponent* Part = StandInWheels[Index];
        const bool bFront = Index < (Spec.WheelCount == 4 ? 2 : 1);
        const bool bCentered = Spec.WheelCount == 2 || (Spec.WheelCount == 3 && bFront);
        const double Lateral = bCentered ? 0.0 : (Index % 2 == 0 ? -Track : Track);
        Part->SetRelativeLocation(FVector(bFront ? AxleOffset : -AxleOffset, Lateral, Spec.WheelRadius));
        const double DiameterScale = Spec.WheelRadius * 0.02;
        Part->SetRelativeScale3D(FVector(DiameterScale, DiameterScale, bCentered ? 0.12 : 0.18));
        Part->SetVisibility(bShowStandIn && Index < Spec.WheelCount);
    }
}

void ARanwarVehicle::SetDetailedVisual(URanwarVehicleVisualProfile* Profile)
{
    VisualProfile = Profile;
    VisualFork->SetStaticMesh(Profile ? Profile->Fork.Get() : nullptr);
    VisualFrontWheel->SetStaticMesh(Profile ? Profile->FrontWheel.Get() : nullptr);
    VisualRearWheel->SetStaticMesh(Profile ? Profile->RearWheel.Get() : nullptr);
    if (Profile)
    {
        VehicleMesh->SetStaticMesh(Profile->Body.Get());
        VisualFork->SetRelativeLocationAndRotation(Profile->ForkPivot, FRotator::ZeroRotator);
        VisualFrontWheel->SetRelativeLocationAndRotation(
            Profile->FrontWheelPivot - Profile->ForkPivot, FRotator::ZeroRotator);
        VisualRearWheel->SetRelativeLocationAndRotation(Profile->RearWheelPivot, FRotator::ZeroRotator);
    }
    VisualSteerAngle = 0.0;
    FrontWheelRoll = 0.0;
    RearWheelRoll = 0.0;
}

void ARanwarVehicle::UpdateDetailedVisual(double Travel, double DeltaSeconds)
{
    if (!VisualProfile)
    {
        return;
    }
    const double TargetAngle = Steering * VisualSteeringLimit;
    const double Angle = FMath::FInterpConstantTo(VisualSteerAngle, TargetAngle, DeltaSeconds, 120.0);
    if (!FMath::IsNearlyEqual(VisualSteerAngle, Angle))
    {
        VisualSteerAngle = Angle;
        VisualFork->SetRelativeRotation(FQuat(VisualProfile->SteeringAxis, FMath::DegreesToRadians(Angle)));
        if (ARanwarCharacter* Character = Driver.Get())
        {
            if (const USkeletalMesh* Rig = Cast<USkeletalMesh>(SeatedDriver->GetSkinnedAsset()))
            {
                const bool bMetaHuman = IsValid(Character->GetMetaHumanVisual());
                FitSeatedPose(*SeatedDriver, *Rig, VehicleKind, bMetaHuman, VisualProfile.Get(), VisualFork.Get(), Angle);
                if (bMetaHuman)
                {
                    Character->RefreshMetaHumanRiderPose(*SeatedDriver);
                }
            }
        }
    }
    if (!FMath::IsNearlyZero(Travel))
    {
        FrontWheelRoll = FMath::UnwindRadians(FrontWheelRoll + Travel / VisualProfile->FrontWheelRadius);
        RearWheelRoll = FMath::UnwindRadians(RearWheelRoll + Travel / VisualProfile->RearWheelRadius);
        VisualFrontWheel->SetRelativeRotation(FQuat(FVector::RightVector, FrontWheelRoll));
        VisualRearWheel->SetRelativeRotation(FQuat(FVector::RightVector, RearWheelRoll));
    }
}

bool ARanwarVehicle::PlaceOnGround(const FVector& GroundPoint, const FRotator& Heading)
{
    double GroundZ = 0.0;
    if (!SampleGround(GroundPoint, 50.0, 90.0, GroundZ))
    {
        return false;
    }
    const FVector Location(GroundPoint.X, GroundPoint.Y, GroundZ + RideHeight());
    const FRotator Rotation(0.0, Heading.Yaw, 0.0);
    return HasChassisClearance(Location, Rotation.Quaternion())
        && SetActorLocationAndRotation(Location, Rotation, false, nullptr, ETeleportType::TeleportPhysics);
}

bool ARanwarVehicle::CanEnter(const ARanwarCharacter* Character) const
{
    if (!IsValid(Character) || Character->GetWorld() != GetWorld() || HasDriver()
        || GetController() || !Character->IsPlayerControlled() || Character->GetCharacterMovement()->IsFalling())
    {
        return false;
    }
    const FVector PlayerPosition = Character->GetActorLocation();
    const FVector Offset = GetActorTransform().InverseTransformPosition(PlayerPosition);
    const FVector Extent = Chassis->GetScaledBoxExtent();
    const FVector Outer(
        FMath::Max(0.0, FMath::Abs(Offset.X) - Extent.X),
        FMath::Max(0.0, FMath::Abs(Offset.Y) - Extent.Y), FMath::Abs(Offset.Z));
    if (Outer.SizeSquared() > FMath::Square(135.0))
    {
        return false;
    }
    FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarVehicleEntry), true, this);
    Query.AddIgnoredActor(Character);
    return !GetWorld()->LineTraceTestByChannel(PlayerPosition, GetActorLocation(), ECC_Visibility, Query);
}

bool ARanwarVehicle::TryEnter(ARanwarCharacter* Character)
{
    if (!CanEnter(Character))
    {
        return false;
    }
    APlayerController* Player = Cast<APlayerController>(Character->GetController());
    if (!Player)
    {
        return false;
    }

    Player->Possess(this);
    if (Player->GetPawn() != this)
    {
        if (Player->GetPawn() != Character)
        {
            Player->Possess(Character);
        }
        return false;
    }
    Driver = Character;
    Character->GetCharacterMovement()->StopMovementImmediately();
    Character->GetCharacterMovement()->DisableMovement();
    Character->SetActorEnableCollision(false);
    Character->SetActorHiddenInGame(true);
    CameraYaw = 0.0;
    CameraPitch = CameraRestPitch;
    CameraLookTime = 0.0;
    Arm->SetRelativeRotation(FRotator(CameraPitch, CameraYaw, 0.0));
    if (!ShowDriver(*Character))
    {
        Driver.Reset();
        RestoreDriver(*Character, nullptr);
        Player->Possess(Character);
        return false;
    }
    EngineAudio = RanwarAudio::StartVehicleEngine(*this, VehicleKind);
    SetActorTickEnabled(true);
    return true;
}

bool ARanwarVehicle::HasDriver() const
{
    return Driver.IsValid();
}

bool ARanwarVehicle::ExitDriver()
{
    ARanwarCharacter* Character = Driver.Get();
    AController* Player = GetController();
    FVector ExitLocation;
    if (!Character || !Player || FMath::Abs(ForwardSpeed) > ExitSpeed
        || !FindExitLocation(*Character, ExitLocation))
    {
        return false;
    }
    Driver.Reset();
    RestoreDriver(*Character, &ExitLocation);
    Player->Possess(Character);
    Player->SetControlRotation(FRotator(0.0, GetActorRotation().Yaw, 0.0));
    return Player->GetPawn() == Character;
}

void ARanwarVehicle::UnPossessed()
{
    StopEngineAudio();
    if (ARanwarCharacter* Character = Driver.Get())
    {
        FVector ExitLocation;
        const bool bClear = FindExitLocation(*Character, ExitLocation);
        RestoreDriver(*Character, bClear ? &ExitLocation : nullptr);
    }
    Driver.Reset();
    SeatedDriver->SetVisibility(false);
    ForwardSpeed = 0.0;
    Throttle = 0.0;
    Steering = 0.0;
    bBrakePressed = false;
    SetActorTickEnabled(false);
    Super::UnPossessed();
}

FText ARanwarVehicle::GetVehicleName() const
{
    return SetupFor(VehicleKind).Name;
}

double ARanwarVehicle::GetSpeedKph() const
{
    return FMath::Abs(ForwardSpeed) * 0.036;
}

const ARanwarCharacter* ARanwarVehicle::GetDriver() const
{
    return Driver.Get();
}

UStaticMeshComponent* ARanwarVehicle::GetVehicleMesh() const
{
    return VehicleMesh;
}

FVector ARanwarVehicle::GetVelocity() const
{
    return GetActorForwardVector() * ForwardSpeed;
}

void ARanwarVehicle::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis(TEXT("MoveForward"), this, &ARanwarVehicle::SetThrottle);
    Input->BindAxis(TEXT("MoveRight"), this, &ARanwarVehicle::SetSteering);
    Input->BindAxis(TEXT("Turn"), this, &ARanwarVehicle::Turn);
    Input->BindAxis(TEXT("LookUp"), this, &ARanwarVehicle::LookUp);
    Input->BindAxis(TEXT("TurnWithStick"), this, &ARanwarVehicle::TurnWithStick);
    Input->BindAxis(TEXT("LookUpWithStick"), this, &ARanwarVehicle::LookUpWithStick);
    Input->BindAction(TEXT("Jump"), IE_Pressed, this, &ARanwarVehicle::PressBrake);
    Input->BindAction(TEXT("Jump"), IE_Released, this, &ARanwarVehicle::ReleaseBrake);
    Input->BindAction(TEXT("Interact"), IE_Pressed, this, &ARanwarVehicle::RequestExit);
    Input->BindAction(TEXT("Horn"), IE_Pressed, this, &ARanwarVehicle::UseHorn);
}

void ARanwarVehicle::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!HasDriver())
    {
        return;
    }
    const FVector Start = GetActorLocation();
    double Remaining = FMath::Min(static_cast<double>(DeltaSeconds), 0.10);
    while (Remaining > UE_SMALL_NUMBER)
    {
        const double Step = FMath::Min(Remaining, 1.0 / 60.0);
        Advance(Step);
        Remaining -= Step;
    }
    UpdateDetailedVisual(FVector::DotProduct(GetActorLocation() - Start, GetActorForwardVector()), DeltaSeconds);
    UpdateVehicleLook(DeltaSeconds);
    RanwarAudio::UpdateVehicleEngine(EngineAudio, static_cast<float>(GetSpeedKph()), static_cast<float>(Throttle));
}

void ARanwarVehicle::UseHorn()
{
    const double Now = GetWorld()->GetTimeSeconds();
    if (HasDriver() && Now - LastHornAt >= 0.5)
    {
        RanwarAudio::PlayHorn(*this, VehicleKind);
        LastHornAt = Now;
    }
}

void ARanwarVehicle::StopEngineAudio()
{
    if (IsValid(EngineAudio.Get()))
    {
        EngineAudio->Stop();
    }
    EngineAudio = nullptr;
}

void ARanwarVehicle::Advance(double Step)
{
    const FVehicleSetup& Spec = SetupFor(VehicleKind);
    const bool bThrottle = FMath::Abs(Throttle) > 0.06;
    const bool bSameDirection = ForwardSpeed * Throttle >= 0.0;
    const double DriveCondition = 0.55 + static_cast<double>(Condition) * 0.0045;
    const double Target = bBrakePressed || !bThrottle || !bSameDirection
        ? 0.0 : Throttle * (Throttle > 0.0 ? Spec.MaxSpeed : Spec.ReverseSpeed) * DriveCondition;
    const double Rate = bBrakePressed || (bThrottle && !bSameDirection)
        ? 1700.0 : (!bThrottle ? 300.0 : Spec.Acceleration);
    ForwardSpeed = FMath::FInterpConstantTo(ForwardSpeed, Target, Step, Rate);
    if (FMath::IsNearlyZero(ForwardSpeed, 1.0))
    {
        return;
    }
    const FVector Start = GetActorLocation();
    const double StartYaw = GetActorRotation().Yaw;
    const double Speed = FMath::Abs(ForwardSpeed);
    const double SteeringGain = FMath::Min(Speed / 225.0, 1.0)
        * FMath::GetMappedRangeValueClamped(FVector2D(350.0, Spec.MaxSpeed), FVector2D(1.0, 0.42), Speed);
    const double Yaw = Steering * Spec.TurnRate * SteeringGain * FMath::Sign(ForwardSpeed) * Step;
    FRotator Rotation(0.0, StartYaw + Yaw, 0.0);
    if (!FMath::IsNearlyZero(Yaw) && !HasChassisClearance(Start, Rotation.Quaternion()))
    {
        Rotation.Yaw = StartYaw;
    }
    const FVector Direction = Rotation.Vector();
    FVector TargetLocation = Start + Direction * ForwardSpeed * Step;
    const FVector RoadPlane = TargetLocation - FVector(0.0, 0.0, RideHeight());
    const FVector Axle = Direction * (Spec.ChassisExtent.X * 0.62);
    double FrontZ = 0.0;
    double RearZ = 0.0;
    if (!SampleGround(RoadPlane + Axle, StepHeight + 3.0, 82.0, FrontZ)
        || !SampleGround(RoadPlane - Axle, StepHeight + 3.0, 82.0, RearZ))
    {
        ForwardSpeed = 0.0;
        return;
    }
    // Axle samples let the chassis follow low curbs without treating a wall as road.
    const double GroundZ = (FrontZ + RearZ) * 0.5;
    TargetLocation.Z = FMath::FInterpConstantTo(Start.Z, GroundZ + RideHeight(), Step, 320.0);
    FHitResult Hit;
    SetActorLocationAndRotation(TargetLocation, Rotation, true, &Hit);
    if (Hit.bBlockingHit)
    {
        const double ImpactSpeed = Speed * FMath::Abs(FVector::DotProduct(Direction, Hit.ImpactNormal));
        const double Now = GetWorld()->GetTimeSeconds();
        if (ImpactSpeed > 510.0 && Now - LastImpactAt > 0.7)
        {
            const float Impact = static_cast<float>(FMath::Clamp((ImpactSpeed - 510.0) * 0.017, 0.0, 30.0));
            Condition = FMath::Max(0.0f, Condition - Impact);
            LastImpactAt = Now;
            if (ARanwarCharacter* Pedestrian = Cast<ARanwarCharacter>(Hit.GetActor()); Pedestrian && Pedestrian != Driver.Get())
            {
                UGameplayStatics::ApplyDamage(Pedestrian, Impact * 2.0f, GetController(), this, nullptr);
            }
        }
        ForwardSpeed *= 0.22;
    }
}

void ARanwarVehicle::SetThrottle(float Value)
{
    Throttle = FMath::Clamp(Value, -1.0f, 1.0f);
}

void ARanwarVehicle::SetSteering(float Value)
{
    Steering = FMath::Clamp(Value, -1.0f, 1.0f);
}

void ARanwarVehicle::Turn(float Value)
{
    if (!FMath::IsNearlyZero(Value))
    {
        CameraYaw = FRotator::NormalizeAxis(CameraYaw + Value);
        CameraLookTime = 1.3;
    }
}

void ARanwarVehicle::LookUp(float Value)
{
    CameraPitch = FMath::Clamp(CameraPitch + Value, -55.0, 15.0);
}

void ARanwarVehicle::TurnWithStick(float Value)
{
    Turn(Value * 115.0f * GetWorld()->GetDeltaSeconds());
}

void ARanwarVehicle::LookUpWithStick(float Value)
{
    LookUp(Value * 95.0f * GetWorld()->GetDeltaSeconds());
}

void ARanwarVehicle::PressBrake()
{
    bBrakePressed = true;
}

void ARanwarVehicle::ReleaseBrake()
{
    bBrakePressed = false;
}

void ARanwarVehicle::RequestExit()
{
    ExitDriver();
}

void ARanwarVehicle::UpdateVehicleLook(double DeltaSeconds)
{
    CameraLookTime = FMath::Max(0.0, CameraLookTime - DeltaSeconds);
    if (CameraLookTime == 0.0 && FMath::Abs(ForwardSpeed) > 170.0)
    {
        CameraYaw = FMath::FInterpTo(CameraYaw, 0.0, DeltaSeconds, 2.1);
    }
    Arm->SetRelativeRotation(FRotator(CameraPitch, CameraYaw, 0.0));
}

bool ARanwarVehicle::ShowDriver(ARanwarCharacter& Character)
{
    const bool bMetaHuman = IsValid(Character.GetMetaHumanVisual());
    const USkeletalMeshComponent* OnFoot = Character.GetAvatarBody();
    USkeletalMesh* Rig = OnFoot->GetSkeletalMeshAsset();
    if (!Rig)
    {
        return !bMetaHuman;
    }
    const FReferenceSkeleton& Reference = Rig->GetRefSkeleton();
    const int32 HipIndex = Reference.FindBoneIndex(bMetaHuman ? TEXT("pelvis") : TEXT("Hips"));
    if (HipIndex == INDEX_NONE)
    {
        return !bMetaHuman;
    }
    SeatedDriver->SetSkinnedAssetAndUpdate(Rig, true);
    const FVehicleSetup& Spec = SetupFor(VehicleKind);
    const FQuat Orientation = Character.GetAvatarFacing();
    const FVector Hip = ToComponentSpace(Reference, Reference.GetRefBonePose(), HipIndex).GetLocation();
    SeatedDriver->SetRelativeScale3D(FVector(Spec.DriverScale));
    SeatedDriver->SetRelativeRotation(Orientation);
    FVector DriverHip = VisualProfile ? VisualProfile->DriverHip : Spec.DriverHip;
    if (VisualProfile && VehicleKind == ERanwarVehicleKind::Motorcycle)
    {
        // Sit on the front half of the detailed saddle so the outer grip stays within reach at full steering lock.
        DriverHip.X += 5.0;
    }
    SeatedDriver->SetRelativeLocation(DriverHip - Orientation.RotateVector(Hip * Spec.DriverScale));

    FitSeatedPose(*SeatedDriver, *Rig, VehicleKind, bMetaHuman, VisualProfile.Get(), VisualFork.Get(), VisualSteerAngle);
    SeatedDriver->SetVisibility(!bMetaHuman);
    return !bMetaHuman || Character.AttachMetaHumanRider(*VehicleMesh, *SeatedDriver);
}

void ARanwarVehicle::RestoreDriver(ARanwarCharacter& Character, const FVector* ExitLocation)
{
    if (ExitLocation)
    {
        const FRotator Heading(0.0, GetActorRotation().Yaw, 0.0);
        Character.SetActorLocationAndRotation(*ExitLocation, Heading, false, nullptr, ETeleportType::TeleportPhysics);
    }
    Character.SetActorHiddenInGame(false);
    Character.RestoreMetaHumanVisual();
    Character.SetActorEnableCollision(true);
    Character.GetCharacterMovement()->SetMovementMode(MOVE_Walking);
    SeatedDriver->SetVisibility(false);
}

bool ARanwarVehicle::FindExitLocation(const ARanwarCharacter& Character, FVector& ExitLocation) const
{
    const UCapsuleComponent* Capsule = Character.GetCapsuleComponent();
    const float Radius = Capsule->GetScaledCapsuleRadius();
    const float HalfHeight = Capsule->GetScaledCapsuleHalfHeight();
    const FCollisionShape Shape = FCollisionShape::MakeCapsule(Radius, HalfHeight);
    const FVector Extent = Chassis->GetScaledBoxExtent();
    const double Side = Extent.Y + Radius + 18.0;
    const double End = Extent.X + Radius + 18.0;
    const FVector Offsets[] = {
        FVector(0.0, Side, 0.0), FVector(0.0, -Side, 0.0),
        FVector(-End, 0.0, 0.0), FVector(End, 0.0, 0.0)
    };
    const ECollisionChannel Channel = Capsule->GetCollisionObjectType();
    const FCollisionResponseParams Responses(Capsule->GetCollisionResponseToChannels());
    const FVector Origin = GetActorLocation() - FVector(0.0, 0.0, RideHeight());
    FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarVehicleExit), true, &Character);
    FCollisionQueryParams PathQuery(Query);
    PathQuery.AddIgnoredActor(this);
    for (const FVector& Offset : Offsets)
    {
        FVector Candidate = Origin + GetActorRotation().RotateVector(Offset);
        double GroundZ;
        if (!SampleGround(Candidate, 48.0, 90.0, GroundZ))
        {
            continue;
        }
        Candidate.Z = GroundZ + HalfHeight + 4.0;
        const FVector PathStart(Origin.X, Origin.Y, FMath::Max(Origin.Z, GroundZ) + HalfHeight + 4.0);
        if (!GetWorld()->OverlapBlockingTestByChannel(Candidate, FQuat::Identity, Channel, Shape, Query, Responses)
            && !GetWorld()->SweepTestByChannel(PathStart, Candidate, FQuat::Identity, Channel, Shape, PathQuery, Responses))
        {
            ExitLocation = Candidate;
            return true;
        }
    }
    return false;
}

bool ARanwarVehicle::SampleGround(const FVector& Position, double Up, double Down, double& GroundZ) const
{
    const FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarVehicleGround), true, this);
    const FCollisionObjectQueryParams WorldStatic(ECC_WorldStatic);
    FHitResult Hit;
    const FVector Above = Position + FVector(0.0, 0.0, Up);
    const FVector Below = Position - FVector(0.0, 0.0, Down);
    if (!GetWorld()->LineTraceSingleByObjectType(Hit, Above, Below, WorldStatic, Query) || Hit.ImpactNormal.Z < 0.60)
    {
        return false;
    }
    GroundZ = Hit.ImpactPoint.Z;
    return true;
}

bool ARanwarVehicle::HasChassisClearance(const FVector& Location, const FQuat& Rotation) const
{
    const FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarVehicleChassis), true, this);
    const FCollisionShape Shape = FCollisionShape::MakeBox(Chassis->GetScaledBoxExtent() - FVector(1.0));
    const FCollisionResponseParams Responses(Chassis->GetCollisionResponseToChannels());
    return !GetWorld()->OverlapBlockingTestByChannel(Location, Rotation, Chassis->GetCollisionObjectType(), Shape, Query, Responses);
}

double ARanwarVehicle::RideHeight() const
{
    return Chassis->GetScaledBoxExtent().Z + ChassisGroundClearance;
}
