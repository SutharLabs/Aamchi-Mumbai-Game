#pragma once

#include "CoreMinimal.h"
#include "Engine/StaticMeshActor.h"
#include "RanwarBus.generated.h"

class APlayerController;
class ARanwarCharacter;
class UCameraComponent;

UCLASS()
class MUMBAIPILOT_API ARanwarBus : public AStaticMeshActor
{
    GENERATED_BODY()

public:
    ARanwarBus();

    FVector GetBoardingPoint() const;
    bool IsPassenger(const ARanwarCharacter& Character) const;
    FText GetPrompt(const ARanwarCharacter& Character) const;
    bool Interact(ARanwarCharacter& Character);

protected:
    void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

private:
    bool CanBoard(const ARanwarCharacter& Character) const;
    bool FindExitLocation(const ARanwarCharacter& Character, FVector& Location) const;
    void RestorePassenger(ARanwarCharacter& Character, const FVector& Location);

    UFUNCTION()
    void OnPassengerControllerChanged(APawn* Pawn, AController* Previous, AController* Current);

    UPROPERTY(VisibleAnywhere, Category = "Ranwar")
    TObjectPtr<UCameraComponent> PassengerCamera;

    TWeakObjectPtr<ARanwarCharacter> Passenger;
    TWeakObjectPtr<APlayerController> PassengerController;
    FTransform CurbArrival;
    FRotator CurbView;
    bool bPassengerCanBeDamaged = true;
    bool bPassengerVisualWasHidden = false;
    bool bExitBlocked = false;
};
