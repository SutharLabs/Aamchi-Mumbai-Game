#include "RanwarGame.h"

#include "Animation/AnimSequence.h"
#include "ReferenceSkeleton.h"
#include "AnimationRuntime.h"
#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/Canvas.h"
#include "Engine/DamageEvents.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/SpringArmComponent.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/PackageName.h"
#include "RanwarPlayerController.h"
#include "RanwarRoute.h"
#include "RanwarVehicle.h"
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

    ARanwarRoute* FindRoute(const UWorld* World)
    {
        const ARanwarGameMode* Mode = World ? World->GetAuthGameMode<ARanwarGameMode>() : nullptr;
        return Mode ? Mode->GetRoute() : nullptr;
    }

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
    StartTransform = GetActorTransform();
    SafeGroundTransform = StartTransform;
    LoadOmkarAppearance();
    WalkTestMarker->SetVisibility(GetMesh()->GetSkeletalMeshAsset() == nullptr, true);
    GetWorldTimerManager().SetTimer(
        LandmarkScanTimer, this, &ARanwarCharacter::UpdateLandmarkFocus, LandmarkScanInterval, true);
}

void ARanwarCharacter::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (Health > 0.0f && IsPlayerControlled() && GetCharacterMovement()->IsMovingOnGround())
    {
        SafeGroundTransform = GetActorTransform();
        if (Health < 50.0f && GetWorld()->GetTimeSeconds() - LastDamageTime > 7.0)
        {
            Health = FMath::Min(Health + DeltaSeconds * 4.0f, 50.0f);
        }
    }
    if (ActiveLoop)
    {
        UpdateLocomotion();
    }
}

float ARanwarCharacter::TakeDamage(float DamageAmount, const FDamageEvent& DamageEvent,
    AController* EventInstigator, AActor* DamageCauser)
{
    if (Health <= 0.0f || !FMath::IsFinite(DamageAmount) || DamageAmount <= 0.0f)
    {
        return 0.0f;
    }
    const float Applied = FMath::Clamp(Super::TakeDamage(DamageAmount, DamageEvent, EventInstigator, DamageCauser), 0.0f, Health);
    if (Applied <= 0.0f)
    {
        return 0.0f;
    }
    Health -= Applied;
    LastDamageTime = GetWorld()->GetTimeSeconds();
    if (Health <= 0.0f)
    {
        GetCharacterMovement()->DisableMovement();
        InteractionDetails = NSLOCTEXT("Ranwar", "Injured", "Omkar is injured and will recover at the BEST stop.");
        DetailsUntil = LastDamageTime + 2.0;
        GetWorldTimerManager().SetTimer(RecoveryTimer, this, &ARanwarCharacter::RecoverAtStop, 2.0f, false);
    }
    return Applied;
}

void ARanwarCharacter::Landed(const FHitResult& Hit)
{
    const float ImpactSpeed = static_cast<float>(-GetVelocity().Z);
    Super::Landed(Hit);
    if (ImpactSpeed > 840.0f)
    {
        TakeDamage((ImpactSpeed - 840.0f) * 0.11f, FDamageEvent(), nullptr, nullptr);
    }
}

void ARanwarCharacter::FellOutOfWorld(const UDamageType& DamageType)
{
    if (TeleportTo(SafeGroundTransform.GetLocation() + FVector(0.0, 0.0, 8.0), SafeGroundTransform.Rotator()))
    {
        GetCharacterMovement()->StopMovementImmediately();
        GetCharacterMovement()->SetMovementMode(MOVE_Walking);
        InteractionDetails = NSLOCTEXT("Ranwar", "ReturnToStreet", "Returned to the last safe spot on the street.");
        DetailsUntil = GetWorld()->GetTimeSeconds() + LandmarkReadTime;
        return;
    }
    RecoverAtStop();
}

