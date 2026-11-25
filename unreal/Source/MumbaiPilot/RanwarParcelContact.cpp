#include "RanwarParcelContact.h"
#include "RanwarStrideAnimation.h"

#include "Animation/AnimSequence.h"
#include "AnimationRuntime.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/World.h"
#include "GameFramework/PlayerController.h"
#include "RanwarAmbientPedestrian.h"
#include "RanwarGame.h"

namespace
{
    constexpr double AttentionRange = 250.0;
    constexpr float IdleTickInterval = 0.05f;

    FRotator FaceVisitor(const AActor& Contact, const APawn& Visitor)
    {
        const FVector Direction = Visitor.GetActorLocation() - Contact.GetActorLocation();
        return FRotator(0.0, Direction.Rotation().Yaw, 0.0);
    }
}

ARanwarParcelContact::ARanwarParcelContact()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = IdleTickInterval;

    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("Feet"));
    RootComponent->SetMobility(EComponentMobility::Movable);
    Appearance = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("Appearance"));
    Appearance->SetupAttachment(RootComponent);
    Appearance->SetMobility(EComponentMobility::Movable);
    Appearance->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    SkeletalAppearance = CreateDefaultSubobject<USkeletalMeshComponent>(TEXT("SkeletalAppearance"));
    SkeletalAppearance->SetupAttachment(RootComponent);
    SkeletalAppearance->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SkeletalAppearance->SetGenerateOverlapEvents(false);
    SkeletalAppearance->SetVisibility(false);
    SkeletalAppearance->bEnableUpdateRateOptimizations = true;
    SkeletalAppearance->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
    SkeletalAppearance->PrimaryComponentTick.AddPrerequisite(this, PrimaryActorTick);

    UCapsuleComponent* Body = CreateDefaultSubobject<UCapsuleComponent>(TEXT("Body"));
    Body->SetupAttachment(RootComponent);
    Body->InitCapsuleSize(22.0f, 85.0f);
    Body->SetRelativeLocation(FVector(0.0, 0.0, 85.0));
    Body->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    Body->SetCollisionObjectType(ECC_Pawn);
    Body->SetCollisionResponseToAllChannels(ECR_Ignore);
    Body->SetCollisionResponseToChannel(ECC_Pawn, ECR_Block);
    Body->SetCollisionResponseToChannel(ECC_WorldDynamic, ECR_Block);
    Body->SetGenerateOverlapEvents(false);
}

void ARanwarParcelContact::BeginPlay()
{
    Super::BeginPlay();
    RestRotation = GetActorRotation();
    bHasAnimatedAppearance = StartBreathing();
    if (bHasAnimatedAppearance)
    {
        Appearance->SetVisibility(false);
        AnimationBody->SetVisibility(true);
        UE_LOG(LogTemp, Display, TEXT("Ranwar contact %s using grounded skeletal idle"),
            *GetNameSafe(AnimationBody->GetSkeletalMeshAsset()));
    }
}

void ARanwarParcelContact::EndPlay(EEndPlayReason::Type EndPlayReason)
{
    if (EndPlayReason == EEndPlayReason::Destroyed && IsValid(MetaHumanVisual))
    {
        MetaHumanVisual->Destroy();
    }
    Super::EndPlay(EndPlayReason);
}

bool ARanwarParcelContact::StartBreathing()
{
    if (!BreathLoop || !(BreathLoop->GetPlayLength() > UE_SMALL_NUMBER))
    {
        return false;
    }

    AnimationBody = MetaHumanClass ? RanwarCast::SpawnGroundedMetaHuman(*this, MetaHumanClass, 1)
        : SkeletalAppearance.Get();
    const USkeletalMesh* Rig = AnimationBody ? AnimationBody->GetSkeletalMeshAsset() : nullptr;
    const bool bGestureValid = ContactGesture && Rig && ContactGesture->GetSkeleton() == Rig->GetSkeleton()
        && ContactGesture->GetPlayLength() > UE_SMALL_NUMBER;
    if (!Rig || BreathLoop->GetSkeleton() != Rig->GetSkeleton() || ((!MetaHumanClass || ContactGesture) && !bGestureValid))
    {
        if (MetaHumanClass && AnimationBody)
        {
            AnimationBody->GetOwner()->Destroy();
            AnimationBody = nullptr;
        }
        return false;
    }
    if (MetaHumanClass)
    {
        MetaHumanVisual = AnimationBody->GetOwner();
        AnimationBody->AddTickPrerequisiteActor(this);
        AnimationBody->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;
    }
    else
    {
        const FReferenceSkeleton& Skeleton = Rig->GetRefSkeleton();
        const int32 Ankle = Skeleton.FindBoneIndex(TEXT("LeftFoot"));
        const int32 Toes = Skeleton.FindBoneIndex(TEXT("LeftToes"));
        if (Ankle == INDEX_NONE || Toes == INDEX_NONE)
        {
            return false;
        }
        const FVector Forward = FAnimationRuntime::GetComponentSpaceTransformRefPose(Skeleton, Toes).GetLocation()
            - FAnimationRuntime::GetComponentSpaceTransformRefPose(Skeleton, Ankle).GetLocation();
        if (Forward.SizeSquared2D() < 1.0)
        {
            return false;
        }
        // The legacy clips already plant the skinned shoe surface at the root origin.
        AnimationBody->SetRelativeRotation(FRotator(0.0, -Forward.Rotation().Yaw, 0.0));
    }
    AnimationBody->SetAnimInstanceClass(URanwarStrideAnimation::StaticClass());
    auto* Sampler = Cast<URanwarStrideAnimation>(AnimationBody->GetAnimInstance());
    if (!Sampler)
    {
        if (IsValid(MetaHumanVisual))
        {
            MetaHumanVisual->Destroy();
            MetaHumanVisual = nullptr;
            AnimationBody = nullptr;
        }
        return false;
    }
    Sampler->Present(BreathLoop, BreathPosition, 0.0f);
    AnimationBody->TickAnimation(0.0f, false);
    AnimationBody->RefreshBoneTransforms();
    return true;
}

