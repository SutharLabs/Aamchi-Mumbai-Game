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
#include "RanwarAudio.h"
#include "RanwarEnvironment.h"
#include "RanwarMap.h"
#include "RanwarPlayerController.h"
#include "RanwarRoute.h"
#include "RanwarTraffic.h"
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
    // Each animation loop contains two footfalls at the retargeted clip speed.
    constexpr double WalkStepDistance = 59.5;
    constexpr double RunRightContact = 5.0 / 30.0;
    constexpr double RunLeftContact = 16.0 / 30.0;
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
    Arm->SocketOffset = FVector(0.0, -28.0, 28.0);
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
    const double Speed = GetVelocity().Size2D();
    if (Health > 0.0f && IsLocallyControlled() && GetCharacterMovement()->IsMovingOnGround() && Speed > 20.0)
    {
        if (RunLoop && ActiveLoop == RunLoop)
        {
            DistanceSinceStep = 0.0;
            const double Current = GetMesh()->GetPosition();
            double Previous = LastRunStepPosition;
            LastRunStepPosition = Current;
            if (Previous < 0.0 || Previous == Current)
            {
                return;
            }
            if (Current < Previous)
            {
                Previous -= RunLoop->GetPlayLength();
            }
            if (Previous < RunLeftContact && Current >= RunLeftContact)
            {
                RanwarAudio::PlayFootstep(*this, true, false);
            }
            else if (Previous < RunRightContact && Current >= RunRightContact)
            {
                RanwarAudio::PlayFootstep(*this, true, true);
            }
            return;
        }
        LastRunStepPosition = -1.0;
        DistanceSinceStep += Speed * DeltaSeconds;
        if (DistanceSinceStep >= WalkStepDistance)
        {
            RanwarAudio::PlayFootstep(*this, false, bRightFootNext);
            bRightFootNext = !bRightFootNext;
            DistanceSinceStep = FMath::Fmod(DistanceSinceStep, WalkStepDistance);
        }
    }
    else
    {
        DistanceSinceStep = 0.0;
        LastRunStepPosition = -1.0;
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
    // Evaluate the first idle pose before the startup or pause overlay can freeze the world.
    GetMesh()->TickAnimation(0.0f, false);
    GetMesh()->RefreshBoneTransforms();
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
    const ARanwarPlayerController* Controller = Cast<ARanwarPlayerController>(PlayerOwner);
    if (!Canvas || !Pawn || !Controller || Controller->IsMenuOpen())
    {
        return;
    }

    const ARanwarCharacter* Walker = Cast<ARanwarCharacter>(Pawn);
    const ARanwarVehicle* Vehicle = Cast<ARanwarVehicle>(Pawn);
    const ARanwarRoute* Route = FindRoute(GetWorld());
    const ARanwarTraffic* Traffic = Controller->GetMapTraffic();
    const bool bLiveMap = Traffic && Controller->IsLiveMapEnabled();
    const float Scale = FMath::Clamp(Canvas->ClipY / 720.0f, 0.85f, 1.5f);
    const float Margin = 19.0f * Scale;
    const FLinearColor Panel(0.018f, 0.035f, 0.062f, 0.90f);
    const FLinearColor Ink(0.95f, 0.94f, 0.90f);
    const FLinearColor Muted(0.70f, 0.76f, 0.84f);
    const FLinearColor Gold(0.98f, 0.78f, 0.43f);
    const FLinearColor Coral(1.0f, 0.53f, 0.39f);
    const FLinearColor Green(0.30f, 0.82f, 0.64f);
    const float Padding = 12.0f * Scale;
    const float DockWidth = FMath::Min(202.0f * Scale, Canvas->ClipX * 0.30f);
    const auto Label = [&](const FString& Text, const FLinearColor& Color, float X, float Y, float Size = 1.0f)
    {
        DrawText(Text, Color, X, Y, nullptr, Scale * Size, false);
    };
    const auto FitLabel = [&](const FString& Text, const FLinearColor& Color, float X, float Y, float Width, float Size)
    {
        float LineWidth = 0.0f;
        float LineHeight = 0.0f;
        GetTextSize(Text, LineWidth, LineHeight, nullptr, Scale * Size);
        Label(Text, Color, X, Y, Size * FMath::Min(1.0f, Width / FMath::Max(1.0f, LineWidth)));
    };
    const auto Wrap = [&](const FString& Text, float MaxWidth, float FontScale)
    {
        TArray<FString> Words;
        Text.ParseIntoArrayWS(Words);
        TArray<FString> Lines;
        FString Line;
        for (const FString& Word : Words)
        {
            const FString Combined = Line.IsEmpty() ? Word : Line + TEXT(" ") + Word;
            float Width = 0.0f;
            float Height = 0.0f;
            GetTextSize(Combined, Width, Height, nullptr, Scale * FontScale);
            if (!Line.IsEmpty() && Width > MaxWidth)
            {
                Lines.Add(MoveTemp(Line));
                Line = Word;
            }
            else
            {
                Line = Combined;
            }
        }
        if (!Line.IsEmpty())
        {
            Lines.Add(MoveTemp(Line));
        }
        return Lines;
    };
    const auto DrawCenteredCard = [&](const FText& Text, const FText& Heading, float Bottom, float MaximumWidth, float FontScale)
    {
        const float MaxTextWidth = FMath::Max(54.0f, MaximumWidth - Padding * 2.0f);
        const TArray<FString> Lines = Wrap(Text.ToString(), MaxTextWidth, FontScale);
        float BoxWidth = 0.0f;
        float TextHeight = 0.0f;
        for (const FString& Line : Lines)
        {
            float Width = 0.0f;
            float Height = 0.0f;
            GetTextSize(Line, Width, Height, nullptr, Scale * FontScale);
            BoxWidth = FMath::Max(BoxWidth, Width);
            TextHeight = FMath::Max(TextHeight, Height);
        }
        const FString Name = Heading.ToString();
        float HeadingWidth = 0.0f;
        float HeadingHeight = 0.0f;
        GetTextSize(Name, HeadingWidth, HeadingHeight, nullptr, Scale);
        BoxWidth = FMath::Min(MaxTextWidth, FMath::Max(BoxWidth, HeadingWidth)) + Padding * 2.0f;
        const float HeadingSpace = Name.IsEmpty() ? 0.0f : HeadingHeight + 4.0f * Scale;
        const float LineStep = TextHeight + 4.0f * Scale;
        const float BoxHeight = LineStep * Lines.Num() + HeadingSpace + Padding * 2.0f - 4.0f * Scale;
        const float Left = (Canvas->ClipX - BoxWidth) * 0.5f;
        const float Top = Bottom - BoxHeight;
        const float TextLeft = Left + Padding;
        DrawRect(Panel, Left, Top, BoxWidth, BoxHeight);
        if (!Name.IsEmpty())
        {
            FitLabel(Name, Gold, TextLeft, Top + Padding, MaxTextWidth, 1.0f);
        }
        for (int32 Index = 0; Index < Lines.Num(); ++Index)
        {
            FitLabel(Lines[Index], Ink, TextLeft, Top + Padding + HeadingSpace + Index * LineStep, MaxTextWidth, FontScale);
        }
        return Top;
    };

    TOptional<FVector> Waypoint;
    if (Route)
    {
        FVector Destination;
        if (Route->GetWaypoint(Destination))
        {
            Waypoint = Destination;
        }
        const float CardWidth = FMath::Min(356.0f * Scale, Canvas->ClipX * 0.50f);
        const TArray<FString> Objective = Wrap(Route->GetObjective(Pawn->GetActorLocation()).ToString(),
            CardWidth - Padding * 2.0f - 3.0f * Scale, 1.17f);
        const float CardHeight = (37.0f + Objective.Num() * 18.0f) * Scale;
        DrawRect(Panel, Margin, Margin, CardWidth, CardHeight);
        DrawRect(Gold, Margin, Margin, 3.0f * Scale, CardHeight);
        const float ObjectiveX = Margin + Padding + 3.0f * Scale;
        Label(TEXT("RANWAR / BANDRA WEST"), Gold, ObjectiveX, Margin + 11.0f * Scale);
        for (int32 Index = 0; Index < Objective.Num(); ++Index)
        {
            FitLabel(Objective[Index], Ink, ObjectiveX, Margin + (32.0f + 18.0f * Index) * Scale,
                CardWidth - Padding * 2.0f, 1.17f);
        }

        const float Right = Canvas->ClipX - DockWidth - Margin;
        DrawRect(Panel, Right, Margin, DockWidth, 90.0f * Scale);
        Label(FString::Printf(TEXT("INR %d"), Route->GetCash()), Ink, Right + Padding, Margin + 10.0f * Scale, 1.28f);
        const int32 Alert = Route->GetPoliceAlert();
        Label(Alert ? TEXT("Police alert") : TEXT("Police clear"), Alert ? Coral : Muted, Right + Padding, Margin + 34.0f * Scale);
        const ARanwarCharacter* HealthOwner = Vehicle ? Vehicle->GetDriver() : Walker;
        if (HealthOwner)
        {
            const float Vitality = FMath::Clamp(HealthOwner->GetHealth() / 100.0f, 0.0f, 1.0f);
            Label(FString::Printf(TEXT("Health   %d%%"), FMath::RoundToInt(Vitality * 100.0f)), Ink,
                Right + Padding, Margin + 53.0f * Scale);
            const float BarWidth = DockWidth - Padding * 2.0f;
            DrawRect(FLinearColor(0.16f, 0.21f, 0.28f), Right + Padding, Margin + 74.0f * Scale, BarWidth, 5.0f * Scale);
            DrawRect(Vitality <= 0.30f ? Coral : Green, Right + Padding, Margin + 74.0f * Scale,
                BarWidth * Vitality, 5.0f * Scale);
        }

        FVector2D Screen;
        const double DistanceSquared = Waypoint.IsSet()
            ? FVector::DistSquared2D(Pawn->GetActorLocation(), Waypoint.GetValue()) : 0.0;
        if (Route->UsesParcelGroundHint() && Waypoint.IsSet() && DistanceSquared > FMath::Square(210.0)
            && DistanceSquared < FMath::Square(2000.0))
        {
            const FVector Point = Waypoint.GetValue();
            FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarGroundHint), true, Pawn);
            FHitResult Ground;
            const FCollisionObjectQueryParams Surfaces(ECC_WorldStatic);
            FVector ViewLocation;
            FRotator ViewRotation;
            PlayerOwner->GetPlayerViewPoint(ViewLocation, ViewRotation);
            if (GetWorld()->LineTraceSingleByObjectType(Ground, Point + FVector(0.0, 0.0, 65.0),
                    Point - FVector(0.0, 0.0, 140.0), Surfaces, Query)
                && Ground.ImpactNormal.Z > 0.70
                && !GetWorld()->LineTraceTestByChannel(ViewLocation, Ground.ImpactPoint + FVector(0.0, 0.0, 9.0),
                    ECC_Visibility, Query))
            {
                const FVector Centre = Ground.ImpactPoint + Ground.ImpactNormal * 3.0;
                FLinearColor MarkColor = Gold;
                MarkColor.A = 0.54f;
                constexpr int32 DashCount = 8;
                constexpr double Step = UE_TWO_PI / DashCount;
                for (int32 Segment = 0; Segment < DashCount; ++Segment)
                {
                    const double Angle = Segment * Step;
                    const double EndAngle = Angle + Step * 0.60;
                    const FVector StartOffset(FMath::Cos(Angle) * 31.0, FMath::Sin(Angle) * 31.0, 0.0);
                    const FVector EndOffset(FMath::Cos(EndAngle) * 31.0, FMath::Sin(EndAngle) * 31.0, 0.0);
                    FVector2D StartScreen;
                    FVector2D EndScreen;
                    if (PlayerOwner->ProjectWorldLocationToScreen(Centre + FVector::VectorPlaneProject(StartOffset, Ground.ImpactNormal), StartScreen)
                        && PlayerOwner->ProjectWorldLocationToScreen(Centre + FVector::VectorPlaneProject(EndOffset, Ground.ImpactNormal), EndScreen)
                        && StartScreen.X > Margin && StartScreen.X < Canvas->ClipX - Margin
                        && StartScreen.Y > Margin + CardHeight && StartScreen.Y < Canvas->ClipY - Margin)
                    {
                        DrawLine(static_cast<float>(StartScreen.X), static_cast<float>(StartScreen.Y),
                            static_cast<float>(EndScreen.X), static_cast<float>(EndScreen.Y), MarkColor, 2.0f * Scale);
                    }
                }
            }
        }
        else if (!Route->UsesParcelGroundHint() && Waypoint.IsSet() && DistanceSquared > FMath::Square(160.0)
            && PlayerOwner->ProjectWorldLocationToScreen(Waypoint.GetValue() + FVector(0.0, 0.0, 150.0), Screen)
            && Screen.X > Margin && Screen.X < Canvas->ClipX - Margin
            && Screen.Y > Margin + FMath::Max(CardHeight, 95.0f * Scale) && Screen.Y < Canvas->ClipY * 0.76f)
        {
            const float X = static_cast<float>(Screen.X);
            const float Y = static_cast<float>(Screen.Y);
            const float Radius = 7.0f * Scale;
            DrawLine(X, Y - Radius, X + Radius, Y, Gold, 2.0f);
            DrawLine(X + Radius, Y, X, Y + Radius, Gold, 2.0f);
            DrawLine(X, Y + Radius, X - Radius, Y, Gold, 2.0f);
            DrawLine(X - Radius, Y, X, Y - Radius, Gold, 2.0f);
        }
    }

    const float DockLeft = Canvas->ClipX - DockWidth - Margin;
    const float MapHeight = 126.0f * Scale;
    float DockTop = Canvas->ClipY - Margin;
    if (bLiveMap)
    {
        DockTop -= MapHeight;
        DrawRect(Panel, DockLeft, DockTop, DockWidth, MapHeight);
        Label(TEXT("RANWAR"), Muted, DockLeft + Padding, DockTop + 8.0f * Scale, 0.92f);
        RanwarMap::Draw(*Traffic, FVector2D(DockLeft, DockTop + 17.0f * Scale),
            FVector2D(DockWidth, MapHeight - 20.0f * Scale), Pawn->GetActorLocation(), Pawn->GetActorForwardVector(),
            Waypoint, [this](const FVector2D& Start, const FVector2D& End, const FLinearColor& Color, float Thickness)
            {
                DrawLine(static_cast<float>(Start.X), static_cast<float>(Start.Y),
                    static_cast<float>(End.X), static_cast<float>(End.Y), Color, Thickness);
            }, true);
        DockTop -= 7.0f * Scale;
    }

    FText Prompt;
    FText Notice = Route ? Route->GetNotice() : FText::GetEmpty();
    if (Vehicle)
    {
        DockTop -= 57.0f * Scale;
        DrawRect(Panel, DockLeft, DockTop, DockWidth, 57.0f * Scale);
        Label(FString::Printf(TEXT("%d km/h"), FMath::RoundToInt(Vehicle->GetSpeedKph())), Gold,
            DockLeft + Padding, DockTop + 8.0f * Scale, 1.43f);
        Label(FString::Printf(TEXT("Condition   %d%%"), FMath::RoundToInt(Vehicle->GetCondition())), Ink,
            DockLeft + Padding, DockTop + 34.0f * Scale);
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

    float Bottom = Canvas->ClipY - Margin - 10.0f * Scale;
    float CardWidth = FMath::Min(660.0f * Scale, Canvas->ClipX - Margin * 2.0f);
    if (bLiveMap || Vehicle)
    {
        const float WidthBetweenDocks = Canvas->ClipX - 2.0f * (DockWidth + Margin * 2.0f);
        if (WidthBetweenDocks >= 300.0f * Scale)
        {
            CardWidth = FMath::Min(CardWidth, WidthBetweenDocks);
        }
        else
        {
            Bottom = FMath::Min(Bottom, DockTop - 8.0f * Scale);
        }
    }
    if (Route && Controller->IsSubtitleEnabled())
    {
        const FText Dialogue = Route->GetDialogueText();
        if (!Dialogue.IsEmpty())
        {
            const FText Speaker = Controller->ShouldShowSubtitleSpeaker() ? Route->GetDialogueSpeaker() : FText::GetEmpty();
            Bottom = DrawCenteredCard(Dialogue, Speaker, Bottom, CardWidth,
                Controller->IsSubtitleLarge() ? 1.85f : 1.48f) - 10.0f * Scale;
        }
    }
    if (!Prompt.IsEmpty())
    {
        Bottom = DrawCenteredCard(Prompt, FText::GetEmpty(), Bottom, CardWidth, 1.08f) - 10.0f * Scale;
    }
    if (!Notice.IsEmpty())
    {
        DrawCenteredCard(Notice, FText::GetEmpty(), Bottom, CardWidth, 1.08f);
    }
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
        if (!TActorIterator<ARanwarEnvironment>(GetWorld()))
        {
            ARanwarEnvironment::CreateExposure(*GetWorld());
        }
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