void ARanwarCharacter::RecoverAtStop()
{
    if (!TeleportTo(StartTransform.GetLocation(), StartTransform.Rotator())
        && !TeleportTo(SafeGroundTransform.GetLocation(), SafeGroundTransform.Rotator()))
    {
        GetWorldTimerManager().SetTimer(RecoveryTimer, this, &ARanwarCharacter::RecoverAtStop, 1.0f, false);
        return;
    }
    GetCharacterMovement()->StopMovementImmediately();
    GetCharacterMovement()->SetMovementMode(MOVE_Walking);
    Health = 100.0f;
    InteractionDetails = NSLOCTEXT("Ranwar", "RecoverAtStop", "Recovered at St Peter's BEST stop.");
    DetailsUntil = GetWorld()->GetTimeSeconds() + LandmarkReadTime;
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
    GetWorldTimerManager().ClearTimer(RecoveryTimer);
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
    NearbyVehicle.Reset();
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
    NearbyVehicle.Reset();
    if (!IsLocallyControlled())
    {
        return;
    }

    UWorld* World = GetWorld();
    double ClosestVehicleSquared = TNumericLimits<double>::Max();
    for (TActorIterator<ARanwarVehicle> Vehicle(World); Vehicle; ++Vehicle)
    {
        const double DistanceSquared = FVector::DistSquared(GetActorLocation(), Vehicle->GetActorLocation());
        if (DistanceSquared < ClosestVehicleSquared && Vehicle->CanEnter(this))
        {
            NearbyVehicle = *Vehicle;
            ClosestVehicleSquared = DistanceSquared;
        }
    }
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
    if (Health <= 0.0f)
    {
        return;
    }
    UpdateLandmarkFocus();
    ARanwarRoute* Route = FindRoute(GetWorld());
    if (Route && Route->Interact(*this))
    {
        return;
    }
    if (ARanwarVehicle* Vehicle = NearbyVehicle.Get(); Vehicle && Vehicle->TryEnter(this))
    {
        if (Route)
        {
            Route->OnVehicleEntry(*Vehicle);
        }
        return;
    }
    if (const ARanwarLandmark* Landmark = NearbyLandmark.Get())
    {
        InteractionDetails = Landmark->GetDetails();
        DetailsUntil = GetWorld()->GetTimeSeconds() + LandmarkReadTime;
    }
}

