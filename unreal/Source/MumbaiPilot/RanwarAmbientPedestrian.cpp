#include "RanwarAmbientPedestrian.h"
#include "RanwarStrideAnimation.h"

#include "Animation/AnimSequence.h"
#include "Animation/Skeleton.h"
#include "AnimationRuntime.h"
#include "Components/CapsuleComponent.h"
#include "Components/LODSyncComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "GroomComponent.h"

namespace
{
    constexpr int32 MaxPathPoints = 16;
    constexpr double StartWalkingRange = 6500.0;
    constexpr double StopWalkingRange = 7500.0;
    constexpr double PlayerClearance = 85.0;
    constexpr double PlayerHeightTolerance = 175.0;
    constexpr double TurnDegreesPerSecond = 140.0;
    constexpr double WalkingHeadingTolerance = 15.0;
    constexpr double SpeedChangePerSecond = 330.0;
    constexpr float DistantTickInterval = 0.5f;
    constexpr float MaximumMoveStepSeconds = 0.10f;

    FRanwarFootMotion TurnFootMotion(double Angle, double Progress, const FVector& Forward)
    {
        FRanwarFootMotion Motion;
        Motion.Forward = Forward;
        if (FMath::IsNearlyZero(Angle) || Progress >= 1.0)
        {
            return Motion;
        }

        const int32 Steps = FMath::Max(2, FMath::CeilToInt(FMath::Abs(Angle) / 50.0));
        const double StepsElapsed = Progress * Steps;
        const int32 MovingStep = FMath::FloorToInt(StepsElapsed);
        const double Swing = StepsElapsed - MovingStep;
        const double PerStep = Angle / Steps;
        const bool bLeftFirst = Angle < 0.0;
        for (int32 Side = 0; Side < 2; ++Side)
        {
            const int32 FirstStep = (Side == 0) == bLeftFirst ? 0 : 1;
            const bool bSwinging = MovingStep % 2 == FirstStep;
            const int32 LastPlant = bSwinging ? MovingStep - 2 : MovingStep - 1;
            const double Start = LastPlant >= 0 ? PerStep * FMath::Min(LastPlant + 2, Steps) : 0.0;
            const double End = bSwinging ? PerStep * FMath::Min(MovingStep + 2, Steps) : Start;
            const double Eased = Swing * Swing * (3.0 - 2.0 * Swing);
            Motion.PivotYaw[Side] = FMath::Lerp(Start, End, Eased) - Angle * Progress;
            Motion.Lift[Side] = bSwinging ? 7.5 * FMath::Sin(UE_DOUBLE_PI * Swing) : 0.0;
        }
        return Motion;
    }

    FVector FootPosition(const UAnimSequence& Clip, const FReferenceSkeleton& Skeleton, int32 Bone, double Time)
    {
        FTransform InComponent = FTransform::Identity;
        const FAnimExtractContext Context(Time, false);
        while (Bone != INDEX_NONE)
        {
            FTransform Local = Skeleton.GetRefBonePose()[Bone];
            Clip.GetBoneTransform(Local, FSkeletonPoseBoneIndex(Bone), Context, false);
            InComponent = InComponent * Local;
            Bone = Skeleton.GetParentIndex(Bone);
        }
        return InComponent.GetLocation();
    }

