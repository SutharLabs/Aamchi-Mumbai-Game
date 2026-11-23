#include "RanwarRoute.h"

#include "CollisionQueryParams.h"
#include "Components/SceneComponent.h"
#include "Engine/World.h"
#include "Kismet/GameplayStatics.h"
#include "RanwarGame.h"
#include "RanwarVehicle.h"

#define LOCTEXT_NAMESPACE "RanwarRoute"

namespace
{
    constexpr double InteractionRange = 190.0;
    constexpr double NoticeSeconds = 7.0;
    constexpr int32 ParcelPay = 500;
    constexpr int32 SaveVersion = 1;
    constexpr ERanwarVehicleKind YardKinds[] = {
        ERanwarVehicleKind::Hatchback, ERanwarVehicleKind::Rickshaw,
        ERanwarVehicleKind::Motorcycle, ERanwarVehicleKind::Scooter,
    };

    FString SaveSlot(int32 Revision)
    {
        return FString::Printf(TEXT("RanwarProgress%d"), Revision % 2);
    }
}

ARanwarRoute::ARanwarRoute()
{
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("RouteOrigin"));
}

void ARanwarRoute::BeginPlay()
{
    Super::BeginPlay();
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
        const FString Slot = SaveSlot(Index);
        if (!UGameplayStatics::DoesSaveGameExist(Slot, 0))
        {
            continue;
        }
        const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(Slot, 0));
        if (Saved && Saved->Version == SaveVersion && Saved->Revision > Revision
            && Saved->Revision % 2 == Index && Saved->Stage > ERanwarJobStage::Arrival
            && Saved->Stage <= ERanwarJobStage::Complete)
        {
            Revision = Saved->Revision;
            Stage = Saved->Stage;
        }
    }
}

bool ARanwarRoute::SaveStage(ERanwarJobStage Next)
{
    if (Revision == MAX_int32)
    {
        return false;
    }
    URanwarProgress* Snapshot = NewObject<URanwarProgress>();
    Snapshot->Version = SaveVersion;
    Snapshot->Revision = Revision + 1;
    Snapshot->Stage = Next;
    // Keep the prior checkpoint intact if the new save is interrupted.
    if (!UGameplayStatics::SaveGameToSlot(Snapshot, SaveSlot(Snapshot->Revision), 0))
    {
        return false;
    }
    Revision = Snapshot->Revision;
    Stage = Next;
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
    case ERanwarJobStage::Complete: return false;
    }
    return true;
}

bool ARanwarRoute::CanReach(const ARanwarCharacter& Player) const
{
    FVector Point;
    if (!GetWaypoint(Point) || FVector::DistSquared2D(Player.GetActorLocation(), Point) > FMath::Square(InteractionRange)
        || FMath::Abs(Player.GetActorLocation().Z - Point.Z) > 190.0)
    {
        return false;
    }
    FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarJobReach), true, &Player);
    return !GetWorld()->LineTraceTestByChannel(Player.GetPawnViewLocation(), Point + FVector(0.0, 0.0, 115.0), ECC_Visibility, Query);
}

FText ARanwarRoute::GetPrompt(const ARanwarCharacter& Player) const
{
    if (!CanReach(Player))
    {
        return FText::GetEmpty();
    }
    switch (Stage)
    {
    case ERanwarJobStage::Arrival: return LOCTEXT("Talk", "Talk to Anjali (E / B)");
    case ERanwarJobStage::Offer: return LOCTEXT("Accept", "Start Ranwar Parcel Run (E / B)");
    case ERanwarJobStage::Pickup: return LOCTEXT("Collect", "Pick up parcel (E / B)");
    case ERanwarJobStage::Dropoff: return LOCTEXT("Leave", "Deliver parcel (E / B)");
    case ERanwarJobStage::Complete: return FText::GetEmpty();
    }
    return FText::GetEmpty();
}

FText ARanwarRoute::GetObjective(const FVector& PlayerLocation) const
{
    FVector Point;
    if (!GetWaypoint(Point))
    {
        return LOCTEXT("FreeRoam", "Free roam in Ranwar");
    }
    FText Instruction;
    switch (Stage)
    {
    case ERanwarJobStage::Arrival: Instruction = LOCTEXT("FindGuide", "Find Anjali at the BEST stop"); break;
    case ERanwarJobStage::Offer: Instruction = LOCTEXT("FindJobBoard", "Visit the Hill Road job board"); break;
    case ERanwarJobStage::Pickup: Instruction = LOCTEXT("FindParcel", "Collect the parcel near Hill Road"); break;
    case ERanwarJobStage::Dropoff: Instruction = LOCTEXT("FindAddress", "Deliver the parcel near Waroda Road"); break;
    case ERanwarJobStage::Complete: break;
    }
    return FText::Format(LOCTEXT("Distance", "{0}  |  {1} m"), Instruction,
        FText::AsNumber(FMath::RoundToInt(FVector::Dist2D(PlayerLocation, Point) / 100.0)));
}

bool ARanwarRoute::Interact(const ARanwarCharacter& Player)
{
    if (!CanReach(Player))
    {
        return false;
    }
    ERanwarJobStage Next = Stage;
    FText Response;
    switch (Stage)
    {
    case ERanwarJobStage::Arrival:
        Next = ERanwarJobStage::Offer;
        Response = LOCTEXT("GuideLine", "Anjali: Take my bike if you like. The Hill Road job board has paid work.");
        break;
    case ERanwarJobStage::Offer:
        Next = ERanwarJobStage::Pickup;
        Response = LOCTEXT("JobAccepted", "Pick up the parcel at the Hill Road end of Nagrana Lane.");
        break;
    case ERanwarJobStage::Pickup:
        Next = ERanwarJobStage::Dropoff;
        Response = LOCTEXT("ParcelCollected", "Parcel collected. Follow the lane to Waroda Road.");
        break;
    case ERanwarJobStage::Dropoff:
        Next = ERanwarJobStage::Complete;
        Response = FText::Format(LOCTEXT("ParcelDelivered", "Parcel delivered. +INR {0}. Mira has a new lead."),
            FText::AsNumber(ParcelPay));
        break;
    case ERanwarJobStage::Complete: return false;
    }
    SetNotice(SaveStage(Next) ? Response : LOCTEXT("SaveFailed", "Progress could not be saved. Try again."));
    return true;
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

FText ARanwarRoute::GetNotice() const
{
    return GetWorld()->GetTimeSeconds() < NoticeUntil ? Notice : FText::GetEmpty();
}

int32 ARanwarRoute::GetCash() const
{
    return Stage == ERanwarJobStage::Complete ? ParcelPay : 0;
}

int32 ARanwarRoute::GetPoliceAlert() const
{
    return GetWorld()->GetTimeSeconds() < AlertUntil ? 1 : 0;
}

#undef LOCTEXT_NAMESPACE
