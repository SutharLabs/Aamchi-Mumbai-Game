#include "RanwarRoute.h"

#include "RanwarAudio.h"

#include "CollisionQueryParams.h"
#include "Components/AudioComponent.h"
#include "Components/SceneComponent.h"
#include "Dom/JsonObject.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "RanwarBus.h"
#include "RanwarGame.h"
#include "RanwarParcelContact.h"
#include "RanwarPlayerController.h"
#include "RanwarProfiles.h"
#include "RanwarVehicle.h"
#include "Serialization/JsonSerializer.h"
#include "TimerManager.h"

#define LOCTEXT_NAMESPACE "RanwarRoute"

namespace
{
    constexpr double InteractionRange = 190.0;
    constexpr double NoticeSeconds = 7.0;
    constexpr int32 ParcelPay = 500;
    constexpr int32 DabbaPay = 150;
    constexpr int32 LedgerPay = 400;
    constexpr int32 MaxDabbaDeliveries = (MAX_int32 - ParcelPay) / DabbaPay;
    constexpr int32 LegacySaveVersion = 1;
    constexpr int32 DabbaSaveVersion = 2;
    constexpr int32 NewGameSaveVersion = 3;
    constexpr int32 LedgerSaveVersion = 4;
    constexpr ERanwarVehicleKind YardKinds[] = {
        ERanwarVehicleKind::Hatchback, ERanwarVehicleKind::Rickshaw,
        ERanwarVehicleKind::Motorcycle, ERanwarVehicleKind::Scooter,
    };

    FString SaveSlot(int32 Revision, int32 Profile)
    {
        return Profile == 1
            ? FString::Printf(TEXT("RanwarProgress%d"), Revision % 2)
            : FString::Printf(TEXT("RanwarProfile%dProgress%d"), Profile, Revision % 2);
    }
}

ARanwarRoute::ARanwarRoute()
{
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("RouteOrigin"));
}

void ARanwarRoute::BeginPlay()
{
    Super::BeginPlay();
    TArray<FString> Profiles;
    ActiveProfile = RanwarProfiles::Load(Profiles);
    LoadProgress();
    SpawnVehicles();
    if (Stage == ERanwarJobStage::Arrival)
    {
        SetNotice(LOCTEXT("Welcome", "Omkar arrives at St Peter's BEST stop. Find Anjali nearby."));
    }
}

void ARanwarRoute::LoadProgress()
{
    for (int32 Index = 0; Index < 2; ++Index)
    {
        const FString Slot = SaveSlot(Index, ActiveProfile);
        if (!UGameplayStatics::DoesSaveGameExist(Slot, 0))
        {
            continue;
        }
        const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(Slot, 0));
        if (!Saved || Saved->Revision <= Revision || Saved->Revision % 2 != Index)
        {
            continue;
        }
        const bool bLegacy = Saved->Version == LegacySaveVersion
            && Saved->Stage > ERanwarJobStage::Arrival && Saved->Stage <= ERanwarJobStage::Complete;
        const bool bValidDabbaState = Saved->Stage == ERanwarJobStage::Complete
            && Saved->DabbaStage <= ERanwarDabbaStage::Dropoff
            && Saved->DabbaDeliveries >= 0 && Saved->DabbaDeliveries <= MaxDabbaDeliveries
            && (Saved->DabbaDeliveries < MaxDabbaDeliveries || Saved->DabbaStage == ERanwarDabbaStage::Available);
        const bool bValidDabba = Saved->Version == DabbaSaveVersion && bValidDabbaState;
        const bool bValidLedger = Saved->Version == LedgerSaveVersion && bValidDabbaState
            && (Saved->LedgerStage == ERanwarLedgerStage::Complete
                || (Saved->LedgerStage == ERanwarLedgerStage::Handoff && Saved->DabbaStage == ERanwarDabbaStage::Available));
        const bool bReset = Saved->Version == NewGameSaveVersion && Saved->Stage == ERanwarJobStage::Arrival
            && Saved->DabbaStage == ERanwarDabbaStage::Available && Saved->DabbaDeliveries == 0;
        if (!bLegacy && !bValidDabba && !bValidLedger && !bReset)
        {
            continue;
        }
        Revision = Saved->Revision;
        Stage = Saved->Stage;
        DabbaStage = bValidDabba || bValidLedger ? Saved->DabbaStage : ERanwarDabbaStage::Available;
        DabbaDeliveries = bValidDabba || bValidLedger ? Saved->DabbaDeliveries : 0;
        LedgerStage = bValidLedger ? Saved->LedgerStage : ERanwarLedgerStage::Collect;
    }
}

