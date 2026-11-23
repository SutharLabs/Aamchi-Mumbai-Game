#include "RanwarGame.h"

#include "Animation/AnimSequence.h"
#include "Animation/ReferenceSkeleton.h"
#include "AnimationRuntime.h"
#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Components/TextRenderComponent.h"
#include "Engine/Canvas.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/SpringArmComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/PackageName.h"
#include "SeaLinkGame.h"
#include "TimerManager.h"
#include "UObject/ConstructorHelpers.h"
#include "UObject/UObjectGlobals.h"

namespace
{
    constexpr float WalkSpeed = 112.0f;
    constexpr float RunSpeed = 305.0f;
    constexpr double WalkClipSpeed = 89.3;
    constexpr double RunClipSpeed = 293.7;
    constexpr float StickLookDegreesPerSecond = 120.0f;
    constexpr float LandmarkRange = 265.0f;
    constexpr float LandmarkScanInterval = 0.15f;
    constexpr double LandmarkReadTime = 6.0;

    template <typename AssetType>
    AssetType* LoadOmkarAsset(const TCHAR* AssetName)
    {
        const FString Package = FString(TEXT("/Game/Ranwar/Characters/Omkar/")) + AssetName;
        if (!FPackageName::DoesPackageExist(Package, nullptr, false))
        {
            return nullptr;
        }
        return LoadObject<AssetType>(nullptr, *(Package + TEXT(".") + AssetName));
    }
}

ARanwarLandmark::ARanwarLandmark()
{
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("LandmarkOrigin"));
    DisplayName = NSLOCTEXT("Ranwar", "LandmarkName", "Landmark");
    Sign = CreateDefaultSubobject<UTextRenderComponent>(TEXT("LandmarkSign"));
    Sign->SetupAttachment(RootComponent);
    Sign->SetRelativeLocation(FVector(0.0, 0.0, 155.0));
    Sign->SetHorizontalAlignment(EHTA_Center);
    Sign->SetVerticalAlignment(EVRTA_TextCenter);
    Sign->SetWorldSize(23.0f);
    Sign->SetTextRenderColor(FColor(255, 241, 191));
    Sign->SetCollisionEnabled(ECollisionEnabled::NoCollision);
}

void ARanwarLandmark::OnConstruction(const FTransform& Transform)
{
    Super::OnConstruction(Transform);
    Sign->SetText(DisplayName);
}

void ARanwarLandmark::BeginPlay()
{
    Super::BeginPlay();
    Sign->SetText(DisplayName);
}

ARanwarCharacter::ARanwarCharacter()
{
    PrimaryActorTick.bCanEverTick = true;
    GetCapsuleComponent()->InitCapsuleSize(31.0f, 84.0f);
    bUseControllerRotationYaw = false;
    BaseEyeHeight = 56.0f;

    UCharacterMovementComponent* Movement = GetCharacterMovement();
    Movement->bOrientRotationToMovement = true;
    Movement->RotationRate = FRotator(0.0, 600.0, 0.0);
    Movement->MaxWalkSpeed = WalkSpeed;
    Movement->JumpZVelocity = 325.0f;
    Movement->MaxStepHeight = 36.0f;

    GetMesh()->SetRelativeLocation(FVector(0.0, 0.0, -84.0));
    GetMesh()->SetCollisionEnabled(ECollisionEnabled::NoCollision);

    USpringArmComponent* Arm = CreateDefaultSubobject<USpringArmComponent>(TEXT("FollowArm"));
    Arm->SetupAttachment(GetCapsuleComponent());
    Arm->SetRelativeLocation(FVector(0.0, 0.0, 55.0));
    Arm->TargetArmLength = 420.0f;
    Arm->SocketOffset = FVector(0.0, 35.0, 28.0);
    Arm->bUsePawnControlRotation = true;
    Arm->bDoCollisionTest = true;
    Arm->ProbeSize = 12.0f;

    UCameraComponent* Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("FollowCamera"));
    Camera->SetupAttachment(Arm, USpringArmComponent::SocketName);
    Camera->bUsePawnControlRotation = false;
    Camera->SetFieldOfView(80.0f);

    WalkTestMarker = CreateDefaultSubobject<USceneComponent>(TEXT("WalkTestMarker"));
    WalkTestMarker->SetupAttachment(GetCapsuleComponent());
    UStaticMeshComponent* Marker = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("MarkerVisual"));
    Marker->SetupAttachment(WalkTestMarker);
    Marker->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    Marker->SetGenerateOverlapEvents(false);
    Marker->SetRelativeLocation(FVector(0.0, 0.0, -4.0));
    Marker->SetRelativeScale3D(FVector(0.48, 0.48, 1.58));
    static ConstructorHelpers::FObjectFinder<UStaticMesh> MarkerMesh(TEXT("/Engine/BasicShapes/Cylinder.Cylinder"));
    if (MarkerMesh.Succeeded())
    {
        Marker->SetStaticMesh(MarkerMesh.Object);
    }
}

