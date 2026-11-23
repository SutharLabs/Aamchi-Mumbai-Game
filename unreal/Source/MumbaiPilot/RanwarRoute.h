#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GameFramework/SaveGame.h"
#include "RanwarRoute.generated.h"

class ARanwarCharacter;
class ARanwarVehicle;

UENUM()
enum class ERanwarJobStage : uint8
{
    Arrival,
    Offer,
    Pickup,
    Dropoff,
    Complete,
};

UCLASS()
class MUMBAIPILOT_API URanwarProgress : public USaveGame
{
    GENERATED_BODY()

public:
    UPROPERTY(SaveGame)
    int32 Version = 1;

    UPROPERTY(SaveGame)
    int32 Revision = 0;

    UPROPERTY(SaveGame)
    ERanwarJobStage Stage = ERanwarJobStage::Arrival;
};

UCLASS()
class MUMBAIPILOT_API ARanwarRoute : public AActor
{
    GENERATED_BODY()

public:
    ARanwarRoute();
    FText GetPrompt(const ARanwarCharacter& Player) const;
    FText GetObjective(const FVector& PlayerLocation) const;
    FText GetNotice() const;
    bool GetWaypoint(FVector& Point) const;
    bool Interact(const ARanwarCharacter& Player);
    void OnVehicleEntry(const ARanwarVehicle& Vehicle);
    int32 GetCash() const;
    int32 GetPoliceAlert() const;
    bool HasSavedProgress() const { return Revision > 0; }

protected:
    void BeginPlay() override;

private:
    bool CanReach(const ARanwarCharacter& Player) const;
    void SetNotice(const FText& Text);
    bool SaveStage(ERanwarJobStage Next);
    void LoadProgress();
    void SpawnVehicles();

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector GuideStop = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector JobBoard = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector ParcelPickup = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector ParcelDropoff = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    TArray<FVector> YardBays;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    TArray<FVector> LoanBays;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    float RoadHeading = 0.0f;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    float YardHeading = 0.0f;

    TWeakObjectPtr<ARanwarVehicle> LoanVehicle;
    ERanwarJobStage Stage = ERanwarJobStage::Arrival;
    int32 Revision = 0;
    FText Notice;
    double NoticeUntil = 0.0;
    double AlertUntil = 0.0;
};
