#pragma once

#include "CoreMinimal.h"
#include "Engine/TimerHandle.h"
#include "GameFramework/Actor.h"
#include "GameFramework/SaveGame.h"
#include "RanwarRoute.generated.h"

class ARanwarCharacter;
class ARanwarParcelContact;
class ARanwarVehicle;
class UAudioComponent;

UENUM()
enum class ERanwarJobStage : uint8
{
    Arrival,
    Offer,
    Pickup,
    Dropoff,
    Complete,
};

UENUM()
enum class ERanwarDabbaStage : uint8
{
    Available,
    Pickup,
    Dropoff,
};

UENUM()
enum class ERanwarLedgerStage : uint8
{
    Collect,
    Handoff,
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

    UPROPERTY(SaveGame)
    ERanwarDabbaStage DabbaStage = ERanwarDabbaStage::Available;

    UPROPERTY(SaveGame)
    int32 DabbaDeliveries = 0;

    UPROPERTY(SaveGame)
    ERanwarLedgerStage LedgerStage = ERanwarLedgerStage::Collect;
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
    FText GetDialogueSpeaker() const;
    FText GetDialogueText() const;
    void SetDialogueVolume(float Volume);
    bool GetWaypoint(FVector& Point) const;
    bool UsesParcelGroundHint() const { return Stage == ERanwarJobStage::Pickup || Stage == ERanwarJobStage::Dropoff; }
    bool Interact(const ARanwarCharacter& Player);
    void OnVehicleEntry(const ARanwarVehicle& Vehicle);
    int32 GetCash() const;
    int32 GetPoliceAlert() const;
    bool HasSavedProgress() const { return Stage != ERanwarJobStage::Arrival; }
    void SelectProfile(int32 NewActiveProfile);
    bool ResetProgress();
    bool CanAbandonJob() const;
    bool AbandonJob();

protected:
    void BeginPlay() override;

private:
    enum class ESideJob : uint8 { None, Dabba, Ledger };

    bool CanReach(const ARanwarCharacter& Player, const FVector& Point) const;
    ARanwarParcelContact* GetActiveParcelContact() const;
    ESideJob GetSideJobAt(const ARanwarCharacter& Player) const;
    bool GetDabbaWaypoint(FVector& Point) const;
    bool GetLedgerWaypoint(FVector& Point) const;
    void SetNotice(const FText& Text);
    void ClearDialogue();
    void PresentDialogue(FName Id);
    bool SaveProgress(ERanwarJobStage NextStage, ERanwarDabbaStage NextDabbaStage, int32 NextDabbaDeliveries);
    bool SaveProgress(ERanwarJobStage NextStage, ERanwarDabbaStage NextDabbaStage, int32 NextDabbaDeliveries,
        ERanwarLedgerStage NextLedgerStage);
    void LoadProgress();
    void SpawnVehicles();
    void AdvanceDabbaDelivery();
    void AdvanceLedger();
    bool IsWarodaDabbaDropoff() const;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector GuideStop = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector JobBoard = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector ParcelPickup = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector ParcelDropoff = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    TObjectPtr<ARanwarParcelContact> ParcelPickupContact;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    TObjectPtr<ARanwarParcelContact> ParcelDropoffContact;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector LedgerPickup = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FVector LedgerHandoff = FVector::ZeroVector;

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
    ERanwarDabbaStage DabbaStage = ERanwarDabbaStage::Available;
    ERanwarLedgerStage LedgerStage = ERanwarLedgerStage::Collect;
    int32 DabbaDeliveries = 0;
    int32 Revision = 0;
    int32 ActiveProfile = 1;
    struct FDialogueLine
    {
        FText Speaker;
        FText Text;
        double Duration = 0.0;
    };
    bool LoadDialogue();
    TMap<FName, FDialogueLine> DialogueLines;
    const FDialogueLine* ActiveDialogue = nullptr;
    TWeakObjectPtr<UAudioComponent> DialogueAudio;
    FTimerHandle FollowUpDialogueTimer;
    double DialogueUntil = 0.0;
    bool bLoadedDialogue = false;
    FText Notice;
    double NoticeUntil = 0.0;
    double AlertUntil = 0.0;
};
