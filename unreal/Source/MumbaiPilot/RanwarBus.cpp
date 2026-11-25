#include "RanwarBus.h"

#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "CollisionShape.h"
#include "Components/CapsuleComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/World.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "RanwarGame.h"

#define LOCTEXT_NAMESPACE "RanwarBus"

namespace
{
    // The original arrival mesh faces +X. Its open front doors are on the curb side at -Y.
    const FVector DoorCurbPoint(272.0, -218.0, 0.0);
    const FVector PassengerSeat(225.0, -24.0, 115.0);
    constexpr double BoardingRange = 145.0;
}

ARanwarBus::ARanwarBus()
{
    PassengerCamera = CreateDefaultSubobject<UCameraComponent>(TEXT("PassengerCamera"));
    PassengerCamera->SetupAttachment(GetStaticMeshComponent());
    PassengerCamera->SetRelativeLocation(PassengerSeat + FVector(0.0, 0.0, 35.0));
    PassengerCamera->SetRelativeRotation(FRotator(-6.0, -66.0, 0.0));
    PassengerCamera->SetFieldOfView(74.0f);
    PassengerCamera->bUsePawnControlRotation = false;
}

FVector ARanwarBus::GetBoardingPoint() const
{
    return GetActorTransform().TransformPosition(DoorCurbPoint);
}

bool ARanwarBus::IsPassenger(const ARanwarCharacter& Character) const
{
    return Passenger.Get() == &Character;
}

bool ARanwarBus::CanBoard(const ARanwarCharacter& Character) const
{
    if (Passenger.IsValid() || Character.GetWorld() != GetWorld() || !Character.IsPlayerControlled()
        || Character.GetHealth() <= 0.0f || Character.IsHidden() || !Character.GetActorEnableCollision()
        || Character.GetCharacterMovement()->IsFalling())
    {
        return false;
    }
    const FVector Location = Character.GetActorLocation();
    const FVector Point = GetBoardingPoint();
    if (FVector::DistSquared2D(Location, Point) > FMath::Square(BoardingRange)
        || FMath::Abs(Location.Z - Point.Z) > 155.0
        || GetActorTransform().InverseTransformPosition(Location).Y > -130.0)
    {
        return false;
    }

    FCollisionQueryParams Trace(SCENE_QUERY_STAT(RanwarBusBoarding), false, &Character);
    Trace.AddIgnoredActor(this);
    return !GetWorld()->LineTraceTestByChannel(Character.GetPawnViewLocation(),
        Point + FVector(0.0, 0.0, 100.0), ECC_Visibility, Trace);
}

FText ARanwarBus::GetPrompt(const ARanwarCharacter& Character) const
{
    if (IsPassenger(Character))
    {
        return bExitBlocked ? LOCTEXT("BlockedExit", "Curb is blocked. Try the exit again (E / B)")
            : LOCTEXT("Alight", "Step off the BEST bus (E / B)");
    }
    return CanBoard(Character) ? LOCTEXT("Board", "Board the BEST bus (E / B)") : FText::GetEmpty();
}

bool ARanwarBus::FindExitLocation(const ARanwarCharacter& Character, FVector& Location) const
{
    const UCapsuleComponent* Capsule = Character.GetCapsuleComponent();
    const float Radius = Capsule->GetScaledCapsuleRadius();
    const float HalfHeight = Capsule->GetScaledCapsuleHalfHeight();
    const FCollisionShape Shape = FCollisionShape::MakeCapsule(Radius, HalfHeight);
    FCollisionQueryParams Clearance(SCENE_QUERY_STAT(RanwarBusExit), false, &Character);
    FCollisionQueryParams Ground = Clearance;
    Ground.AddIgnoredActor(this);
    const FCollisionResponseParams Responses(Capsule->GetCollisionResponseToChannels());
    const FVector Curb = GetBoardingPoint();

    for (const double Offset : { 0.0, -70.0, 70.0 })
    {
        const FVector Point = Curb + GetActorForwardVector() * Offset;
        FHitResult Hit;
        if (!GetWorld()->LineTraceSingleByObjectType(Hit, Point + FVector(0.0, 0.0, 85.0),
            Point - FVector(0.0, 0.0, 125.0), FCollisionObjectQueryParams(ECC_WorldStatic), Ground)
            || Hit.ImpactNormal.Z < 0.7)
        {
            continue;
        }
        const FVector Candidate = Hit.ImpactPoint + FVector(0.0, 0.0, HalfHeight + 4.0);
        if (!GetWorld()->OverlapBlockingTestByChannel(Candidate, FQuat::Identity, Capsule->GetCollisionObjectType(),
            Shape, Clearance, Responses))
        {
            Location = Candidate;
            return true;
        }
    }
    return false;
}

