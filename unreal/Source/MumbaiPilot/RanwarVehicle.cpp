#include "RanwarVehicle.h"

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
        if (Joint == INDEX_NONE || Child == INDEX_NONE || Reference.GetParentIndex(Child) != Joint)
        {
            return;
        }
        const FTransform Component = ToComponentSpace(Reference, Pose, Joint);
        const FVector CurrentDirection = Component.TransformVectorNoScale(Pose[Child].GetTranslation()).GetSafeNormal();
        const FQuat ParentRotation = ToComponentSpace(Reference, Pose, Reference.GetParentIndex(Joint)).GetRotation();
        const FQuat Aim = FQuat::FindBetweenNormals(CurrentDirection, TargetDirection.GetSafeNormal());
        Pose[Joint].SetRotation((ParentRotation.Inverse() * Aim * Component.GetRotation()).GetNormalized());
    }
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
        UStaticMesh* Asset = FPackageName::DoesPackageExist(Package, nullptr, false)
            ? LoadObject<UStaticMesh>(nullptr, *(Package + TEXT(".") + Spec.AssetName)) : nullptr;
        VehicleMesh->SetStaticMesh(Asset);
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
    ShowDriver(*Character);
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
}

void ARanwarVehicle::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (!HasDriver())
    {
        return;
    }
    double Remaining = FMath::Min(static_cast<double>(DeltaSeconds), 0.10);
    while (Remaining > UE_SMALL_NUMBER)
    {
        const double Step = FMath::Min(Remaining, 1.0 / 60.0);
        Advance(Step);
        Remaining -= Step;
    }
    UpdateVehicleLook(DeltaSeconds);
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

void ARanwarVehicle::ShowDriver(const ARanwarCharacter& Character)
{
    const USkeletalMeshComponent* OnFoot = Character.GetMesh();
    USkeletalMesh* Rig = OnFoot->GetSkeletalMeshAsset();
    if (!Rig)
    {
        return;
    }
    const FReferenceSkeleton& Reference = Rig->GetRefSkeleton();
    const int32 HipIndex = Reference.FindBoneIndex(TEXT("Hips"));
    if (HipIndex == INDEX_NONE)
    {
        return;
    }
    SeatedDriver->SetSkinnedAssetAndUpdate(Rig, true);
    TArray<FTransform>& Pose = SeatedDriver->BoneSpaceTransforms;
    Pose = Reference.GetRefBonePose();
    const FVehicleSetup& Spec = SetupFor(VehicleKind);
    const FQuat Orientation = OnFoot->GetRelativeRotation().Quaternion();
    const FVector Hip = ToComponentSpace(Reference, Pose, HipIndex).GetLocation();
    SeatedDriver->SetRelativeScale3D(FVector(Spec.DriverScale));
    SeatedDriver->SetRelativeRotation(Orientation);
    SeatedDriver->SetRelativeLocation(Spec.DriverHip - Orientation.RotateVector(Hip * Spec.DriverScale));

    const bool bMotorcycle = VehicleKind == ERanwarVehicleKind::Motorcycle;
    const bool bCar = VehicleKind == ERanwarVehicleKind::Hatchback;
    const auto Aim = [&Reference, &Pose, &Orientation](const TCHAR* Joint, const TCHAR* Child, const FVector& Direction)
    {
        AimJoint(Reference, Pose, FName(Joint), FName(Child), Orientation.UnrotateVector(Direction));
    };
    Aim(TEXT("LeftUpperLeg"), TEXT("LeftLowerLeg"), FVector(1.0, -0.28, bMotorcycle ? -0.46 : -0.14));
    Aim(TEXT("RightUpperLeg"), TEXT("RightLowerLeg"), FVector(1.0, 0.28, bMotorcycle ? -0.46 : -0.14));
    Aim(TEXT("LeftLowerLeg"), TEXT("LeftFoot"), FVector(bMotorcycle ? -0.78 : 0.20, 0.04, -1.0));
    Aim(TEXT("RightLowerLeg"), TEXT("RightFoot"), FVector(bMotorcycle ? -0.78 : 0.20, -0.04, -1.0));
    Aim(TEXT("LeftFoot"), TEXT("LeftToes"), FVector(1.0, -0.08, -0.12));
    Aim(TEXT("RightFoot"), TEXT("RightToes"), FVector(1.0, 0.08, -0.12));
    Aim(TEXT("LeftUpperArm"), TEXT("LeftLowerArm"), FVector(0.63, -0.38, -0.80));
    Aim(TEXT("RightUpperArm"), TEXT("RightLowerArm"), FVector(0.63, 0.38, -0.80));
    Aim(TEXT("LeftLowerArm"), TEXT("LeftHand"), FVector(1.0, 0.42, bCar ? 0.40 : 0.19));
    Aim(TEXT("RightLowerArm"), TEXT("RightHand"), FVector(1.0, -0.42, bCar ? 0.40 : 0.19));
    SeatedDriver->MarkRefreshTransformDirty();
    SeatedDriver->SetVisibility(true);
}

void ARanwarVehicle::RestoreDriver(ARanwarCharacter& Character, const FVector* ExitLocation)
{
    if (ExitLocation)
    {
        const FRotator Heading(0.0, GetActorRotation().Yaw, 0.0);
        Character.SetActorLocationAndRotation(*ExitLocation, Heading, false, nullptr, ETeleportType::TeleportPhysics);
    }
    Character.SetActorHiddenInGame(false);
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