    double FindStandingPose(const UAnimSequence& Clip)
    {
        const FReferenceSkeleton& Skeleton = Clip.GetSkeleton()->GetReferenceSkeleton();
        const int32 LeftToe = Skeleton.FindBoneIndex(TEXT("foot_end_l"));
        const int32 RightToe = Skeleton.FindBoneIndex(TEXT("foot_end_r"));
        const int32 LeftAnkle = Skeleton.FindBoneIndex(TEXT("foot_l"));
        const int32 RightAnkle = Skeleton.FindBoneIndex(TEXT("foot_r"));
        if (LeftToe == INDEX_NONE || RightToe == INDEX_NONE || LeftAnkle == INDEX_NONE || RightAnkle == INDEX_NONE)
        {
            return 0.0;
        }
        constexpr int32 Samples = 72;
        double LowestScore = TNumericLimits<double>::Max();
        double BestTime = 0.0;
        for (int32 Index = 0; Index < Samples; ++Index)
        {
            const double Time = Clip.GetPlayLength() * Index / Samples;
            const FVector A = FootPosition(Clip, Skeleton, LeftToe, Time);
            const FVector B = FootPosition(Clip, Skeleton, RightToe, Time);
            const double HeelDifference = FMath::Abs(FootPosition(Clip, Skeleton, LeftAnkle, Time).Z
                - FootPosition(Clip, Skeleton, RightAnkle, Time).Z);
            // Prefer two low, level toes in a compact stance instead of stopping on a swinging leg.
            const double Score = FMath::Max(A.Z, B.Z) + 4.0 * FMath::Abs(A.Z - B.Z)
                + HeelDifference * 1.5 + 0.15 * FVector::Dist2D(A, B);
            if (Score < LowestScore)
            {
                LowestScore = Score;
                BestTime = Time;
            }
        }
        return BestTime;
    }
}

ARanwarAmbientPedestrian::ARanwarAmbientPedestrian()
{
    PrimaryActorTick.bCanEverTick = true;
    SetRootComponent(CreateDefaultSubobject<USceneComponent>(TEXT("FootOrigin")));

    SkeletalMesh = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("PedestrianMesh"));
    SkeletalMesh->SetupAttachment(GetRootComponent());
    SkeletalMesh->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SkeletalMesh->SetGenerateOverlapEvents(false);
    SkeletalMesh->SetCanEverAffectNavigation(false);

    PassageCollider = CreateDefaultSubobject<UCapsuleComponent>(TEXT("PassageCollider"));
    PassageCollider->SetupAttachment(GetRootComponent());
    PassageCollider->InitCapsuleSize(21.0f, 79.0f);
    PassageCollider->SetRelativeLocation(FVector(0.0, 0.0, 79.0));
    PassageCollider->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    PassageCollider->SetCollisionObjectType(ECC_Pawn);
    PassageCollider->SetCollisionResponseToAllChannels(ECR_Ignore);
    PassageCollider->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
    PassageCollider->SetCollisionResponseToChannel(ECC_WorldDynamic, ECR_Block);
    PassageCollider->SetGenerateOverlapEvents(false);
}