bool ARanwarBus::Interact(ARanwarCharacter& Character)
{
    if (IsPassenger(Character))
    {
        FVector ExitLocation;
        bExitBlocked = !FindExitLocation(Character, ExitLocation);
        if (!bExitBlocked)
        {
            RestorePassenger(Character, ExitLocation);
        }
        return true;
    }
    auto* Controller = Cast<APlayerController>(Character.GetController());
    FVector ExitLocation;
    if (!Controller || !CanBoard(Character) || !FindExitLocation(Character, ExitLocation))
    {
        return false;
    }

    Passenger = &Character;
    PassengerController = Controller;
    CurbArrival = Character.GetActorTransform();
    CurbView = Controller->GetControlRotation();
    bPassengerCanBeDamaged = Character.CanBeDamaged();
    bExitBlocked = false;
    Character.GetCharacterMovement()->StopMovementImmediately();
    Character.GetCharacterMovement()->DisableMovement();
    Character.SetCanBeDamaged(false);
    Character.SetActorEnableCollision(false);
    Character.SetActorHiddenInGame(true);
    if (AActor* Visual = Character.GetMetaHumanVisual())
    {
        bPassengerVisualWasHidden = Visual->IsHidden();
        Visual->SetActorHiddenInGame(true);
    }
    Character.SetActorLocationAndRotation(GetActorTransform().TransformPosition(PassengerSeat),
        GetActorRotation(), false, nullptr, ETeleportType::TeleportPhysics);
    Character.ReceiveControllerChangedDelegate.AddUniqueDynamic(this, &ARanwarBus::OnPassengerControllerChanged);
    Controller->SetViewTargetWithBlend(this, 0.22f);
    return true;
}

void ARanwarBus::RestorePassenger(ARanwarCharacter& Character, const FVector& Location)
{
    APlayerController* Controller = PassengerController.Get();
    Passenger.Reset();
    PassengerController.Reset();
    Character.ReceiveControllerChangedDelegate.RemoveDynamic(this, &ARanwarBus::OnPassengerControllerChanged);
    Character.SetActorLocationAndRotation(Location, CurbArrival.Rotator(), false, nullptr, ETeleportType::TeleportPhysics);
    Character.SetActorHiddenInGame(false);
    Character.SetActorEnableCollision(true);
    Character.SetCanBeDamaged(bPassengerCanBeDamaged);
    if (AActor* Visual = Character.GetMetaHumanVisual())
    {
        Visual->SetActorHiddenInGame(bPassengerVisualWasHidden);
    }
    Character.GetCharacterMovement()->SetMovementMode(MOVE_Walking);
    if (Controller && Controller->GetPawn() == &Character)
    {
        Controller->SetControlRotation(CurbView);
        Controller->SetViewTargetWithBlend(&Character, 0.22f);
    }
}

void ARanwarBus::OnPassengerControllerChanged(APawn* Pawn, AController* Previous, AController* Current)
{
    ARanwarCharacter* Character = Passenger.Get();
    if (Character && Character == Pawn && Previous == PassengerController.Get() && Previous != Current)
    {
        FVector Location = CurbArrival.GetLocation();
        FindExitLocation(*Character, Location);
        RestorePassenger(*Character, Location);
    }
}

void ARanwarBus::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    if (EndPlayReason == EEndPlayReason::Destroyed)
    {
        if (ARanwarCharacter* Character = Passenger.Get())
        {
            FVector Location = CurbArrival.GetLocation();
            FindExitLocation(*Character, Location);
            RestorePassenger(*Character, Location);
        }
    }
    Super::EndPlay(EndPlayReason);
}

#undef LOCTEXT_NAMESPACE