void ARanwarCharacter::BeginPlay()
{
    Super::BeginPlay();
    LoadOmkarAppearance();
    WalkTestMarker->SetVisibility(GetMesh()->GetSkeletalMeshAsset() == nullptr, true);
    GetWorldTimerManager().SetTimer(
        LandmarkScanTimer, this, &ARanwarCharacter::UpdateLandmarkFocus, LandmarkScanInterval, true);
}

void ARanwarCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (ActiveLoop)
    {
        UpdateLocomotion();
    }
}

void ARanwarCharacter::LoadOmkarAppearance()
{
    USkeletalMesh* Rig = LoadOmkarAsset<USkeletalMesh>(TEXT("Omkar"));
    if (!Rig)
    {
        return;
    }
    IdleLoop = LoadOmkarAsset<UAnimSequence>(TEXT("OmkarIdle"));
    WalkLoop = LoadOmkarAsset<UAnimSequence>(TEXT("OmkarWalk"));
    RunLoop = LoadOmkarAsset<UAnimSequence>(TEXT("OmkarRun"));
    if (!IdleLoop || !WalkLoop || !RunLoop || IdleLoop->GetSkeleton() != Rig->GetSkeleton()
        || WalkLoop->GetSkeleton() != Rig->GetSkeleton() || RunLoop->GetSkeleton() != Rig->GetSkeleton())
    {
        UE_LOG(LogTemp, Warning, TEXT("Ranwar: Omkar needs idle, walk, and run on the imported skeleton."));
        return;
    }

    const FBox Bounds = Rig->GetBounds().GetBox();
    const double Height = Bounds.GetSize().Z;
    const FReferenceSkeleton& Skeleton = Rig->GetRefSkeleton();
    const int32 AnkleIndex = Skeleton.FindBoneIndex(TEXT("LeftFoot"));
    const int32 ToesIndex = Skeleton.FindBoneIndex(TEXT("LeftToes"));
    if (Height < 145.0 || Height > 190.0 || AnkleIndex == INDEX_NONE || ToesIndex == INDEX_NONE)
    {
        UE_LOG(LogTemp, Warning, TEXT("Ranwar: Omkar import did not retain the expected scale and foot bones."));
        return;
    }

    // The reference ankle-to-toe vector defines the model's forward axis after import.
    const FVector Forward = FAnimationRuntime::GetComponentSpaceTransformRefPose(Skeleton, ToesIndex).GetLocation()
        - FAnimationRuntime::GetComponentSpaceTransformRefPose(Skeleton, AnkleIndex).GetLocation();
    if (Forward.SizeSquared2D() < 1.0)
    {
        UE_LOG(LogTemp, Warning, TEXT("Ranwar: Omkar import does not have a horizontal foot direction."));
        return;
    }

    GetMesh()->SetSkeletalMeshAsset(Rig);
    GetMesh()->SetRelativeRotation(FRotator(0.0, -Forward.Rotation().Yaw, 0.0));
    GetMesh()->SetRelativeLocation(FVector(0.0, 0.0, -GetCapsuleComponent()->GetUnscaledCapsuleHalfHeight() - Bounds.Min.Z));
    GetMesh()->PlayAnimation(IdleLoop.Get(), true);
    ActiveLoop = IdleLoop;
}