void ARanwarRoute::SelectProfile(int32 NewActiveProfile)
{
    if (NewActiveProfile == ActiveProfile || NewActiveProfile < 1 || NewActiveProfile > RanwarProfiles::MaxProfiles)
    {
        return;
    }
    ActiveProfile = NewActiveProfile;
    Revision = 0;
    Stage = ERanwarJobStage::Arrival;
    DabbaStage = ERanwarDabbaStage::Available;
    DabbaDeliveries = 0;
    LedgerStage = ERanwarLedgerStage::Collect;
    AlertUntil = 0.0;
    Notice = FText::GetEmpty();
    ClearDialogue();
    LoadProgress();
}

bool ARanwarRoute::ResetProgress()
{
    const bool bSaved = !HasSavedProgress()
        || SaveProgress(ERanwarJobStage::Arrival, ERanwarDabbaStage::Available, 0, ERanwarLedgerStage::Collect);
    if (bSaved)
    {
        ClearDialogue();
    }
    return bSaved;
}

bool ARanwarRoute::CanAbandonJob() const
{
    return Stage == ERanwarJobStage::Pickup || Stage == ERanwarJobStage::Dropoff
        || (Stage == ERanwarJobStage::Complete
            && (DabbaStage != ERanwarDabbaStage::Available || LedgerStage == ERanwarLedgerStage::Handoff));
}

bool ARanwarRoute::AbandonJob()
{
    if (!CanAbandonJob())
    {
        return false;
    }
    const ERanwarJobStage NextStage = Stage == ERanwarJobStage::Complete ? Stage : ERanwarJobStage::Offer;
    const bool bAbandoningLedger = LedgerStage == ERanwarLedgerStage::Handoff;
    const ERanwarLedgerStage NextLedgerStage = bAbandoningLedger ? ERanwarLedgerStage::Collect : LedgerStage;
    const bool bSaved = SaveProgress(NextStage, ERanwarDabbaStage::Available, DabbaDeliveries, NextLedgerStage);
    if (bSaved)
    {
        ClearDialogue();
        SetNotice(bAbandoningLedger ? LOCTEXT("AbandonedLedger", "Ledger job abandoned. Collect a fresh copy from Asha.")
            : LOCTEXT("AbandonedJob", "Job abandoned. You can accept it again later."));
    }
    else
    {
        SetNotice(LOCTEXT("AbandonSaveFailed", "The job could not be abandoned. Try again."));
    }
    return bSaved;
}

bool ARanwarRoute::SaveProgress(ERanwarJobStage NextStage, ERanwarDabbaStage NextDabbaStage, int32 NextDabbaDeliveries)
{
    return SaveProgress(NextStage, NextDabbaStage, NextDabbaDeliveries, LedgerStage);
}

bool ARanwarRoute::SaveProgress(ERanwarJobStage NextStage, ERanwarDabbaStage NextDabbaStage, int32 NextDabbaDeliveries,
    ERanwarLedgerStage NextLedgerStage)
{
    if (Revision == MAX_int32)
    {
        return false;
    }
    URanwarProgress* Snapshot = NewObject<URanwarProgress>();
    if (NextStage == ERanwarJobStage::Arrival)
    {
        Snapshot->Version = NewGameSaveVersion;
    }
    else if (NextLedgerStage != ERanwarLedgerStage::Collect)
    {
        Snapshot->Version = LedgerSaveVersion;
    }
    else
    {
        Snapshot->Version = (NextDabbaStage == ERanwarDabbaStage::Available && NextDabbaDeliveries == 0)
            ? LegacySaveVersion : DabbaSaveVersion;
    }
    Snapshot->Revision = Revision + 1;
    Snapshot->Stage = NextStage;
    Snapshot->DabbaStage = NextDabbaStage;
    Snapshot->DabbaDeliveries = NextDabbaDeliveries;
    Snapshot->LedgerStage = NextLedgerStage;
    // Keep the prior checkpoint intact if the new save is interrupted.
    if (!UGameplayStatics::SaveGameToSlot(Snapshot, SaveSlot(Snapshot->Revision, ActiveProfile), 0))
    {
        return false;
    }
    Revision = Snapshot->Revision;
    Stage = NextStage;
    DabbaStage = NextDabbaStage;
    DabbaDeliveries = NextDabbaDeliveries;
    LedgerStage = NextLedgerStage;
    return true;
}