void ARanwarAmbientPedestrian::BeginPlay()
{
    Super::BeginPlay();
    bStationary = MetaHumanClass && PathPoints.Num() < 2;
    const bool bConfigurationValid = FMath::IsFinite(WalkSpeed) && FMath::IsFinite(WalkClipSpeed)
        && WalkClipSpeed > 0.0f && FMath::IsFinite(InitialProgress) && FMath::IsFinite(MeshZOffset)
        && FMath::IsFinite(MeshYawOffset);
    const bool bVisualReady = bConfigurationValid && LoadVisual();
    const USkeletalMesh* MeshAsset = bVisualReady ? Body->GetSkeletalMeshAsset() : nullptr;
    const float ClipLength = WalkAnimation ? WalkAnimation->GetPlayLength() : 0.0f;
    const bool bWalkValid = MeshAsset && WalkAnimation && WalkAnimation->GetSkeleton() == MeshAsset->GetSkeleton()
        && FMath::IsFinite(ClipLength) && ClipLength > UE_SMALL_NUMBER;
    if (!MeshAsset || !MeshAsset->GetSkeleton() || (!bStationary && (!bWalkValid || !CachePathDistances()))
        || (bStationary && !bWalkValid && !IdleAnimation)
        || (IdleAnimation && (IdleAnimation->GetSkeleton() != MeshAsset->GetSkeleton()
            || !(IdleAnimation->GetPlayLength() > UE_SMALL_NUMBER))))
    {
        UE_LOG(LogTemp, Warning, TEXT("Ambient pedestrian %s has an invalid route, mesh, or walk animation."), *GetName());
        if (IsValid(MetaHumanVisual))
        {
            MetaHumanVisual->Destroy();
            MetaHumanVisual = nullptr;
        }
        SetActorHiddenInGame(true);
        SetActorTickEnabled(false);
        SkeletalMesh->SetComponentTickEnabled(false);
        return;
    }

    WalkSpeed = FMath::Clamp(WalkSpeed, 30.0f, 180.0f);
    if (bWalkValid && !IdleAnimation)
    {
        StandingPosition = FindStandingPose(*WalkAnimation);
        WalkPosition = StandingPosition;
    }
    if (bStationary)
    {
        if (!PathPoints.IsEmpty() && !PathPoints[0].ContainsNaN())
        {
            SetActorLocation(PathPoints[0]);
        }
        SetActorTickInterval(0.05f);
        if (bBlocksPassage)
        {
            PassageCollider->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
        }
    }
    else
    {
        TravelDistance = FMath::Clamp(InitialProgress, 0.0f, 1.0f) * PathDistances.Last();
        bForward = TravelDistance < PathDistances.Last();
        const int32 Segment = GetPathSegment();
        const double SegmentDistance = PathDistances[Segment + 1] - PathDistances[Segment];
        const double Alpha = (TravelDistance - PathDistances[Segment]) / SegmentDistance;
        const FVector Heading = PathPoints[Segment + 1] - PathPoints[Segment];
        const double FacingYaw = (bForward ? Heading : -Heading).Rotation().Yaw;
        SetActorLocationAndRotation(FMath::Lerp(PathPoints[Segment], PathPoints[Segment + 1], Alpha),
            FRotator(0.0, FacingYaw, 0.0), false, nullptr, ETeleportType::TeleportPhysics);
    }

    Body->VisibilityBasedAnimTickOption = bStationary ? EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered
        : EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
    Body->bEnableUpdateRateOptimizations = false;
    Body->AddTickPrerequisiteActor(this);
    Body->SetAnimInstanceClass(URanwarStrideAnimation::StaticClass());
    PresentMovement(0.0, 0.0f);
    Body->TickAnimation(0.0f, false);
    Body->RefreshBoneTransforms();
}

bool ARanwarAmbientPedestrian::LoadVisual()
{
    if (!MetaHumanClass)
    {
        Body = SkeletalMesh;
        const FQuat Facing(FRotator(0.0, MeshYawOffset, 0.0));
        PoseForward = Facing.UnrotateVector(FVector::ForwardVector).GetSafeNormal2D();
        Body->SetRelativeLocation(FVector(0.0, 0.0, MeshZOffset));
        Body->SetRelativeRotation(Facing);
        return true;
    }

    Body = RanwarCast::SpawnGroundedMetaHuman(*this, MetaHumanClass, 2, MeshZOffset, MeshYawOffset, &PoseForward);
    if (Body)
    {
        MetaHumanVisual = Body->GetOwner();
    }
    return Body != nullptr;
}