void ARanwarCharacter::UpdateLocomotion()
{
    if (GetCharacterMovement()->IsFalling())
    {
        GetMesh()->SetPlayRate(0.0f);
        return;
    }
    const double Speed = GetVelocity().Size2D();
    UAnimSequence* Next = IdleLoop.Get();
    double Rate = 1.0;
    if (Speed >= (ActiveLoop == RunLoop ? 128.0 : 144.0))
    {
        Next = RunLoop.Get();
        Rate = FMath::Clamp(Speed / RunClipSpeed, 0.40, 1.35);
    }
    else if (Speed > 18.0)
    {
        Next = WalkLoop.Get();
        Rate = FMath::Clamp(Speed / WalkClipSpeed, 0.35, 1.40);
    }
    if (ActiveLoop.Get() != Next)
    {
        GetMesh()->PlayAnimation(Next, true);
        ActiveLoop = Next;
    }
    GetMesh()->SetPlayRate(static_cast<float>(Rate));
}

void ARanwarCharacter::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    GetWorldTimerManager().ClearTimer(LandmarkScanTimer);
    Super::EndPlay(EndPlayReason);
}

void ARanwarCharacter::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis(TEXT("MoveForward"), this, &ARanwarCharacter::MoveForward);
    Input->BindAxis(TEXT("MoveRight"), this, &ARanwarCharacter::MoveRight);
    Input->BindAxis(TEXT("Turn"), this, &ARanwarCharacter::AddControllerYawInput);
    Input->BindAxis(TEXT("LookUp"), this, &ARanwarCharacter::AddControllerPitchInput);
    Input->BindAxis(TEXT("TurnWithStick"), this, &ARanwarCharacter::TurnWithStick);
    Input->BindAxis(TEXT("LookUpWithStick"), this, &ARanwarCharacter::LookUpWithStick);
    Input->BindAction(TEXT("Jump"), IE_Pressed, this, &ARanwarCharacter::Jump);
    Input->BindAction(TEXT("Jump"), IE_Released, this, &ARanwarCharacter::StopJumping);
    Input->BindAction(TEXT("Run"), IE_Pressed, this, &ARanwarCharacter::StartRunning);
    Input->BindAction(TEXT("Run"), IE_Released, this, &ARanwarCharacter::StopRunning);
    Input->BindAction(TEXT("Interact"), IE_Pressed, this, &ARanwarCharacter::Interact);
}

void ARanwarCharacter::UnPossessed()
{
    StopRunning();
    NearbyLandmark.Reset();
    Super::UnPossessed();
}

void ARanwarCharacter::MoveForward(float Value)
{
    const FRotator Heading(0.0, GetControlRotation().Yaw, 0.0);
    AddMovementInput(Heading.Vector(), Value);
}

void ARanwarCharacter::MoveRight(float Value)
{
    const FRotator Heading(0.0, GetControlRotation().Yaw + 90.0, 0.0);
    AddMovementInput(Heading.Vector(), Value);
}

void ARanwarCharacter::TurnWithStick(float Value)
{
    AddControllerYawInput(Value * StickLookDegreesPerSecond * GetWorld()->GetDeltaSeconds());
}

void ARanwarCharacter::LookUpWithStick(float Value)
{
    AddControllerPitchInput(Value * StickLookDegreesPerSecond * GetWorld()->GetDeltaSeconds());
}

void ARanwarCharacter::StartRunning()
{
    GetCharacterMovement()->MaxWalkSpeed = RunSpeed;
}

void ARanwarCharacter::StopRunning()
{
    GetCharacterMovement()->MaxWalkSpeed = WalkSpeed;
}