void ARanwarRoute::SpawnVehicles()
{
    auto SpawnParked = [this](ERanwarVehicleKind Kind, const FVector& Spot, double Yaw) -> ARanwarVehicle*
    {
        const FRotator Heading(0.0, Yaw, 0.0);
        FActorSpawnParameters Parameters;
        Parameters.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
        ARanwarVehicle* Vehicle = GetWorld()->SpawnActor<ARanwarVehicle>(Spot + FVector(0.0, 0.0, 300.0), Heading, Parameters);
        if (Vehicle)
        {
            Vehicle->SetVehicleKind(Kind);
            if (Vehicle->PlaceOnGround(Spot, Heading))
            {
                return Vehicle;
            }
            Vehicle->Destroy();
        }
        return nullptr;
    };

    TArray<FVector> Bays = YardBays;
    for (int32 KindIndex = 0; KindIndex < UE_ARRAY_COUNT(YardKinds) && !Bays.IsEmpty(); ++KindIndex)
    {
        while (!Bays.IsEmpty())
        {
            const int32 Index = FMath::RandHelper(Bays.Num());
            const FVector Spot = Bays[Index];
            Bays.RemoveAtSwap(Index);
            const double Heading = YardHeading + (FMath::RandBool() ? 180.0 : 0.0);
            if (SpawnParked(YardKinds[KindIndex], Spot, Heading))
            {
                break;
            }
        }
    }
    Bays = LoanBays;
    while (!Bays.IsEmpty())
    {
        const int32 Index = FMath::RandHelper(Bays.Num());
        const FVector Spot = Bays[Index];
        Bays.RemoveAtSwap(Index);
        if (ARanwarVehicle* Bike = SpawnParked(ERanwarVehicleKind::Motorcycle, Spot, RoadHeading))
        {
            LoanVehicle = Bike;
            break;
        }
    }
}

bool ARanwarRoute::GetWaypoint(FVector& Point) const
{
    switch (Stage)
    {
    case ERanwarJobStage::Arrival: Point = GuideStop; break;
    case ERanwarJobStage::Offer: Point = JobBoard; break;
    case ERanwarJobStage::Pickup: Point = ParcelPickup; break;
    case ERanwarJobStage::Dropoff: Point = ParcelDropoff; break;
    case ERanwarJobStage::Complete: return GetDabbaWaypoint(Point) || GetLedgerWaypoint(Point);
    }
    return true;
}

bool ARanwarRoute::GetDabbaWaypoint(FVector& Point) const
{
    if (DabbaStage == ERanwarDabbaStage::Available)
    {
        return false;
    }
    Point = DabbaStage == ERanwarDabbaStage::Pickup ? ParcelPickup
        : (IsWarodaDabbaDropoff() ? ParcelDropoff : JobBoard);
    return true;
}

bool ARanwarRoute::GetLedgerWaypoint(FVector& Point) const
{
    if (Stage != ERanwarJobStage::Complete || LedgerStage == ERanwarLedgerStage::Complete
        || LedgerPickup.IsNearlyZero() || LedgerHandoff.IsNearlyZero())
    {
        return false;
    }
    Point = LedgerStage == ERanwarLedgerStage::Collect ? LedgerPickup : LedgerHandoff;
    return true;
}

bool ARanwarRoute::CanReach(const ARanwarCharacter& Player, const FVector& Point) const
{
    if (!Player.IsPlayerControlled() || FVector::DistSquared2D(Player.GetActorLocation(), Point) > FMath::Square(InteractionRange)
        || FMath::Abs(Player.GetActorLocation().Z - Point.Z) > 190.0)
    {
        return false;
    }
    FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarJobReach), true, &Player);
    return !GetWorld()->LineTraceTestByChannel(Player.GetPawnViewLocation(), Point + FVector(0.0, 0.0, 115.0), ECC_Visibility, Query);
}

ARanwarParcelContact* ARanwarRoute::GetActiveParcelContact() const
{
    if (Stage == ERanwarJobStage::Pickup)
    {
        return ParcelPickupContact.Get();
    }
    return Stage == ERanwarJobStage::Dropoff ? ParcelDropoffContact.Get() : nullptr;
}