USkeletalMeshComponent* RanwarCast::SpawnGroundedMetaHuman(AActor& Owner, TSubclassOf<AActor> ActorClass,
    int32 MinimumLOD, float ZOffset, float YawOffset, FVector* PoseForward)
{
    FActorSpawnParameters Spawn;
    Spawn.Owner = &Owner;
    Spawn.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
    AActor* Visual = Owner.GetWorld()->SpawnActor<AActor>(ActorClass, Owner.GetActorTransform(), Spawn);
    if (!Visual)
    {
        return nullptr;
    }
    Visual->SetActorEnableCollision(false);
    USkeletalMeshComponent* Body = nullptr;
    TInlineComponentArray<USkeletalMeshComponent*> Meshes(Visual);
    for (USkeletalMeshComponent* Part : Meshes)
    {
        if (Part->GetFName() == TEXT("Body"))
        {
            Body = Part;
            break;
        }
    }
    const USkeletalMesh* Mesh = Body ? Body->GetSkeletalMeshAsset() : nullptr;
    if (!Mesh || !Visual->GetRootComponent())
    {
        Visual->Destroy();
        return nullptr;
    }
    const FReferenceSkeleton& Rest = Mesh->GetRefSkeleton();
    const int32 Toe = Rest.FindBoneIndex(TEXT("ball_l"));
    const int32 Ankle = Rest.FindBoneIndex(TEXT("foot_l"));
    const FBox Bounds = Mesh->GetBounds().GetBox();
    if (Toe == INDEX_NONE || Ankle == INDEX_NONE || !Bounds.IsValid)
    {
        Visual->Destroy();
        return nullptr;
    }
    const FVector Forward = FAnimationRuntime::GetComponentSpaceTransformRefPose(Rest, Toe).GetLocation()
        - FAnimationRuntime::GetComponentSpaceTransformRefPose(Rest, Ankle).GetLocation();
    if (Forward.SizeSquared2D() <= UE_SMALL_NUMBER)
    {
        Visual->Destroy();
        return nullptr;
    }
    const FTransform RelativeBody = Body->GetComponentTransform().GetRelativeTransform(Visual->GetActorTransform());
    if (RelativeBody.ContainsNaN() || FMath::IsNearlyZero(RelativeBody.GetScale3D().GetAbsMin())
        || !Visual->AttachToComponent(Owner.GetRootComponent(), FAttachmentTransformRules::KeepRelativeTransform))
    {
        Visual->Destroy();
        return nullptr;
    }
    const FQuat Facing(FRotator(0.0, YawOffset - Forward.Rotation().Yaw, 0.0));
    if (PoseForward)
    {
        *PoseForward = Facing.UnrotateVector(FVector::ForwardVector).GetSafeNormal2D();
    }
    const FTransform NormalizedBody(Facing, FVector(0.0, 0.0, ZOffset - Bounds.Min.Z));
    Visual->SetActorRelativeTransform(RelativeBody.Inverse() * NormalizedBody);
    if (ULODSyncComponent* Lod = Visual->FindComponentByClass<ULODSyncComponent>())
    {
        Lod->MinLOD = FMath::Max(Lod->MinLOD, MinimumLOD);
    }
    TInlineComponentArray<UGroomComponent*> Grooms(Visual);
    for (UGroomComponent* Groom : Grooms)
    {
        Groom->SimulationSettings.bOverrideSettings = true;
        Groom->SimulationSettings.SolverSettings.bEnableSimulation = false;
        Groom->SetUseCards(true);
        Groom->UpdateHairSimulation();
    }
    return Body;
}

void ARanwarAmbientPedestrian::EndPlay(EEndPlayReason::Type EndPlayReason)
{
    if (EndPlayReason == EEndPlayReason::Destroyed && IsValid(MetaHumanVisual))
    {
        MetaHumanVisual->Destroy();
    }
    Super::EndPlay(EndPlayReason);
}

bool ARanwarAmbientPedestrian::CachePathDistances()
{
    if (PathPoints.Num() < 2 || PathPoints.Num() > MaxPathPoints)
    {
        return false;
    }

    PathDistances.Reserve(PathPoints.Num());
    PathDistances.Add(0.0);
    for (int32 Index = 1; Index < PathPoints.Num(); ++Index)
    {
        const FVector& Start = PathPoints[Index - 1];
        const FVector& End = PathPoints[Index];
        const double Length = FVector::Dist2D(Start, End);
        const double Distance = PathDistances.Last() + Length;
        if (Start.ContainsNaN() || End.ContainsNaN() || !FMath::IsFinite(Distance) || Length < 1.0)
        {
            return false;
        }
        PathDistances.Add(Distance);
    }
    return true;
}

int32 ARanwarAmbientPedestrian::GetPathSegment() const
{
    for (int32 Index = 1; Index < PathDistances.Num() - 1; ++Index)
    {
        const double Boundary = PathDistances[Index];
        if (TravelDistance < Boundary || (!bForward && TravelDistance == Boundary))
        {
            return Index - 1;
        }
    }
    return PathDistances.Num() - 2;
}