void ARanwarCharacter::UpdateLandmarkFocus()
{
    NearbyLandmark.Reset();
    if (!IsLocallyControlled())
    {
        return;
    }

    UWorld* World = GetWorld();
    const FVector Eyes = GetPawnViewLocation();
    double ClosestDistanceSquared = FMath::Square(static_cast<double>(LandmarkRange));
    for (TActorIterator<ARanwarLandmark> Landmark(World); Landmark; ++Landmark)
    {
        const FVector SignLocation = Landmark->GetActorLocation() + FVector(0.0, 0.0, 110.0);
        const double DistanceSquared = FVector::DistSquared(Eyes, SignLocation);
        if (DistanceSquared > ClosestDistanceSquared)
        {
            continue;
        }

        FCollisionQueryParams Params(SCENE_QUERY_STAT(RanwarLandmarkVisibility), false, this);
        Params.AddIgnoredActor(*Landmark);
        if (!World->LineTraceTestByChannel(Eyes, SignLocation, ECC_Visibility, Params))
        {
            NearbyLandmark = *Landmark;
            ClosestDistanceSquared = DistanceSquared;
        }
    }
}

void ARanwarCharacter::Interact()
{
    UpdateLandmarkFocus();
    if (const ARanwarLandmark* Landmark = NearbyLandmark.Get())
    {
        InteractionDetails = Landmark->GetDetails();
        DetailsUntil = GetWorld()->GetTimeSeconds() + LandmarkReadTime;
    }
}

FText ARanwarCharacter::GetInteractionPrompt() const
{
    if (const ARanwarLandmark* Landmark = NearbyLandmark.Get())
    {
        return FText::Format(
            NSLOCTEXT("Ranwar", "InteractPrompt", "Interact (E / B): {0}"),
            Landmark->GetDisplayName()
        );
    }
    return FText::GetEmpty();
}

FText ARanwarCharacter::GetInteractionDetails() const
{
    return GetWorld()->GetTimeSeconds() < DetailsUntil ? InteractionDetails : FText::GetEmpty();
}

void ARanwarHUD::DrawHUD()
{
    Super::DrawHUD();
    const ARanwarCharacter* Walker = PlayerOwner ? Cast<ARanwarCharacter>(PlayerOwner->GetPawn()) : nullptr;
    if (!Canvas || !Walker)
    {
        return;
    }

    const FText Details = Walker->GetInteractionDetails();
    const FText Notice = Details.IsEmpty() ? Walker->GetInteractionPrompt() : Details;
    if (Notice.IsEmpty())
    {
        return;
    }

    const FString Line = Notice.ToString();
    float TextWidth = 0.0f;
    float TextHeight = 0.0f;
    GetTextSize(Line, TextWidth, TextHeight, nullptr, 1.0f);
    const float Scale = FMath::Min(1.0f, FMath::Max(1.0f, Canvas->ClipX - 32.0f) / FMath::Max(TextWidth, 1.0f));
    TextWidth *= Scale;
    TextHeight *= Scale;
    const float Left = FMath::Max(12.0f, (Canvas->ClipX - TextWidth) * 0.5f);
    const float Top = Canvas->ClipY * 0.80f;
    DrawRect(FLinearColor(0.03f, 0.05f, 0.08f, 0.94f), Left - 8.0f, Top - 5.0f, TextWidth + 16.0f, TextHeight + 10.0f);
    DrawText(Line, FLinearColor::White, Left, Top, nullptr, Scale, false);
}

ARanwarGameMode::ARanwarGameMode()
{
    DefaultPawnClass = ARanwarCharacter::StaticClass();
    HUDClass = ARanwarHUD::StaticClass();
}

UClass* ARanwarGameMode::GetDefaultPawnClassForController_Implementation(AController* InController)
{
    // Earlier generated Sea Link levels may already exist without a per-map override.
    if (UGameplayStatics::GetCurrentLevelName(this, true) == TEXT("SeaLinkWalk"))
    {
        return ASeaLinkWalker::StaticClass();
    }
    return Super::GetDefaultPawnClassForController_Implementation(InController);
}