ARanwarRoute::ESideJob ARanwarRoute::GetSideJobAt(const ARanwarCharacter& Player) const
{
    FVector Point;
    if (GetDabbaWaypoint(Point))
    {
        return CanReach(Player, Point) ? ESideJob::Dabba : ESideJob::None;
    }
    if (GetLedgerWaypoint(Point) && CanReach(Player, Point))
    {
        return ESideJob::Ledger;
    }
    if (LedgerStage != ERanwarLedgerStage::Handoff && DabbaDeliveries < MaxDabbaDeliveries && CanReach(Player, GuideStop))
    {
        return ESideJob::Dabba;
    }
    return ESideJob::None;
}

FText ARanwarRoute::GetPrompt(const ARanwarCharacter& Player) const
{
    if (IsValid(StopBus) && StopBus->IsPassenger(Player))
    {
        return StopBus->GetPrompt(Player);
    }
    const FText JobPrompt = GetJobPrompt(Player);
    return JobPrompt.IsEmpty() && IsValid(StopBus) ? StopBus->GetPrompt(Player) : JobPrompt;
}

FText ARanwarRoute::GetJobPrompt(const ARanwarCharacter& Player) const
{
    if (Stage == ERanwarJobStage::Complete)
    {
        switch (GetSideJobAt(Player))
        {
        case ESideJob::Ledger:
            return LedgerStage == ERanwarLedgerStage::Collect
                ? LOCTEXT("CollectLedger", "Take the ledger copy from Asha (E / B)")
                : LOCTEXT("HandOverLedger", "Hand the ledger copy to the grocer (E / B)");
        case ESideJob::Dabba:
            switch (DabbaStage)
            {
            case ERanwarDabbaStage::Available:
                return FText::Format(LOCTEXT("AcceptDabba", "Take a dabba delivery for INR {0} (E / B)"),
                    FText::AsNumber(DabbaPay));
            case ERanwarDabbaStage::Pickup: return LOCTEXT("CollectDabba", "Pick up the lunchbox (E / B)");
            case ERanwarDabbaStage::Dropoff: return LOCTEXT("DeliverDabba", "Hand over the lunchbox (E / B)");
            }
            break;
        case ESideJob::None: break;
        }
        return FText::GetEmpty();
    }
    FVector Point;
    if (!GetWaypoint(Point))
    {
        return FText::GetEmpty();
    }
    const ARanwarParcelContact* Contact = GetActiveParcelContact();
    if (!CanReach(Player, IsValid(Contact) ? Contact->GetActorLocation() : Point))
    {
        return FText::GetEmpty();
    }
    switch (Stage)
    {
    case ERanwarJobStage::Arrival: return LOCTEXT("Talk", "Talk to Anjali (E / B)");
    case ERanwarJobStage::Offer: return LOCTEXT("Accept", "Start Ranwar Parcel Run (E / B)");
    case ERanwarJobStage::Pickup: return LOCTEXT("CollectFromRavi", "Collect the parcel from Ravi (E / B)");
    case ERanwarJobStage::Dropoff: return LOCTEXT("DeliverToKavita", "Give the parcel to Kavita (E / B)");
    case ERanwarJobStage::Complete: break;
    }
    return FText::GetEmpty();
}