void ARanwarAmbientPedestrian::PresentMovement(double Traveled, float DeltaSeconds)
{
    const bool bWasWalking = bWalking;
    bWalking = Traveled > UE_SMALL_NUMBER;
    FRanwarFootMotion Motion;
    Motion.Forward = PoseForward;
    UAnimSequence* Clip = WalkAnimation.Get();
    double Position = StandingPosition;
    if (bWalking)
    {
        // Shorter steps let slow patrols retain cadence without their soles slipping backwards.
        Motion.StrideScale = MetaHumanVisual ? 0.56 : 0.83;
        Motion.StrideScale *= FMath::GetMappedRangeValueClamped(FVector2D(15.0, 80.0),
            FVector2D(0.66, 1.0), CurrentSpeed);
        WalkPosition = FMath::Fmod(WalkPosition + Traveled / (WalkClipSpeed * Motion.StrideScale),
            static_cast<double>(WalkAnimation->GetPlayLength()));
        Position = WalkPosition;
    }
    else if (IdleAnimation)
    {
        Clip = IdleAnimation.Get();
        if (FMath::IsNearlyZero(TurnAngle))
        {
            IdlePosition = FMath::Fmod(IdlePosition + DeltaSeconds, static_cast<double>(IdleAnimation->GetPlayLength()));
        }
        Position = IdlePosition;
    }
    if (!FMath::IsNearlyZero(TurnAngle))
    {
        Motion = TurnFootMotion(TurnAngle, TurnProgress, PoseForward);
    }
    if (URanwarStrideAnimation* Stride = Cast<URanwarStrideAnimation>(Body->GetAnimInstance()))
    {
        Stride->Present(Clip, Position, DeltaSeconds, bWasWalking != bWalking, Motion);
    }
}

void ARanwarAmbientPedestrian::TurnTowards(double TargetYaw, float DeltaSeconds)
{
    if (FMath::IsNearlyZero(TurnAngle))
    {
        TurnStartYaw = GetActorRotation().Yaw;
        TurnAngle = FMath::FindDeltaAngleDegrees(TurnStartYaw, TargetYaw);
        TurnProgress = 0.0;
    }
    TurnProgress = FMath::Min(1.0, TurnProgress + TurnDegreesPerSecond * DeltaSeconds / FMath::Abs(TurnAngle));
    SetActorRotation(FRotator(0.0, TurnStartYaw + TurnAngle * TurnProgress, 0.0));
    CurrentSpeed = 0.0;
    PresentMovement(0.0, DeltaSeconds);
    if (TurnProgress >= 1.0)
    {
        TurnAngle = 0.0;
    }
}