FText ARanwarCharacter::GetInteractionPrompt() const
{
    if (Health <= 0.0f)
    {
        return FText::GetEmpty();
    }
    if (const ARanwarRoute* Route = FindRoute(GetWorld()))
    {
        FText Prompt = Route->GetPrompt(*this);
        if (!Prompt.IsEmpty())
        {
            return Prompt;
        }
    }
    if (const ARanwarVehicle* Vehicle = NearbyVehicle.Get())
    {
        return FText::Format(NSLOCTEXT("Ranwar", "VehiclePrompt", "Drive {0} (E / B)"), Vehicle->GetVehicleName());
    }
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
    const APawn* Pawn = PlayerOwner ? PlayerOwner->GetPawn() : nullptr;
    if (!Canvas || !Pawn)
    {
        return;
    }

    const ARanwarCharacter* Walker = Cast<ARanwarCharacter>(Pawn);
    const ARanwarVehicle* Vehicle = Cast<ARanwarVehicle>(Pawn);
    const ARanwarRoute* Route = FindRoute(GetWorld());
    const FLinearColor Backdrop(0.03f, 0.05f, 0.08f, 0.92f);
    const FLinearColor Amber(1.0f, 0.76f, 0.31f);
    if (Route)
    {
        DrawRect(Backdrop, 12.0f, 12.0f, 290.0f, 48.0f);
        DrawText(TEXT("RANWAR  /  BANDRA WEST"), Amber, 23.0f, 19.0f);
        DrawText(Route->GetObjective(Pawn->GetActorLocation()).ToString(), FLinearColor::White, 23.0f, 39.0f);

        const float Right = Canvas->ClipX - 160.0f;
        DrawRect(Backdrop, Right, 12.0f, 148.0f, 72.0f);
        DrawText(FString::Printf(TEXT("INR %d"), Route->GetCash()), FLinearColor::White, Right + 11.0f, 19.0f);
        const int32 Alert = Route->GetPoliceAlert();
        DrawText(Alert ? TEXT("Police alert") : TEXT("Police clear"), Alert ? Amber : FLinearColor::White, Right + 11.0f, 39.0f);
        const ARanwarCharacter* HealthOwner = Vehicle ? Vehicle->GetDriver() : Walker;
        if (HealthOwner)
        {
            const float Vitality = HealthOwner->GetHealth() / 100.0f;
            DrawText(TEXT("Health"), FLinearColor::White, Right + 11.0f, 60.0f);
            DrawRect(FLinearColor(0.18f, 0.19f, 0.21f), Right + 63.0f, 63.0f, 70.0f, 8.0f);
            DrawRect(FLinearColor(0.23f, 0.83f, 0.63f), Right + 63.0f, 63.0f, 70.0f * Vitality, 8.0f);
        }

        FVector Waypoint;
        FVector2D Screen;
        if (Route->GetWaypoint(Waypoint) && FVector::DistSquared2D(Pawn->GetActorLocation(), Waypoint) > FMath::Square(160.0)
            && PlayerOwner->ProjectWorldLocationToScreen(Waypoint + FVector(0.0, 0.0, 150.0), Screen)
            && Screen.X > 15.0 && Screen.X < Canvas->ClipX - 15.0 && Screen.Y > 80.0 && Screen.Y < Canvas->ClipY - 30.0)
        {
            const float X = static_cast<float>(Screen.X);
            const float Y = static_cast<float>(Screen.Y);
            DrawLine(X, Y - 8.0f, X + 8.0f, Y, Amber, 2.0f);
            DrawLine(X + 8.0f, Y, X, Y + 8.0f, Amber, 2.0f);
            DrawLine(X, Y + 8.0f, X - 8.0f, Y, Amber, 2.0f);
            DrawLine(X - 8.0f, Y, X, Y - 8.0f, Amber, 2.0f);
        }
    }

    FText Prompt;
    FText Notice = Route ? Route->GetNotice() : FText::GetEmpty();
    if (Vehicle)
    {
        const float Right = Canvas->ClipX - 136.0f;
        const float Bottom = Canvas->ClipY - 65.0f;
        DrawRect(Backdrop, Right, Bottom, 124.0f, 53.0f);
        DrawText(FString::Printf(TEXT("%d km/h"), FMath::RoundToInt(Vehicle->GetSpeedKph())), Amber, Right + 12.0f, Bottom + 9.0f);
        DrawText(FString::Printf(TEXT("Vehicle %d%%"), FMath::RoundToInt(Vehicle->GetCondition())), FLinearColor::White,
            Right + 12.0f, Bottom + 29.0f);
        Prompt = NSLOCTEXT("Ranwar", "DriveExit", "E / B  Exit     Space / A  Brake");
    }
    else if (Walker)
    {
        Prompt = Walker->GetInteractionPrompt();
        if (Notice.IsEmpty())
        {
            Notice = Walker->GetInteractionDetails();
        }
    }

    const FText VisibleText = Prompt.IsEmpty() ? Notice : Prompt;
    if (VisibleText.IsEmpty())
    {
        return;
    }
    const FString Line = VisibleText.ToString();
    float TextWidth = 0.0f;
    float TextHeight = 0.0f;
    GetTextSize(Line, TextWidth, TextHeight, nullptr, 1.0f);
    const float Scale = FMath::Min(1.0f, FMath::Max(1.0f, Canvas->ClipX - 32.0f) / FMath::Max(TextWidth, 1.0f));
    TextWidth *= Scale;
    TextHeight *= Scale;
    const float Left = FMath::Max(12.0f, (Canvas->ClipX - TextWidth) * 0.5f);
    const float Top = Canvas->ClipY * 0.86f;
    DrawRect(Backdrop, Left - 8.0f, Top - 5.0f, TextWidth + 16.0f, TextHeight + 10.0f);
    DrawText(Line, FLinearColor::White, Left, Top, nullptr, Scale, false);
}

ARanwarGameMode::ARanwarGameMode()
{
    DefaultPawnClass = ARanwarCharacter::StaticClass();
    PlayerControllerClass = ARanwarPlayerController::StaticClass();
    HUDClass = ARanwarHUD::StaticClass();
}

void ARanwarGameMode::BeginPlay()
{
    Super::BeginPlay();
    const TActorIterator<ARanwarRoute> RouteActor(GetWorld());
    if (RouteActor)
    {
        Route = *RouteActor;
    }
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