FText ARanwarRoute::GetObjective(const FVector& PlayerLocation) const
{
    FVector Point;
    if (!GetWaypoint(Point))
    {
        return DabbaDeliveries < MaxDabbaDeliveries
            ? LOCTEXT("FreeRoamDabba", "Free roam  |  Ask Anjali for work")
            : LOCTEXT("FreeRoam", "Free roam in Ranwar");
    }
    FText Instruction;
    switch (Stage)
    {
    case ERanwarJobStage::Arrival: Instruction = LOCTEXT("FindGuide", "Find Anjali at the BEST stop"); break;
    case ERanwarJobStage::Offer: Instruction = LOCTEXT("FindJobBoard", "Visit the Hill Road job board"); break;
    case ERanwarJobStage::Pickup: Instruction = LOCTEXT("FindRavi", "Pick up parcel from Ravi · Hill Road"); break;
    case ERanwarJobStage::Dropoff: Instruction = LOCTEXT("FindKavita", "Hand off parcel to Kavita · Waroda Road"); break;
    case ERanwarJobStage::Complete:
        if (DabbaStage == ERanwarDabbaStage::Available)
        {
            Instruction = LedgerStage == ERanwarLedgerStage::Collect
                ? LOCTEXT("MeetAsha", "Meet Asha at Hill Road Tea Room")
                : LOCTEXT("CarryLedger", "Carry the ledger to Chapel Corner Grocer");
        }
        else
        {
            Instruction = DabbaStage == ERanwarDabbaStage::Pickup
                ? LOCTEXT("FindDabba", "Pick up the Hill Road lunchbox")
                : (IsWarodaDabbaDropoff() ? LOCTEXT("TakeDabbaWaroda", "Take the lunchbox to Waroda Road")
                    : LOCTEXT("TakeDabbaHill", "Take the lunchbox to the job board"));
        }
        break;
    }
    return FText::Format(LOCTEXT("Distance", "{0}  |  {1} m"), Instruction,
        FText::AsNumber(FMath::RoundToInt(FVector::Dist2D(PlayerLocation, Point) / 100.0)));
}

bool ARanwarRoute::Interact(ARanwarCharacter& Player)
{
    if (IsValid(StopBus) && StopBus->IsPassenger(Player))
    {
        return StopBus->Interact(Player);
    }
    return InteractWithJob(Player) || (IsValid(StopBus) && StopBus->Interact(Player));
}

bool ARanwarRoute::InteractWithJob(const ARanwarCharacter& Player)
{
    if (Stage == ERanwarJobStage::Complete)
    {
        switch (GetSideJobAt(Player))
        {
        case ESideJob::Dabba: AdvanceDabbaDelivery(); return true;
        case ESideJob::Ledger: AdvanceLedger(); return true;
        case ESideJob::None: return false;
        }
    }
    FVector Point;
    if (!GetWaypoint(Point))
    {
        return false;
    }
    ARanwarParcelContact* Contact = GetActiveParcelContact();
    if (!CanReach(Player, IsValid(Contact) ? Contact->GetActorLocation() : Point))
    {
        return false;
    }
    ERanwarJobStage Next = Stage;
    FText Response;
    switch (Stage)
    {
    case ERanwarJobStage::Arrival:
        Next = ERanwarJobStage::Offer;
        break;
    case ERanwarJobStage::Offer:
        Next = ERanwarJobStage::Pickup;
        Response = LOCTEXT("JobAcceptedRavi", "Find Ravi at the Hill Road end of Nagrana Lane.");
        break;
    case ERanwarJobStage::Pickup:
        Next = ERanwarJobStage::Dropoff;
        Response = LOCTEXT("ParcelReceived", "Parcel collected");
        break;
    case ERanwarJobStage::Dropoff:
        Next = ERanwarJobStage::Complete;
        Response = FText::Format(LOCTEXT("ParcelDelivered", "Parcel delivered. +INR {0}"),
            FText::AsNumber(ParcelPay));
        break;
    case ERanwarJobStage::Complete: return false;
    }
    const bool bSaved = SaveProgress(Next, DabbaStage, DabbaDeliveries);
    if (bSaved)
    {
        if (IsValid(Contact))
        {
            Contact->RespondTo(Player);
        }
        if (Next == ERanwarJobStage::Offer)
        {
            PresentDialogue(TEXT("anjali-bike"));
        }
        else if (Next == ERanwarJobStage::Dropoff)
        {
            RanwarAudio::PlayParcelPickup(*this, (IsValid(Contact) ? Contact->GetActorLocation() : ParcelPickup)
                + FVector(0.0, 0.0, 80.0));
            PresentDialogue(TEXT("ranwar-parcel-pickup"));
        }
        else if (Next == ERanwarJobStage::Complete)
        {
            PresentDialogue(TEXT("ranwar-parcel-handoff"));
            const float Delay = static_cast<float>(FMath::Max(0.25, DialogueUntil - GetWorld()->GetTimeSeconds() + 0.2));
            GetWorldTimerManager().SetTimer(FollowUpDialogueTimer,
                FTimerDelegate::CreateUObject(this, &ARanwarRoute::PresentDialogue, FName(TEXT("mira-ledger"))), Delay, false);
        }
    }
    SetNotice(bSaved ? Response : LOCTEXT("SaveFailed", "Progress could not be saved. Try again."));
    return true;
}