const APawn* ARanwarParcelContact::FindNearbyVisitor() const
{
    const UWorld* World = GetWorld();
    const APlayerController* Player = World ? World->GetFirstPlayerController() : nullptr;
    const ARanwarCharacter* Walker = Player ? Cast<ARanwarCharacter>(Player->GetPawn()) : nullptr;
    const FVector Feet = GetActorLocation();
    if (!Walker || FVector::DistSquared(Walker->GetActorLocation(), Feet + FVector(0.0, 0.0, 85.0))
        > FMath::Square(AttentionRange))
    {
        return nullptr;
    }
    FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarParcelContactAttention), true, this);
    Query.AddIgnoredActor(Walker);
    return World->LineTraceTestByChannel(Walker->GetPawnViewLocation(), Feet + FVector(0.0, 0.0, 130.0),
        ECC_Visibility, Query) ? nullptr : Walker;
}

void ARanwarParcelContact::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    const APawn* Visitor = FindNearbyVisitor();
    const double Remaining = FMath::Max(0.0, ResponseUntil - GetWorld()->GetTimeSeconds());
    const FRotator Desired = Visitor ? FaceVisitor(*this, *Visitor) : (Remaining > 0.0 ? ResponseFacing : RestRotation);
    SetActorRotation(FMath::RInterpTo(GetActorRotation(), Desired, DeltaSeconds, 6.0f));
    if (bHasAnimatedAppearance)
    {
        if (auto* Sampler = Cast<URanwarStrideAnimation>(AnimationBody->GetAnimInstance()))
        {
            if (bPlayingGesture && Remaining > 0.0)
            {
                Sampler->Present(ContactGesture, FMath::Max(0.0, ContactGesture->GetPlayLength() - Remaining), DeltaSeconds);
            }
            else
            {
                if (bPlayingGesture)
                {
                    bPlayingGesture = false;
                    BreathPosition = 0.0;
                    SetActorTickInterval(IdleTickInterval);
                }
                else
                {
                    BreathPosition = FMath::Fmod(BreathPosition + DeltaSeconds, BreathLoop->GetPlayLength());
                }
                Sampler->Present(BreathLoop, BreathPosition, DeltaSeconds);
            }
        }
        return;
    }
    const double Pitch = Remaining > 0.0 ? -2.5 * FMath::Sin(UE_DOUBLE_PI * Remaining / 0.55) : 0.0;
    Appearance->SetRelativeRotation(FRotator(Pitch, 0.0, 0.0));
}

void ARanwarParcelContact::RespondTo(const APawn& Visitor)
{
    ResponseFacing = FaceVisitor(*this, Visitor);
    const bool bPlaysGesture = bHasAnimatedAppearance && ContactGesture;
    ResponseUntil = GetWorld()->GetTimeSeconds() + (bPlaysGesture ? ContactGesture->GetPlayLength() : 0.55);
    if (bPlaysGesture)
    {
        if (auto* Sampler = Cast<URanwarStrideAnimation>(AnimationBody->GetAnimInstance()))
        {
            Sampler->Present(ContactGesture, 0.0, 0.0f, bPlayingGesture);
            bPlayingGesture = true;
            SetActorTickInterval(0.0f);
            UE_LOG(LogTemp, Verbose, TEXT("Ranwar contact %s playing handover motion"),
                *GetNameSafe(AnimationBody->GetSkeletalMeshAsset()));
        }
    }
}
