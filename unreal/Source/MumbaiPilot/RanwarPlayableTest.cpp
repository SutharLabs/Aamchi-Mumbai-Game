#include "CoreMinimal.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "CollisionQueryParams.h"
#include "CollisionShape.h"
#include "Components/BoxComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/Engine.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/PlatformTime.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "RanwarGame.h"
#include "RanwarRoute.h"
#include "RanwarTraffic.h"
#include "RanwarVehicle.h"
#include "UObject/Package.h"

namespace
{
    UWorld* GetRanwarGameWorld()
    {
        if (GEngine)
        {
            for (const FWorldContext& Context : GEngine->GetWorldContexts())
            {
                UWorld* World = Context.World();
                if (Context.WorldType == EWorldType::Game && World && World->HasBegunPlay()
                    && World->GetOutermost()->GetFName() == FName(TEXT("/Game/Ranwar/RanwarStreet")))
                {
                    return World;
                }
            }
        }
        return nullptr;
    }

    bool PlaceWalkerOnClearGround(UWorld& World, ARanwarCharacter& Walker, const FVector& Position)
    {
        const UCapsuleComponent* Capsule = Walker.GetCapsuleComponent();
        const float HalfHeight = Capsule->GetScaledCapsuleHalfHeight();
        const FCollisionShape Shape = FCollisionShape::MakeCapsule(Capsule->GetScaledCapsuleRadius(), HalfHeight);
        const FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarPlayablePlacement), true, &Walker);
        const FCollisionObjectQueryParams StaticSurfaces(ECC_WorldStatic);
        FHitResult Ground;
        if (!World.LineTraceSingleByObjectType(Ground, Position + FVector(0.0, 0.0, 90.0),
            Position - FVector(0.0, 0.0, 180.0), StaticSurfaces, Query) || Ground.ImpactNormal.Z < 0.7)
        {
            return false;
        }
        const FVector Stand = Ground.ImpactPoint + FVector(0.0, 0.0, HalfHeight + 5.0);
        const FCollisionResponseParams Responses(Capsule->GetCollisionResponseToChannels());
        if (World.OverlapBlockingTestByChannel(Stand, FQuat::Identity, Capsule->GetCollisionObjectType(), Shape, Query, Responses))
        {
            return false;
        }
        Walker.SetActorLocation(Stand, false, nullptr, ETeleportType::TeleportPhysics);
        return true;
    }

    void CheckParcelRun(FAutomationTestBase& Test, UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker)
    {
        const FVector Offsets[] = {
            FVector::ZeroVector,
            FVector(92.0, 0.0, 0.0), FVector(-92.0, 0.0, 0.0),
            FVector(0.0, 92.0, 0.0), FVector(0.0, -92.0, 0.0),
            FVector(112.0, 112.0, 0.0), FVector(112.0, -112.0, 0.0),
            FVector(-112.0, 112.0, 0.0), FVector(-112.0, -112.0, 0.0),
        };
        const ERanwarJobStage Stages[] = {
            ERanwarJobStage::Offer, ERanwarJobStage::Pickup, ERanwarJobStage::Dropoff, ERanwarJobStage::Complete,
        };
        const TCHAR* Actions[] = {
            TEXT("Talk to Anjali"), TEXT("Accept the parcel run"), TEXT("Pick up the parcel"), TEXT("Deliver the parcel"),
        };
        constexpr int32 StageCount = UE_ARRAY_COUNT(Stages);
        static_assert(UE_ARRAY_COUNT(Actions) == StageCount);
        for (int32 Index = 0; Index < StageCount; ++Index)
        {
            FVector Waypoint;
            if (!Test.TestTrue(Actions[Index], Route.GetWaypoint(Waypoint)))
            {
                return;
            }
            bool bInteracted = false;
            for (const FVector& Offset : Offsets)
            {
                if (PlaceWalkerOnClearGround(World, Walker, Waypoint + Offset) && !Route.GetPrompt(Walker).IsEmpty())
                {
                    bInteracted = Route.Interact(Walker);
                    if (bInteracted)
                    {
                        break;
                    }
                }
            }
            if (!Test.TestTrue(FString::Printf(TEXT("%s from a clear location at the authored waypoint"), Actions[Index]), bInteracted))
            {
                return;
            }
            const int32 Revision = Index + 1;
            const FString Slot = FString::Printf(TEXT("RanwarProgress%d"), Revision % 2);
            const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(Slot, 0));
            if (!Test.TestTrue(TEXT("Parcel checkpoint saves the next stage in the isolated user directory"),
                Saved && Saved->Revision == Revision && Saved->Stage == Stages[Index]))
            {
                return;
            }
        }
        Test.TestEqual(TEXT("Completing the parcel run pays INR 500"), Route.GetCash(), 500);
        Test.TestFalse(TEXT("Re-interacting after delivery cannot complete the run again"), Route.Interact(Walker));
        Test.TestEqual(TEXT("Repeated interaction leaves the payout at INR 500"), Route.GetCash(), 500);
    }

    void CheckVehicleTransfer(FAutomationTestBase& Test, UWorld& World, APlayerController& Player, ARanwarCharacter& Walker)
    {
        const FVector Original = Walker.GetActorLocation();
        const float Radius = Walker.GetCapsuleComponent()->GetScaledCapsuleRadius();
        for (TActorIterator<ARanwarVehicle> It(&World); It; ++It)
        {
            ARanwarVehicle* Vehicle = *It;
            const UBoxComponent* Body = Cast<UBoxComponent>(Vehicle->GetRootComponent());
            if (!Body)
            {
                continue;
            }
            const double Side = Body->GetScaledBoxExtent().Y + Radius + 45.0;
            for (const double Direction : {1.0, -1.0})
            {
                const FVector Position = Vehicle->GetActorLocation() + Vehicle->GetActorRightVector() * Side * Direction;
                if (!PlaceWalkerOnClearGround(World, Walker, Position) || !Vehicle->CanEnter(&Walker))
                {
                    continue;
                }
                Test.TestTrue(TEXT("Parked vehicle accepts Omkar"), Vehicle->TryEnter(&Walker));
                Test.TestTrue(TEXT("Local controller possesses occupied vehicle"),
                    Player.GetPawn() == Vehicle && Vehicle->HasDriver());
                Test.TestTrue(TEXT("Omkar exits the stationary vehicle into clear space"), Vehicle->ExitDriver());
                Test.TestTrue(TEXT("Exit returns a visible, solid Omkar to the local controller"),
                    Player.GetPawn() == &Walker && !Vehicle->HasDriver() && !Walker.IsHidden() && Walker.GetActorEnableCollision());
                return;
            }
        }
        Walker.SetActorLocation(Original, false, nullptr, ETeleportType::TeleportPhysics);
        Test.AddWarning(TEXT("Vehicle transfer was skipped because a clear boarding position could not be found."));
    }

    class FCheckRanwarPlayable final : public IAutomationLatentCommand
    {
    public:
        explicit FCheckRanwarPlayable(FAutomationTestBase& InTest)
            : Test(InTest), Deadline(FPlatformTime::Seconds() + 12.0)
        {
        }

        bool Update() override
        {
            UWorld* World = GetRanwarGameWorld();
            APlayerController* Player = World ? World->GetFirstPlayerController() : nullptr;
            ARanwarCharacter* Walker = Player && Player->IsLocalController()
                ? Cast<ARanwarCharacter>(Player->GetPawn()) : nullptr;
            if (!World || !Walker)
            {
                if (FPlatformTime::Seconds() < Deadline)
                {
                    return false;
                }
                Test.AddError(TEXT("RanwarStreet did not start with a locally possessed Omkar."));
                return true;
            }

            int32 CarCount = 0;
            for (TActorIterator<ARanwarTrafficCar> It(World); It; ++It)
            {
                ++CarCount;
                ARanwarTrafficCar* Car = *It;
                if (!TrackedCar.IsValid())
                {
                    TrackedCar = Car;
                    TrafficOrigin = Car->GetActorLocation();
                }
            }
            const bool bTrafficMoved = TrackedCar.IsValid()
                && FVector::DistSquared2D(TrackedCar->GetActorLocation(), TrafficOrigin) >= FMath::Square(100.0);
            if (!bTrafficMoved && FPlatformTime::Seconds() < Deadline)
            {
                return false;
            }

            Test.TestNotNull(TEXT("Ranwar uses the imported Omkar skeletal mesh"), Walker->GetMesh()->GetSkeletalMeshAsset());
            TActorIterator<APlayerStart> Arrival(World);
            Test.TestTrue(TEXT("Omkar spawns by the map's BEST arrival start"),
                Arrival && FVector::DistSquared2D(Arrival->GetActorLocation(), Walker->GetActorLocation())
                    < FMath::Square(175.0));

            const ARanwarGameMode* Mode = World->GetAuthGameMode<ARanwarGameMode>();
            Test.TestNotNull(TEXT("Ranwar native game mode is active"), Mode);
            ARanwarRoute* Route = Mode ? Mode->GetRoute() : nullptr;
            if (Test.TestNotNull(TEXT("Game mode uses the authored parcel route"), Route))
            {
                FVector Guide;
                Test.TestFalse(TEXT("New player has no prior progress"), Route->HasSavedProgress());
                Test.TestTrue(TEXT("New player starts with an Anjali objective within 30 metres"),
                    Route->GetWaypoint(Guide) && FVector::DistSquared2D(Guide, Walker->GetActorLocation())
                        < FMath::Square(3000.0) && !Route->GetObjective(Walker->GetActorLocation()).IsEmpty());
                Test.TestEqual(TEXT("New player starts with no parcel payout"), Route->GetCash(), 0);
                Test.TestEqual(TEXT("New player starts with no police alert"), Route->GetPoliceAlert(), 0);
            }

            TSet<FName> ArrivalAssets;
            for (TActorIterator<AStaticMeshActor> It(World); It; ++It)
            {
                const UStaticMesh* Asset = It->GetStaticMeshComponent()->GetStaticMesh();
                if (Asset && Asset->GetPathName().StartsWith(TEXT("/Game/Ranwar/Arrival/")))
                {
                    ArrivalAssets.Add(Asset->GetFName());
                }
            }
            Test.TestTrue(TEXT("The map contains the imported BEST bus and Anjali"),
                ArrivalAssets.Contains(FName(TEXT("BestBus"))) && ArrivalAssets.Contains(FName(TEXT("Anjali"))));

            TSet<FName> VehicleAssets;
            for (TActorIterator<ARanwarVehicle> It(World); It; ++It)
            {
                if (const UStaticMesh* Asset = It->GetVehicleMesh()->GetStaticMesh())
                {
                    VehicleAssets.Add(Asset->GetFName());
                }
            }
            for (const TCHAR* Family : {TEXT("Hatchback"), TEXT("Rickshaw"), TEXT("Motorcycle"), TEXT("Scooter")})
            {
                Test.TestTrue(FString::Printf(TEXT("A parked %s uses its imported mesh"), Family),
                    VehicleAssets.Contains(FName(Family)));
            }
            Test.TestTrue(TEXT("Map contains its native traffic system"), static_cast<bool>(TActorIterator<ARanwarTraffic>(World)));
            Test.TestTrue(TEXT("Between one and four ambient traffic vehicles are active"), CarCount >= 1 && CarCount <= 4);
            Test.TestTrue(TEXT("An ambient vehicle travels along the registered roads"), bTrafficMoved);
            if (Route)
            {
                CheckParcelRun(Test, *World, *Route, *Walker);
            }
            CheckVehicleTransfer(Test, *World, *Player, *Walker);
            return true;
        }

    private:
        FAutomationTestBase& Test;
        const double Deadline;
        TWeakObjectPtr<ARanwarTrafficCar> TrackedCar;
        FVector TrafficOrigin = FVector::ZeroVector;
    };
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FRanwarPlayableSmoke, "AamchiMumbai.Ranwar.Playable",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::ProductFilter)

bool FRanwarPlayableSmoke::RunTest(const FString&)
{
    FString UserDir;
    FParse::Value(FCommandLine::Get(), TEXT("UserDir="), UserDir);
    const FString Saved = FPaths::ConvertRelativePathToFull(FPaths::ProjectSavedDir());
    if (UserDir.IsEmpty() || FPaths::IsRelative(UserDir) || !FPaths::IsUnderDirectory(Saved, UserDir)
        || UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProgress0"), 0)
        || UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProgress1"), 0))
    {
        AddError(TEXT("Run the Ranwar smoke test with -UserDir pointing to a fresh absolute scratch directory."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FCheckRanwarPlayable(*this));
    return true;
}

#endif