void ARanwarRoute::AdvanceDabbaDelivery()
{
    ERanwarDabbaStage Next = DabbaStage;
    int32 Completed = DabbaDeliveries;
    FText Response;
    FName DialogueId;
    switch (DabbaStage)
    {
    case ERanwarDabbaStage::Available:
        Next = ERanwarDabbaStage::Pickup;
        Response = IsWarodaDabbaDropoff()
            ? LOCTEXT("DabbaOrderWaroda", "Pick up the lunchbox on Hill Road for Nandini.")
            : LOCTEXT("DabbaOrderHill", "Pick up the lunchbox on Hill Road for Prakash.");
        DialogueId = IsWarodaDabbaDropoff() ? TEXT("anjali-dabba-waroda") : TEXT("anjali-dabba-hill");
        break;
    case ERanwarDabbaStage::Pickup:
        Next = ERanwarDabbaStage::Dropoff;
        Response = IsWarodaDabbaDropoff()
            ? LOCTEXT("DabbaCollectedWaroda", "Lunchbox collected. Follow Nagrana Lane to Waroda Road.")
            : LOCTEXT("DabbaCollectedHill", "Lunchbox collected. Head to the Hill Road job board.");
        break;
    case ERanwarDabbaStage::Dropoff:
        Next = ERanwarDabbaStage::Available;
        ++Completed;
        DialogueId = IsWarodaDabbaDropoff() ? TEXT("nandini-dabba") : TEXT("prakash-dabba");
        Response = FText::Format(LOCTEXT("DabbaPaid", "Lunchbox delivered. +INR {0}"), FText::AsNumber(DabbaPay));
        break;
    }
    const bool bSaved = SaveProgress(Stage, Next, Completed);
    if (bSaved && !DialogueId.IsNone())
    {
        PresentDialogue(DialogueId);
    }
    SetNotice(bSaved ? Response : LOCTEXT("DabbaSaveFailed", "Delivery progress could not be saved. Try again."));
}

void ARanwarRoute::AdvanceLedger()
{
    const bool bPickingUp = LedgerStage == ERanwarLedgerStage::Collect;
    const ERanwarLedgerStage Next = bPickingUp ? ERanwarLedgerStage::Handoff : ERanwarLedgerStage::Complete;
    if (!SaveProgress(Stage, DabbaStage, DabbaDeliveries, Next))
    {
        SetNotice(LOCTEXT("LedgerSaveFailed", "The ledger checkpoint could not be saved. Try again."));
        return;
    }
    UE_LOG(LogTemp, Verbose, TEXT("Saved Ranwar mission hill_road_ledger checkpoint: %s"),
        bPickingUp ? TEXT("handoff") : TEXT("complete"));
    if (bPickingUp)
    {
        PresentDialogue(TEXT("asha-ledger-pickup"));
        SetNotice(FText::GetEmpty());
    }
    else
    {
        PresentDialogue(TEXT("grocer-ledger-handoff"));
        SetNotice(FText::Format(LOCTEXT("LedgerComplete", "The Hill Road Ledger complete  |  +INR {0}"),
            FText::AsNumber(LedgerPay)));
    }
}

bool ARanwarRoute::IsWarodaDabbaDropoff() const
{
    return DabbaDeliveries % 2 == 1;
}

void ARanwarRoute::OnVehicleEntry(const ARanwarVehicle& Vehicle)
{
    if (LoanVehicle.Get() == &Vehicle && Stage != ERanwarJobStage::Arrival)
    {
        return;
    }
    const FVector CarriedPoint = Vehicle.GetActorLocation();
    if (FVector::DistSquared2D(CarriedPoint, GuideStop) < FMath::Square(2400.0))
    {
        FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarWitness), true, &Vehicle);
        if (!GetWorld()->LineTraceTestByChannel(GuideStop + FVector(0.0, 0.0, 160.0), CarriedPoint + FVector(0.0, 0.0, 80.0),
            ECC_Visibility, Query))
        {
            AlertUntil = GetWorld()->GetTimeSeconds() + 35.0;
            SetNotice(LOCTEXT("SeenTakingVehicle", "Vehicle taken in view of a witness. Police alert raised."));
        }
    }
}