void ARanwarAmbientPedestrian::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);

    const APlayerController* Player = GetWorld()->GetFirstPlayerController();
    const APawn* Pawn = Player ? Player->GetPawn() : nullptr;
    const FVector CurrentPosition = GetActorLocation();
    const double Range = bWithinRange ? StopWalkingRange : StartWalkingRange;
    const bool bRendered = MetaHumanVisual ? MetaHumanVisual->WasRecentlyRendered(0.7f) : Body->WasRecentlyRendered(0.7f);
    const bool bNear = Pawn && (FVector::DistSquared(CurrentPosition, Pawn->GetActorLocation()) <= FMath::Square(Range)
        || bRendered);
    if (bNear != bWithinRange)
    {
        bWithinRange = bNear;
        SetActorTickInterval(bNear ? (bStationary ? 0.05f : 0.0f) : DistantTickInterval);
        Body->SetComponentTickEnabled(bNear);
    }
    if (!bNear || DeltaSeconds <= 0.0f)
    {
        CurrentSpeed = 0.0;
        return;
    }
    if (bStationary)
    {
        PresentMovement(0.0, DeltaSeconds);
        return;
    }

    const int32 Segment = GetPathSegment();
    const double StartDistance = PathDistances[Segment];
    const double EndDistance = PathDistances[Segment + 1];
    const FVector Heading = PathPoints[Segment + 1] - PathPoints[Segment];
    const double TargetYaw = (bForward ? Heading : -Heading).Rotation().Yaw;
    const double StepSeconds = FMath::Min(DeltaSeconds, MaximumMoveStepSeconds);
    const double CurrentYaw = GetActorRotation().Yaw;
    const double HeadingDelta = FMath::FindDeltaAngleDegrees(CurrentYaw, TargetYaw);
    if (!FMath::IsNearlyZero(TurnAngle) || FMath::Abs(HeadingDelta) > WalkingHeadingTolerance)
    {
        TurnTowards(TargetYaw, static_cast<float>(StepSeconds));
        return;
    }
    const double TurnStep = TurnDegreesPerSecond * StepSeconds;
    const double FacingYaw = CurrentYaw + FMath::Clamp(HeadingDelta, -TurnStep, TurnStep);
    const FRotator Facing(0.0, FacingYaw, 0.0);

    const FVector PlayerPosition = Pawn->GetActorLocation();
    const FVector Direction = (bForward ? Heading : -Heading).GetSafeNormal2D();
    const FVector PlayerOffset = PlayerPosition - CurrentPosition;
    double StopDistance = bForward ? PathDistances.Last() - TravelDistance : TravelDistance;
    const int32 NextSegment = Segment + (bForward ? 1 : -1);
    if (NextSegment >= 0 && NextSegment < PathDistances.Num() - 1)
    {
        const FVector NextHeading = PathPoints[NextSegment + 1] - PathPoints[NextSegment];
        const double NextYaw = (bForward ? NextHeading : -NextHeading).Rotation().Yaw;
        if (FMath::Abs(FMath::FindDeltaAngleDegrees(TargetYaw, NextYaw)) > WalkingHeadingTolerance)
        {
            StopDistance = bForward ? EndDistance - TravelDistance : TravelDistance - StartDistance;
        }
    }
    const double Ahead = FVector::DotProduct(Direction, PlayerOffset);
    const double SideSquared = FMath::Max(0.0, PlayerOffset.SizeSquared2D() - FMath::Square(Ahead));
    if (FMath::Abs(PlayerOffset.Z) <= PlayerHeightTolerance && Ahead > 0.0 && SideSquared < FMath::Square(PlayerClearance))
    {
        const double ContactDistance = Ahead - FMath::Sqrt(FMath::Square(PlayerClearance) - SideSquared);
        StopDistance = FMath::Min(StopDistance, FMath::Max(0.0, ContactDistance));
    }
    const double TargetSpeed = FMath::Min(static_cast<double>(WalkSpeed), FMath::Sqrt(2.0 * SpeedChangePerSecond * StopDistance));
    CurrentSpeed += FMath::Clamp(TargetSpeed - CurrentSpeed, -SpeedChangePerSecond * StepSeconds, SpeedChangePerSecond * StepSeconds);
    const double Step = FMath::Min(CurrentSpeed * StepSeconds, StopDistance);
    const double NextDistance = FMath::Clamp(TravelDistance + (bForward ? Step : -Step), StartDistance, EndDistance);
    const double Alpha = (NextDistance - StartDistance) / (EndDistance - StartDistance);
    const FVector NextPosition = FMath::Lerp(PathPoints[Segment], PathPoints[Segment + 1], Alpha);

    TravelDistance = FMath::IsNearlyZero(NextDistance, 0.02) ? 0.0 : NextDistance;
    if (FMath::IsNearlyEqual(TravelDistance, PathDistances.Last(), 0.02))
    {
        TravelDistance = PathDistances.Last();
    }
    if (TravelDistance <= 0.0 || TravelDistance >= PathDistances.Last())
    {
        bForward = TravelDistance <= 0.0;
    }
    SetActorLocationAndRotation(NextPosition, Facing);
    PresentMovement(FVector::Dist2D(CurrentPosition, GetActorLocation()), static_cast<float>(StepSeconds));
}