void ARanwarRoute::SetNotice(const FText& Text)
{
    Notice = Text;
    NoticeUntil = GetWorld()->GetTimeSeconds() + NoticeSeconds;
}

void ARanwarRoute::ClearDialogue()
{
    GetWorldTimerManager().ClearTimer(FollowUpDialogueTimer);
    if (UAudioComponent* Previous = DialogueAudio.Get())
    {
        Previous->Stop();
    }
    DialogueAudio.Reset();
    ActiveDialogue = nullptr;
    DialogueUntil = 0.0;
}

bool ARanwarRoute::LoadDialogue()
{
    bLoadedDialogue = true;
    const FString Path = FPaths::Combine(FPaths::ProjectContentDir(), TEXT("Audio/Ranwar/Dialogue/lines.json"));
    FString Json;
    TArray<TSharedPtr<FJsonValue>> Rows;
    if (!FFileHelper::LoadFileToString(Json, *Path) || !FJsonSerializer::Deserialize(TJsonReaderFactory<>::Create(Json), Rows))
    {
        UE_LOG(LogTemp, Warning, TEXT("Cannot open cooked Ranwar dialogue transcript"));
        return false;
    }
    for (const TSharedPtr<FJsonValue>& Row : Rows)
    {
        const TSharedPtr<FJsonObject>* Object = nullptr;
        FString Id;
        FString Speaker;
        FString Text;
        double Duration = 0.0;
        if (Row.IsValid() && Row->TryGetObject(Object) && Object && Object->IsValid()
            && (*Object)->TryGetStringField(TEXT("id"), Id) && !Id.IsEmpty()
            && (*Object)->TryGetStringField(TEXT("speaker"), Speaker) && !Speaker.IsEmpty()
            && (*Object)->TryGetStringField(TEXT("text"), Text) && !Text.IsEmpty()
            && (*Object)->TryGetNumberField(TEXT("duration"), Duration) && Duration >= 0.5 && Duration <= 30.0)
        {
            DialogueLines.Add(FName(*Id), {FText::FromString(Speaker), FText::FromString(Text), Duration});
        }
    }
    return !DialogueLines.IsEmpty();
}

void ARanwarRoute::PresentDialogue(FName Id)
{
    if (!bLoadedDialogue && !LoadDialogue())
    {
        return;
    }
    const FDialogueLine* Line = DialogueLines.Find(Id);
    if (!Line)
    {
        return;
    }
    ClearDialogue();
    ActiveDialogue = Line;
    DialogueUntil = GetWorld()->GetTimeSeconds() + FMath::Max(Line->Duration + 0.35, 2.0);
    const ARanwarPlayerController* Player = Cast<ARanwarPlayerController>(GetWorld()->GetFirstPlayerController());
    DialogueAudio = RanwarAudio::PlayDialogue(*this, Id, Player ? Player->GetDialogueVolume() : 1.0f);
}

FText ARanwarRoute::GetDialogueSpeaker() const
{
    return ActiveDialogue && GetWorld()->GetTimeSeconds() < DialogueUntil ? ActiveDialogue->Speaker : FText::GetEmpty();
}

FText ARanwarRoute::GetDialogueText() const
{
    return ActiveDialogue && GetWorld()->GetTimeSeconds() < DialogueUntil ? ActiveDialogue->Text : FText::GetEmpty();
}

void ARanwarRoute::SetDialogueVolume(float Volume)
{
    if (UAudioComponent* Playing = DialogueAudio.Get())
    {
        Playing->SetVolumeMultiplier(FMath::Clamp(Volume, 0.0f, 1.0f));
    }
}

FText ARanwarRoute::GetNotice() const
{
    return GetWorld()->GetTimeSeconds() < NoticeUntil ? Notice : FText::GetEmpty();
}

int32 ARanwarRoute::GetCash() const
{
    if (Stage != ERanwarJobStage::Complete)
    {
        return 0;
    }
    const int64 Cash = ParcelPay + static_cast<int64>(DabbaDeliveries) * DabbaPay
        + (LedgerStage == ERanwarLedgerStage::Complete ? LedgerPay : 0);
    return static_cast<int32>(FMath::Min<int64>(Cash, MAX_int32));
}

int32 ARanwarRoute::GetPoliceAlert() const
{
    return GetWorld()->GetTimeSeconds() < AlertUntil ? 1 : 0;
}

#undef LOCTEXT_NAMESPACE
