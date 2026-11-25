#include "CoreMinimal.h"

#if WITH_DEV_AUTOMATION_TESTS

#include "Algo/AllOf.h"
#include "Camera/CameraActor.h"
#include "Camera/CameraComponent.h"
#include "CollisionQueryParams.h"
#include "CollisionShape.h"
#include "Components/BoxComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/LightComponent.h"
#include "Components/PoseableMeshComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/Engine.h"
#include "Engine/Light.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "EngineUtils.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "GameFramework/PlayerController.h"
#include "GameFramework/PlayerStart.h"
#include "HAL/PlatformTime.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/App.h"
#include "Misc/AutomationTest.h"
#include "Misc/CommandLine.h"
#include "Misc/PackageName.h"
#include "Misc/Parse.h"
#include "Misc/Paths.h"
#include "RanwarBus.h"
#include "RanwarGame.h"
#include "RanwarEnvironment.h"
#include "RanwarMap.h"
#include "RanwarParcelContact.h"
#include "RanwarRoute.h"
#include "RanwarStrideAnimation.h"
#include "RanwarTraffic.h"
#include "RanwarVehicle.h"
#include "UnrealClient.h"
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

    bool InteractNear(UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker, const FVector& Point)
    {
        const FVector Offsets[] = {
            FVector::ZeroVector,
            FVector(92.0, 0.0, 0.0), FVector(-92.0, 0.0, 0.0),
            FVector(0.0, 92.0, 0.0), FVector(0.0, -92.0, 0.0),
            FVector(112.0, 112.0, 0.0), FVector(112.0, -112.0, 0.0),
            FVector(-112.0, 112.0, 0.0), FVector(-112.0, -112.0, 0.0),
        };
        for (const FVector& Offset : Offsets)
        {
            if (PlaceWalkerOnClearGround(World, Walker, Point + Offset) && !Route.GetPrompt(Walker).IsEmpty()
                && Route.Interact(Walker))
            {
                return true;
            }
        }
        return false;
    }

    void CheckLedgerRun(FAutomationTestBase& Test, UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker,
        const FVector& GuideStop)
    {
        FVector Pickup;
        if (!Test.TestTrue(TEXT("The imported Hill Road Tea Room is the next story destination"),
            Route.GetWaypoint(Pickup) && Route.GetObjective(Walker.GetActorLocation()).ToString().Contains(TEXT("Hill Road Tea Room"))))
        {
            return;
        }
        Test.TestFalse(TEXT("The ledger cannot be collected remotely"), Route.Interact(Walker));
        if (!Test.TestTrue(TEXT("Asha accepts an on-foot interaction inside the tea room"), InteractNear(World, Route, Walker, Pickup)))
        {
            return;
        }
        Test.TestEqual(TEXT("Asha captions the ledger copy pickup"), Route.GetDialogueSpeaker().ToString(), FString(TEXT("Asha")));
        Test.TestEqual(TEXT("The pickup alone pays no ledger reward"), Route.GetCash(), 650);
        FVector Handoff;
        if (!Test.TestTrue(TEXT("The route now points to the Chapel Corner Grocer"),
            Route.GetWaypoint(Handoff) && !Pickup.Equals(Handoff)
            && Route.GetObjective(Walker.GetActorLocation()).ToString().Contains(TEXT("Chapel Corner Grocer"))))
        {
            return;
        }

        Route.SelectProfile(3);
        Test.TestFalse(TEXT("Another profile does not inherit the first profile's ledger checkpoint"), Route.HasSavedProgress());
        Route.SelectProfile(1);
        FVector Restored;
        Test.TestTrue(TEXT("The active ledger objective survives checkpoint reload"), Route.GetWaypoint(Restored) && Handoff.Equals(Restored));
        Test.TestTrue(TEXT("The active ledger job can be abandoned"), Route.CanAbandonJob() && Route.AbandonJob());
        Test.TestTrue(TEXT("Abandonment restores Asha and preserves already paid jobs"),
            Route.GetWaypoint(Restored) && Pickup.Equals(Restored) && Route.GetCash() == 650);
        if (!Test.TestTrue(TEXT("The ledger can be collected again after abandonment"), InteractNear(World, Route, Walker, Pickup))
            || !Test.TestTrue(TEXT("The grocer accepts the copy inside the second shop"),
                Route.GetWaypoint(Restored) && Restored.Equals(Handoff) && InteractNear(World, Route, Walker, Handoff)))
        {
            return;
        }
        Test.TestEqual(TEXT("The grocer captions the ledger handoff"), Route.GetDialogueSpeaker().ToString(), FString(TEXT("Grocer")));
        Test.TestEqual(TEXT("The independent ledger payment adds INR 400"), Route.GetCash(), 1050);
        Test.TestFalse(TEXT("The ledger handoff cannot be repeated for money"), Route.Interact(Walker));
        Test.TestFalse(TEXT("Completing the ledger clears the active story waypoint"), Route.GetWaypoint(Restored));

        const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(TEXT("RanwarProgress1"), 0));
        Test.TestTrue(TEXT("The migrated checkpoint stores the original delivery plus the ledger receipt"),
            Saved && Saved->Version == 4 && Saved->Stage == ERanwarJobStage::Complete
            && Saved->DabbaDeliveries == 1 && Saved->LedgerStage == ERanwarLedgerStage::Complete);
        if (FParse::Param(FCommandLine::Get(), TEXT("RanwarCaptureLedger")))
        {
            FScreenshotRequest::RequestScreenshot(true);
            return;
        }
        Route.SelectProfile(3);
        Route.SelectProfile(1);
        Test.TestEqual(TEXT("The ledger reward survives checkpoint reload"), Route.GetCash(), 1050);
        if (!Test.TestTrue(TEXT("Anjali still offers the repeatable dabba route after the ledger"),
            InteractNear(World, Route, Walker, GuideStop)))
        {
            return;
        }
        for (const TCHAR* Action : {TEXT("Pick up the second dabba from Hill Road"), TEXT("Hand the second dabba to Nandini")})
        {
            FVector Waypoint;
            if (!Test.TestTrue(Action, Route.GetWaypoint(Waypoint) && InteractNear(World, Route, Walker, Waypoint)))
            {
                return;
            }
        }
        Test.TestEqual(TEXT("The alternating repeatable still adds INR 150"), Route.GetCash(), 1200);
        Test.TestEqual(TEXT("Nandini captions the alternate dabba handoff"), Route.GetDialogueSpeaker().ToString(), FString(TEXT("Nandini")));
    }

    const ARanwarParcelContact* ParcelContactNear(UWorld& World, const FVector& Point)
    {
        for (TActorIterator<ARanwarParcelContact> It(&World); It; ++It)
        {
            if (FVector::DistSquared2D(It->GetActorLocation(), Point) < FMath::Square(130.0))
            {
                return *It;
            }
        }
        return nullptr;
    }

    void CheckParcelContact(FAutomationTestBase& Test, UWorld& World, const ARanwarCharacter& Walker,
        const ARanwarParcelContact* Contact, const TCHAR* MeshName, const TCHAR* Fallback)
    {
        if (!Test.TestNotNull(TEXT("The exchange has a real actor beside the access lane"), Contact))
        {
            return;
        }
        const UStaticMeshComponent* Visual = Contact->FindComponentByClass<UStaticMeshComponent>();
        const UStaticMesh* Mesh = Visual ? Visual->GetStaticMesh() : nullptr;
        const AActor* MetaHuman = Contact->GetMetaHumanVisual();
        Test.TestTrue(TEXT("The contact has a deliberate standing appearance"),
            (IsValid(MetaHuman) && MetaHuman->GetAttachParentActor() == Contact && !MetaHuman->IsHidden())
            || (Mesh && (Mesh->GetFName() == FName(MeshName) || Mesh->GetFName() == FName(Fallback))));
        const UCapsuleComponent* Body = Contact->FindComponentByClass<UCapsuleComponent>();
        Test.TestTrue(FString::Printf(TEXT("%s blocks walkers and vehicle sweeps"), MeshName),
            Body && Body->GetCollisionEnabled() == ECollisionEnabled::QueryOnly
            && Body->GetCollisionObjectType() == ECC_Pawn
            && Body->GetCollisionResponseToChannel(ECC_Pawn) == ECR_Block
            && Body->GetCollisionResponseToChannel(ECC_WorldDynamic) == ECR_Block);
        const FVector Feet = Contact->GetActorLocation();
        FHitResult Floor;
        const FCollisionObjectQueryParams Surfaces(ECC_WorldStatic);
        const FCollisionQueryParams Collision(SCENE_QUERY_STAT(RanwarParcelContactGrounding), true, Contact);
        Test.TestTrue(TEXT("The contact is grounded on the imported street collider"),
            World.LineTraceSingleByObjectType(Floor, Feet + FVector(0.0, 0.0, 30.0),
                Feet - FVector(0.0, 0.0, 30.0), Surfaces, Collision)
            && Floor.ImpactNormal.Z > 0.70 && FMath::Abs(Floor.ImpactPoint.Z - Feet.Z) < 2.0);
        Test.TestTrue(TEXT("The contact turns to face Omkar at a successful exchange"),
            FVector::DotProduct(Contact->GetActorForwardVector(), (Walker.GetActorLocation() - Feet).GetSafeNormal2D()) > 0.97);
    }

    bool CheckParcelRun(FAutomationTestBase& Test, UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker, FVector& GuideStop)
    {
        if (!Test.TestTrue(TEXT("Anjali's arrival waypoint is available"), Route.GetWaypoint(GuideStop)))
        {
            return false;
        }
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
                return false;
            }
            const bool bPickup = Stages[Index] == ERanwarJobStage::Dropoff;
            const bool bHandoff = Stages[Index] == ERanwarJobStage::Complete;
            const bool bContactExchange = bPickup || bHandoff;
            Test.TestEqual(TEXT("The named parcel contact uses a ground-only mission waypoint"), Route.UsesParcelGroundHint(), bContactExchange);
            const ARanwarParcelContact* Contact = bContactExchange ? ParcelContactNear(World, Waypoint) : nullptr;
            if (!Test.TestTrue(FString::Printf(TEXT("%s from a clear location at the authored waypoint"), Actions[Index]),
                InteractNear(World, Route, Walker, Waypoint)))
            {
                return false;
            }
            const int32 Revision = Index + 1;
            if (Stages[Index] == ERanwarJobStage::Offer || bContactExchange)
            {
                const FString ExpectedSpeaker = bPickup ? TEXT("Ravi") : bHandoff ? TEXT("Kavita") : TEXT("Anjali");
                Test.TestEqual(TEXT("The packaged route loads the expected dialogue speaker"), Route.GetDialogueSpeaker().ToString(), ExpectedSpeaker);
                Test.TestFalse(TEXT("The packaged route loads the speaker's subtitle"), Route.GetDialogueText().IsEmpty());
            }
            if (bContactExchange)
            {
                CheckParcelContact(Test, World, Walker, Contact, bPickup ? TEXT("Ravi") : TEXT("Kavita"), bPickup ? TEXT("Iqbal") : TEXT("Leena"));
            }
            if (bHandoff && Contact && FParse::Param(FCommandLine::Get(), TEXT("RanwarCaptureParcel")))
            {
                const FVector Across = (Waypoint - Contact->GetActorLocation()).GetSafeNormal2D();
                const FVector Along(-Across.Y, Across.X, 0.0);
                PlaceWalkerOnClearGround(World, Walker, Waypoint + Along * 88.0);
                FRotator View = (Contact->GetActorLocation() - Walker.GetActorLocation()).Rotation();
                View.Pitch = -8.0;
                View.Yaw += 17.0;
                Walker.GetController()->SetControlRotation(View);
                FScreenshotRequest::RequestScreenshot(true);
            }
            const FString Slot = FString::Printf(TEXT("RanwarProgress%d"), Revision % 2);
            const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(Slot, 0));
            if (!Test.TestTrue(TEXT("Parcel checkpoint saves the next stage in the isolated user directory"),
                Saved && Saved->Revision == Revision && Saved->Stage == Stages[Index]))
            {
                return false;
            }
        }
        Test.TestEqual(TEXT("Completing the parcel run pays INR 500"), Route.GetCash(), 500);
        Test.TestFalse(TEXT("Re-interacting after delivery cannot complete the run again"), Route.Interact(Walker));
        Test.TestEqual(TEXT("Repeated interaction leaves the payout at INR 500"), Route.GetCash(), 500);
        return true;
    }

    void CheckDabbaAndLedger(FAutomationTestBase& Test, UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker,
        const FVector& GuideStop)
    {
        if (!Test.TestTrue(TEXT("Anjali offers the optional dabba job"), InteractNear(World, Route, Walker, GuideStop)))
        {
            return;
        }
        Test.TestEqual(TEXT("The optional job starts with a caption from Anjali"), Route.GetDialogueSpeaker().ToString(), FString(TEXT("Anjali")));
        for (const TCHAR* Action : {TEXT("Pick up the dabba"), TEXT("Hand off the dabba")})
        {
            FVector Waypoint;
            if (!Test.TestTrue(Action, Route.GetWaypoint(Waypoint) && InteractNear(World, Route, Walker, Waypoint)))
            {
                return;
            }
        }
        Test.TestEqual(TEXT("The dabba delivery adds INR 150"), Route.GetCash(), 650);
        Test.TestEqual(TEXT("Prakash captions the first delivery"), Route.GetDialogueSpeaker().ToString(), FString(TEXT("Prakash")));
        FVector RemainingGoal;
        Test.TestTrue(TEXT("Completing the dabba clears its own waypoint"),
            !Route.GetWaypoint(RemainingGoal) || Route.GetObjective(Walker.GetActorLocation()).ToString().Contains(TEXT("Asha")));
        if (FParse::Param(FCommandLine::Get(), TEXT("RanwarLedgerSmoke")))
        {
            CheckLedgerRun(Test, World, Route, Walker, GuideStop);
        }
    }

    void CheckSeparateProfile(FAutomationTestBase& Test, UWorld& World, ARanwarRoute& Route, ARanwarCharacter& Walker)
    {
        if (UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProfile2Progress0"), 0)
            || UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProfile2Progress1"), 0))
        {
            Test.AddError(TEXT("The profile smoke check requires an empty second profile in the isolated user directory."));
            return;
        }
        const int32 DefaultCash = Route.GetCash();
        Route.SelectProfile(2);
        Test.TestFalse(TEXT("A new second profile does not inherit the first profile's Continue action"), Route.HasSavedProgress());
        Test.TestEqual(TEXT("A new second profile has its own cash"), Route.GetCash(), 0);
        FVector Waypoint;
        if (Test.TestTrue(TEXT("The second profile can reach Anjali"),
                Route.GetWaypoint(Waypoint) && InteractNear(World, Route, Walker, Waypoint))
            && Test.TestTrue(TEXT("The second profile can accept the parcel run"),
                Route.GetWaypoint(Waypoint) && InteractNear(World, Route, Walker, Waypoint)))
        {
            Test.TestTrue(TEXT("An active delivery can be abandoned"), Route.CanAbandonJob() && Route.AbandonJob());
            Test.TestFalse(TEXT("Abandonment removes the active delivery"), Route.CanAbandonJob());
            const URanwarProgress* Saved = Cast<URanwarProgress>(UGameplayStatics::LoadGameFromSlot(TEXT("RanwarProfile2Progress1"), 0));
            Test.TestTrue(TEXT("Abandonment commits the offer checkpoint to the second profile"),
                Saved && Saved->Revision == 3 && Saved->Stage == ERanwarJobStage::Offer);
            Test.TestTrue(TEXT("Confirmed New Game writes a fresh checkpoint"), Route.ResetProgress());
            Test.TestFalse(TEXT("The current profile has no Continue after a new game"), Route.HasSavedProgress());
            Route.SelectProfile(1);
            Route.SelectProfile(2);
            Test.TestFalse(TEXT("Returning to the second profile retains the reset across reload"),
                Route.HasSavedProgress() || Route.CanAbandonJob());
        }
        Route.SelectProfile(1);
        Test.TestEqual(TEXT("Default-profile legacy slots still hold completed payouts"), Route.GetCash(), DefaultCash);
    }

    void CheckSeatedContacts(FAutomationTestBase& Test, ARanwarVehicle& Vehicle, FName Mesh,
        const USkeletalMeshComponent& AvatarBody, bool bMetaHuman)
    {
        struct FContactFixture
        {
            FName Mesh;
            FVector RightGrip;
            FVector RightGripInward;
            double GripRadius;
            FVector RightAnkle;
            double CenterY;
            bool bMovingFork = false;
        };
        static const FContactFixture Fixtures[] = {
            { TEXT("Hatchback"), FVector(50.05, 13.2, 120.17), FVector(0.283, -0.442, 0.852), 1.8,
                FVector(47.5, 8.5, 65.0), 35.0 },
            { TEXT("Rickshaw"), FVector(57.5, 21.5, 86.7), FVector(0.0, -1.0, 0.0), 2.4,
                FVector(34.0, 10.5, 55.5), 0.0 },
            { TEXT("Motorcycle"), FVector(51.1, 30.95, 101.4), FVector(0.0, -1.0, 0.0), 1.8,
                FVector(-13.5, 23.0, 37.5), 0.0 },
            { TEXT("Scooter"), FVector(33.1, 30.85, 105.8), FVector(0.0, -1.0, 0.0), 1.8,
                FVector(26.7, 14.1, 36.4), 0.0 },
            { TEXT("MotorcycleVinishBody"), FVector(29.55, 32.5, 106.91), FVector(0.40, -1.0, 0.025), 1.8,
                FVector(-27.0, 21.0, 39.5), 0.0, true },
            { TEXT("ScooterVinishBody"), FVector(20.88, 28.8, 97.55), FVector(0.31, -1.0, 0.01), 1.8,
                FVector(-4.0, 14.8, 41.6), 0.0, true }
        };
        const FContactFixture* Fixture = nullptr;
        for (const FContactFixture& Candidate : Fixtures)
        {
            if (Candidate.Mesh == Mesh)
            {
                Fixture = &Candidate;
                break;
            }
        }
        const USkinnedMeshComponent* Rider = bMetaHuman
            ? static_cast<const USkinnedMeshComponent*>(&AvatarBody) : Vehicle.FindComponentByClass<UPoseableMeshComponent>();
        if (!Test.TestNotNull(TEXT("The parked mesh has a measured cockpit"), Fixture)
            || !Test.TestNotNull(TEXT("The occupied vehicle has an evaluated rider"), Rider))
        {
            return;
        }
        const auto* Fork = Cast<UStaticMeshComponent>(Vehicle.GetDefaultSubobjectByName(TEXT("VisualFork")));
        if (Fixture->bMovingFork && !Test.TestNotNull(TEXT("The detailed bike has its steering fork"), Fork))
        {
            return;
        }
        const auto CheckPose = [&](const TCHAR* Position)
        {
            const FTransform& Chassis = Vehicle.GetVehicleMesh()->GetComponentTransform();
            const FTransform& GripTransform = Fixture->bMovingFork ? Fork->GetComponentTransform() : Chassis;
            const FVector GripPivot = Fixture->bMovingFork ? Fork->GetRelativeLocation() : FVector::ZeroVector;
            const TArray<FTransform>& Pose = Rider->GetComponentSpaceTransforms();
            const FTransform& RiderTransform = Rider->GetComponentTransform();
            const auto ReadBone = [&](FName Bone, FVector& Point)
            {
                const int32 Index = Rider->GetBoneIndex(Bone);
                if (!Test.TestTrue(FString::Printf(TEXT("Seated driver evaluates %s"), *Bone.ToString()), Pose.IsValidIndex(Index)))
                {
                    return false;
                }
                Point = RiderTransform.TransformPosition(Pose[Index].GetLocation());
                return true;
            };
            for (int32 Side : {-1, 1})
            {
                const bool bRight = Side > 0;
                const FString Label = FString::Printf(TEXT("%s %s %s"), *Mesh.ToString(), Position,
                    bRight ? TEXT("right") : TEXT("left"));
                FVector LocalGrip = Fixture->RightGrip;
                LocalGrip.Y = Fixture->CenterY + Side * LocalGrip.Y;
                const FVector Grip = GripTransform.TransformPosition(LocalGrip - GripPivot);
                FVector LocalAnkle = Fixture->RightAnkle;
                LocalAnkle.Y = Fixture->CenterY + Side * LocalAnkle.Y;
                LocalAnkle.Z += bMetaHuman ? 1.4 : 0.0;
                FVector Ankle;
                const FName AnkleBone(bMetaHuman ? (bRight ? TEXT("foot_r") : TEXT("foot_l"))
                                                 : (bRight ? TEXT("RightFoot") : TEXT("LeftFoot")));
                if (ReadBone(AnkleBone, Ankle))
                {
                    const double Error = FVector::Distance(Ankle, Chassis.TransformPosition(LocalAnkle));
                    Test.TestTrue(FString::Printf(TEXT("%s ankle stays at its support (%.2f cm)"), *Label, Error), Error <= 6.0);
                }

                FVector Wrist;
                const FName WristBone(bMetaHuman ? (bRight ? TEXT("hand_r") : TEXT("hand_l"))
                                                 : (bRight ? TEXT("RightHand") : TEXT("LeftHand")));
                if (!ReadBone(WristBone, Wrist))
                {
                    continue;
                }
                if (!bMetaHuman)
                {
                    const FVector Offset = GripTransform.TransformVectorNoScale(FVector(4.0, 0.0, -0.6));
                    const double Error = FVector::Distance(Wrist, Grip - Offset);
                    Test.TestTrue(FString::Printf(TEXT("%s legacy wrist stays by the grip (%.2f cm)"), *Label, Error), Error <= 10.0);
                    continue;
                }

                FVector Knuckle, Thumb, Fingertip, Index, Pinky;
                if (!ReadBone(bRight ? TEXT("middle_01_r") : TEXT("middle_01_l"), Knuckle)
                    || !ReadBone(bRight ? TEXT("middle_03_r") : TEXT("middle_03_l"), Fingertip)
                    || !ReadBone(bRight ? TEXT("thumb_03_r") : TEXT("thumb_03_l"), Thumb)
                    || !ReadBone(bRight ? TEXT("index_01_r") : TEXT("index_01_l"), Index)
                    || !ReadBone(bRight ? TEXT("pinky_01_r") : TEXT("pinky_01_l"), Pinky))
                {
                    continue;
                }

                FVector LocalAxis = Fixture->RightGripInward;
                LocalAxis.Y *= Side;
                const FVector Axis = GripTransform.TransformVectorNoScale(LocalAxis).GetSafeNormal();
                const FVector Forward = FVector::VectorPlaneProject(
                    GripTransform.TransformVectorNoScale(FVector::ForwardVector), Axis).GetSafeNormal();
                const FVector Down = Side * FVector::CrossProduct(Forward, Axis);
                const FVector Palm = FMath::Lerp(Wrist, Knuckle, 0.75);
                const FVector Desired = Grip - Down * (Fixture->GripRadius + 1.3 * RiderTransform.GetScale3D().X);
                const double Error = FVector::Distance(Palm, Desired);
                Test.TestTrue(FString::Printf(TEXT("%s palm locks onto the grip (%.2f cm)"), *Label, Error), Error <= 1.5);
                Test.TestTrue(Label + TEXT(" knuckles follow the grip axis"),
                    FVector::DotProduct((Index - Pinky).GetSafeNormal(), Axis) >= 0.90);
                const FVector FingerOffset = Fingertip - Grip;
                Test.TestTrue(Label + TEXT(" fingers wrap under the grip with the thumb opposed"),
                    FVector::DotProduct(FingerOffset, Down) > 0.7
                    && FVector::DotProduct(Thumb - Grip, Down) > 0.7
                    && FVector::VectorPlaneProject(FingerOffset, Axis).Size() <= Fixture->GripRadius + 2.2);
            }
        };
        CheckPose(TEXT("centered"));
        if (Fixture->bMovingFork)
        {
            const FInputAxisBinding* Steering = Vehicle.InputComponent
                ? Vehicle.InputComponent->AxisBindings.FindByPredicate([](const FInputAxisBinding& Binding)
                    { return Binding.AxisName == TEXT("MoveRight"); })
                : nullptr;
            if (!Test.TestNotNull(TEXT("The detailed bike has its normal steering input"), Steering))
            {
                return;
            }
            const auto Steer = [&](float Axis)
            {
                Steering->AxisDelegate.Execute(Axis);
                static_cast<AActor&>(Vehicle).Tick(0.24f);
            };
            const FQuat Center = Fork->GetRelativeRotation().Quaternion();
            Steer(0.5f);
            CheckPose(TEXT("mid-turn"));
            Steer(1.0f);
            const FQuat Right = Fork->GetRelativeRotation().Quaternion();
            Test.TestTrue(TEXT("Steering input turns the detailed fork right"), Center.AngularDistance(Right) > 0.3);
            CheckPose(TEXT("right lock"));
            Steer(-1.0f);
            Steer(-1.0f);
            Test.TestTrue(TEXT("Steering input turns the detailed fork across to left lock"),
                Right.AngularDistance(Fork->GetRelativeRotation().Quaternion()) > 0.7);
            CheckPose(TEXT("left lock"));
            Steer(0.0f);
        }
    }

    void CheckVehicleTransfer(FAutomationTestBase& Test, UWorld& World, APlayerController& Player, ARanwarCharacter& Walker)
    {
        const FVector Original = Walker.GetActorLocation();
        const float Radius = Walker.GetCapsuleComponent()->GetScaledCapsuleRadius();
        TSet<FName> CheckedFamilies;
        for (TActorIterator<ARanwarVehicle> It(&World); It; ++It)
        {
            ARanwarVehicle* Vehicle = *It;
            const UBoxComponent* Body = Cast<UBoxComponent>(Vehicle->GetRootComponent());
            const UStaticMesh* Mesh = Vehicle->GetVehicleMesh()->GetStaticMesh();
            if (!Body || !Mesh || CheckedFamilies.Contains(Mesh->GetFName()))
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
                const USkeletalMeshComponent* AvatarBody = Walker.GetAvatarBody();
                const bool bBodyTickEnabledOnFoot = AvatarBody->IsComponentTickEnabled();
                if (!Test.TestTrue(TEXT("Parked vehicle accepts Omkar"), Vehicle->TryEnter(&Walker)))
                {
                    break;
                }
                Test.TestTrue(TEXT("Local controller possesses occupied vehicle"),
                    Player.GetPawn() == Vehicle && Vehicle->HasDriver());
                if (const AActor* MetaHuman = Walker.GetMetaHumanVisual())
                {
                    Test.TestTrue(TEXT("The same visible MetaHuman follows the seated driver pose"),
                        MetaHuman->GetAttachParentActor() == Vehicle && !MetaHuman->IsHidden()
                            && !AvatarBody->LeaderPoseComponent.IsValid()
                            && !AvatarBody->IsComponentTickEnabled()
                            && AvatarBody->GetAnimationMode() == EAnimationMode::AnimationCustomMode);
                }
                CheckSeatedContacts(Test, *Vehicle, Mesh->GetFName(), *AvatarBody, IsValid(Walker.GetMetaHumanVisual()));
                if (!Test.TestTrue(TEXT("Omkar exits the stationary vehicle into clear space"), Vehicle->ExitDriver()))
                {
                    return;
                }
                Test.TestTrue(TEXT("Exit returns a visible, solid Omkar to the local controller"),
                    Player.GetPawn() == &Walker && !Vehicle->HasDriver() && !Walker.IsHidden() && Walker.GetActorEnableCollision());
                if (const AActor* MetaHuman = Walker.GetMetaHumanVisual())
                {
                    Test.TestTrue(TEXT("The same visible MetaHuman returns to the walking capsule"),
                        MetaHuman->GetAttachParentActor() == &Walker && !MetaHuman->IsHidden()
                            && !AvatarBody->LeaderPoseComponent.IsValid()
                            && AvatarBody->IsComponentTickEnabled() == bBodyTickEnabledOnFoot
                            && Cast<URanwarStrideAnimation>(AvatarBody->GetAnimInstance()) != nullptr);
                }
                CheckedFamilies.Add(Mesh->GetFName());
                break;
            }
        }
        Walker.SetActorLocation(Original, false, nullptr, ETeleportType::TeleportPhysics);
        Test.TestEqual(TEXT("Omkar boards and exits all four vehicle families"), CheckedFamilies.Num(), 4);
    }

    class FCheckRanwarRiderPhoto final : public IAutomationLatentCommand
    {
    public:
        FCheckRanwarRiderPhoto(FAutomationTestBase& InTest, FName InBike)
            : Test(InTest), Bike(InBike), Deadline(FPlatformTime::Seconds() + 12.0)
        {
        }

        bool Update() override
        {
            const double Now = FPlatformTime::Seconds();
            if (ARanwarVehicle* Vehicle = Mounted.Get())
            {
                if (bRequested)
                {
                    if (FScreenshotRequest::IsScreenshotRequested() && Now < FrameAt + 5.0)
                    {
                        return false;
                    }
                    Test.TestFalse(TEXT("The mounted screenshot was rendered"), FScreenshotRequest::IsScreenshotRequested());
                    Test.TestTrue(TEXT("Omkar dismounts safely after the photo"), Vehicle->ExitDriver());
                    if (ACameraActor* View = Camera.Get())
                    {
                        View->Destroy();
                    }
                    return true;
                }

                if (const FInputAxisBinding* Steer = Vehicle->InputComponent
                    ? Vehicle->InputComponent->AxisBindings.FindByPredicate([](const FInputAxisBinding& Binding)
                        { return Binding.AxisName == TEXT("MoveRight"); }) : nullptr)
                {
                    Steer->AxisDelegate.Execute(-0.72f);
                    static_cast<AActor&>(*Vehicle).Tick(0.24f);
                }
                if (Now >= FrameAt)
                {
                    FScreenshotRequest::RequestScreenshot(false);
                    bRequested = true;
                }
                return false;
            }

            UWorld* World = GetRanwarGameWorld();
            APlayerController* Player = World ? World->GetFirstPlayerController() : nullptr;
            ARanwarCharacter* Walker = Player ? Cast<ARanwarCharacter>(Player->GetPawn()) : nullptr;
            if (!World || !Walker)
            {
                if (Now < Deadline)
                {
                    return false;
                }
                Test.AddError(TEXT("Ranwar did not start for the mounted screenshot."));
                return true;
            }
            if (!Test.TestNotNull(TEXT("The current MetaHuman Omkar is available for the mounted photo"),
                Walker->GetMetaHumanVisual()))
            {
                return true;
            }

            for (TActorIterator<ARanwarVehicle> It(World); It; ++It)
            {
                ARanwarVehicle* Vehicle = *It;
                const UStaticMesh* Mesh = Vehicle->GetVehicleMesh()->GetStaticMesh();
                const UBoxComponent* Chassis = Cast<UBoxComponent>(Vehicle->GetRootComponent());
                if (!Mesh || Mesh->GetFName() != Bike || !Chassis)
                {
                    continue;
                }
                const double Clearance = Chassis->GetScaledBoxExtent().Y
                    + Walker->GetCapsuleComponent()->GetScaledCapsuleRadius() + 45.0;
                const FVector Stand = Vehicle->GetActorLocation() - Vehicle->GetActorRightVector() * Clearance;
                if (!PlaceWalkerOnClearGround(*World, *Walker, Stand) || !Vehicle->TryEnter(Walker))
                {
                    continue;
                }
                const FTransform& Rig = Vehicle->GetVehicleMesh()->GetComponentTransform();
                const FVector Eye = Rig.TransformPosition(FVector(160.0, -247.0, 164.0));
                const FVector Focus = Rig.TransformPosition(FVector(0.0, 0.0, 85.0));
                ACameraActor* View = World->SpawnActor<ACameraActor>(Eye, (Focus - Eye).Rotation());
                if (!Test.TestNotNull(TEXT("The rider verification camera spawns"), View))
                {
                    Vehicle->ExitDriver();
                    return true;
                }
                View->GetCameraComponent()->SetFieldOfView(51.0f);
                Player->SetViewTargetWithBlend(View, 0.0f);
                Camera = View;
                Mounted = Vehicle;
                FrameAt = Now + 1.0;
                return false;
            }
            Test.AddError(TEXT("No detailed parked bike had a clear boarding side for the screenshot."));
            return true;
        }

    private:
        FAutomationTestBase& Test;
        FName Bike;
        const double Deadline;
        double FrameAt = 0.0;
        bool bRequested = false;
        TWeakObjectPtr<ACameraActor> Camera;
        TWeakObjectPtr<ARanwarVehicle> Mounted;
    };

    void CheckEnvironmentClock(FAutomationTestBase& Test, UWorld& World, ARanwarEnvironment& Environment)
    {
        const double Start = Environment.GetTimeMinutes();
        const UInstancedStaticMeshComponent* Skyline = Environment.FindComponentByClass<UInstancedStaticMeshComponent>();
        Test.TestTrue(TEXT("The horizon is a single bounded, non-solid instance batch"),
            Skyline && Skyline->GetInstanceCount() >= 50 && Skyline->GetInstanceCount() <= 80
            && Skyline->GetCollisionEnabled() == ECollisionEnabled::NoCollision);
        const UStaticMeshComponent* Cloud = Cast<UStaticMeshComponent>(Environment.GetDefaultSubobjectByName(TEXT("CloudLayer")));
        Test.TestTrue(TEXT("The Ranwar sky uses a non-solid, single sheet with its real material"),
            Cloud && Cloud->GetStaticMesh() && Cloud->GetMaterial(0)
            && Cloud->GetCollisionEnabled() == ECollisionEnabled::NoCollision);

        const ULightComponent* Sun = nullptr;
        const ULightComponent* Moon = nullptr;
        TArray<const ULightComponent*> Streets;
        TArray<const ULightComponent*> Shops;
        for (TActorIterator<ALight> It(&World); It; ++It)
        {
            const ULightComponent* Light = It->GetLightComponent();
            if (Light && It->ActorHasTag(TEXT("RanwarSun"))) { Sun = Light; }
            if (Light && It->ActorHasTag(TEXT("RanwarMoon"))) { Moon = Light; }
            if (Light && It->ActorHasTag(TEXT("RanwarStreetLight"))) { Streets.Add(Light); }
            if (Light && It->ActorHasTag(TEXT("RanwarShopLight"))) { Shops.Add(Light); }
        }
        if (!Test.TestTrue(TEXT("The editor baked sunlight, cool fill, ten road fixtures, the BEST lamp and two fixtures per shop"),
            Sun && Moon && Streets.Num() == 11 && Shops.Num() == 4))
        {
            return;
        }

        Environment.SetTimeMinutes(630.0);
        Test.TestTrue(TEXT("Daytime has natural sunlight, unlit street fixtures and both shop interiors lit"),
            Sun->Intensity > 20000.0f && Moon->Intensity < 1.0f
            && Algo::AllOf(Streets, [](const ULightComponent* Light) { return Light->Intensity < 1.0f; })
            && Algo::AllOf(Shops, [](const ULightComponent* Light) { return Light->Intensity > 1000.0f; }));
        Environment.SetTimeMinutes(1050.0);
        const float DuskLampIntensity = Streets[0]->Intensity;
        Test.TestTrue(TEXT("Street lamps begin glowing while the sun is still above the horizon"),
            Sun->Intensity > 1000.0f && Sun->Intensity < 12000.0f && DuskLampIntensity > 10.0f);
        Environment.SetTimeMinutes(1290.0);
        Test.TestTrue(TEXT("Night has diffuse fill and warm local light with no extra shadow passes"),
            Sun->Intensity < 1.0f && Moon->Intensity > 100.0f
            && Algo::AllOf(Streets, [DuskLampIntensity](const ULightComponent* Light)
                { return Light->Intensity > DuskLampIntensity && !Light->CastShadows; })
            && Algo::AllOf(Shops, [](const ULightComponent* Light)
                { return Light->Intensity > 150.0f && !Light->CastShadows; }));
        Environment.SetTimeMinutes(1442.0);
        Test.TestEqual(TEXT("The minute clock wraps through midnight"), Environment.GetTimeMinutes(), 2.0);
        Environment.SetTimeMinutes(Start);
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

            const ARanwarGameMode* Mode = World->GetAuthGameMode<ARanwarGameMode>();
            ARanwarRoute* Route = Mode ? Mode->GetRoute() : nullptr;
            if (MiraDeadline > 0.0)
            {
                if (MotionDeadline > 0.0)
                {
                    USkeletalMeshComponent* Avatar = Walker->GetAvatarBody();
                    const double ToeHeight = Avatar->GetBoneLocation(TEXT("ball_l"), EBoneSpaces::ComponentSpace).Z;
                    const double HandPosition = Avatar->GetBoneLocation(TEXT("hand_l"), EBoneSpaces::ComponentSpace).Y;
                    MinToe = FMath::Min(MinToe, ToeHeight);
                    MaxToe = FMath::Max(MaxToe, ToeHeight);
                    MinHand = FMath::Min(MinHand, HandPosition);
                    MaxHand = FMath::Max(MaxHand, HandPosition);
                    if (!bMotionPhotoRequested && FApp::CanEverRender()
                        && FPlatformTime::Seconds() >= MotionDeadline - 0.65
                        && FParse::Param(FCommandLine::Get(), TEXT("RanwarWalkPhoto")))
                    {
                        bMotionPhotoRequested = true;
                        FScreenshotRequest::RequestScreenshot(true);
                    }
                    if (FPlatformTime::Seconds() < MotionDeadline)
                    {
                        Walker->AddMovementInput(MotionDirection, 1.0f);
                        return false;
                    }
                    Test.TestTrue(TEXT("On-foot movement evaluates a real Omkar toe lift and hand swing"),
                        FVector::DistSquared2D(MotionStart.GetLocation(), Walker->GetActorLocation()) > FMath::Square(35.0)
                        && MaxToe - MinToe > 5.0 && MaxHand - MinHand > 6.0);
                    Avatar->VisibilityBasedAnimTickOption = MotionVisibility;
                    Walker->GetCharacterMovement()->StopMovementImmediately();
                    Walker->SetActorTransform(MotionStart, false, nullptr, ETeleportType::TeleportPhysics);
                    CheckVehicleTransfer(Test, *World, *Player, *Walker);
                    if (Route && FParse::Param(FCommandLine::Get(), TEXT("RanwarProfileSmoke")))
                    {
                        CheckSeparateProfile(Test, *World, *Route, *Walker);
                    }
                    return true;
                }
                const FString Speaker = Route ? Route->GetDialogueSpeaker().ToString() : FString();
                if (Route && Speaker != TEXT("Mira") && FPlatformTime::Seconds() < MiraDeadline)
                {
                    return false;
                }
                Test.TestEqual(TEXT("Mira's story lead follows the completed Kavita exchange"), Speaker, FString(TEXT("Mira")));
                if (ClockProbe.IsValid() && !FParse::Param(FCommandLine::Get(), TEXT("RanwarTime")))
                {
                    Test.TestTrue(TEXT("The clock advances naturally during unpaused gameplay"),
                        ClockProbe->GetTimeMinutes() > ClockStart);
                }
                if (Route)
                {
                    CheckDabbaAndLedger(Test, *World, *Route, *Walker, GuideStop);
                }
                if (Walker->GetMetaHumanVisual())
                {
                    MotionStart = Walker->GetActorTransform();
                    const FVector Origin = MotionStart.GetLocation() + FVector(0.0, 0.0, 4.0);
                    const UCapsuleComponent* Capsule = Walker->GetCapsuleComponent();
                    const FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarPlayableGait), false, Walker);
                    for (const FVector& Direction : {FVector::ForwardVector, -FVector::ForwardVector,
                        FVector::RightVector, -FVector::RightVector})
                    {
                        if (!World->SweepTestByChannel(Origin, Origin + Direction * 160.0, FQuat::Identity,
                            Capsule->GetCollisionObjectType(), Capsule->GetCollisionShape(-2.0f), Query))
                        {
                            USkeletalMeshComponent* Avatar = Walker->GetAvatarBody();
                            MotionVisibility = Avatar->VisibilityBasedAnimTickOption;
                            Avatar->VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
                            MotionDirection = Direction;
                            MotionDeadline = FPlatformTime::Seconds() + 1.5;
                            return false;
                        }
                    }
                    Test.AddError(TEXT("Could not find a clear stretch for the Omkar walking test."));
                }
                CheckVehicleTransfer(Test, *World, *Player, *Walker);
                if (Route && FParse::Param(FCommandLine::Get(), TEXT("RanwarProfileSmoke")))
                {
                    CheckSeparateProfile(Test, *World, *Route, *Walker);
                }
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

            Test.TestNotNull(TEXT("Ranwar uses Omkar's active skeletal body"), Walker->GetAvatarBody()->GetSkeletalMeshAsset());
            if (FPackageName::DoesPackageExist(TEXT("/Game/OmkarAssembled/r004/Omkar/BP_Omkar"), nullptr, false))
            {
                const AActor* OmkarVisual = Walker->GetMetaHumanVisual();
                Test.TestTrue(TEXT("Cooked MetaHuman Omkar is active, visible, and collision-free"),
                    IsValid(OmkarVisual) && !OmkarVisual->IsHidden()
                        && !OmkarVisual->GetActorEnableCollision() && OmkarVisual->GetAttachParentActor() == Walker);
                if (IsValid(OmkarVisual))
                {
                    const TInlineComponentArray<USkeletalMeshComponent*> Parts(OmkarVisual);
                    Test.TestTrue(TEXT("MetaHuman Omkar has a visible skinned outfit"),
                        Parts.ContainsByPredicate([](const USkeletalMeshComponent* Part)
                        {
                            const USkeletalMesh* Garment = Part->GetSkeletalMeshAsset();
                            return Garment && Part->IsVisible() && Garment->GetPathName().Contains(TEXT("/Omkar/Clothing/"));
                        }));
                }
            }
            TActorIterator<APlayerStart> Arrival(World);
            Test.TestTrue(TEXT("Omkar spawns by the map's BEST arrival start"),
                Arrival && FVector::DistSquared2D(Arrival->GetActorLocation(), Walker->GetActorLocation())
                    < FMath::Square(175.0));

            Test.TestNotNull(TEXT("Ranwar native game mode is active"), Mode);
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
            Test.TestTrue(TEXT("The map contains the imported BEST coach"), ArrivalAssets.Contains(TEXT("BestBus")));
            if (FPackageName::DoesPackageExist(TEXT("/Game/OmkarAssembled/r005/Omkar/BP_Omkar")))
            {
                TSet<FName> NativeCast;
                int32 NativeWalkers = 0;
                for (TActorIterator<AActor> It(World); It; ++It)
                {
                    const AActor* CastAnchor = *It;
                    const bool bNamed = CastAnchor->ActorHasTag(TEXT("RanwarMetaHumanCast"));
                    const bool bWalker = CastAnchor->ActorHasTag(TEXT("RanwarMetaHumanWalker"));
                    if (!bNamed && !bWalker)
                    {
                        continue;
                    }
                    TArray<AActor*> Attached;
                    CastAnchor->GetAttachedActors(Attached);
                    const AActor* NativeVisual = Attached.IsEmpty() ? nullptr : Attached[0];
                    if (!Test.TestTrue(TEXT("A cast member spawns its visible, attached MetaHuman"),
                        IsValid(NativeVisual) && !NativeVisual->IsHidden()
                        && NativeVisual->GetClass()->GetPathName().StartsWith(TEXT("/Game/OmkarAssembled/"))))
                    {
                        continue;
                    }
                    if (CastAnchor->ActorHasTag(TEXT("RanwarRivalCourier")))
                    {
                        Test.TestTrue(TEXT("Vikram uses the previous Omkar design"),
                            NativeVisual->GetClass()->GetPathName().StartsWith(TEXT("/Game/OmkarAssembled/r004/")));
                    }
                    NativeWalkers += bWalker ? 1 : 0;
                    for (const FName Tag : CastAnchor->Tags)
                    {
                        NativeCast.Add(Tag);
                    }
                }
                for (const TCHAR* Name : {TEXT("Anjali"), TEXT("Vikram"), TEXT("Farah"), TEXT("Nitin"), TEXT("Leena"),
                    TEXT("Iqbal"), TEXT("Asha"), TEXT("ChapelCornerGrocer"), TEXT("Ravi"), TEXT("Kavita")})
                {
                    const FName Tag(*FString::Printf(TEXT("RanwarNPC.%s"), Name));
                    Test.TestTrue(FString::Printf(TEXT("Ranwar contains the native %s"), Name), NativeCast.Contains(Tag));
                }
                Test.TestEqual(TEXT("The three pavement routes use native MetaHumans"), NativeWalkers, 3);
                Test.TestEqual(TEXT("The native cast replaces legacy arrival meshes in the level"), ArrivalAssets.Num(), 1);
            }
            else
            {
                for (const TCHAR* Name : {TEXT("AnjaliKurta"), TEXT("Pedestrian"), TEXT("Farah"), TEXT("Nitin"),
                    TEXT("Leena"), TEXT("Iqbal")})
                {
                    Test.TestTrue(FString::Printf(TEXT("The public map contains the imported %s arrival mesh"), Name),
                        ArrivalAssets.Contains(FName(Name)));
                }
            }

            TActorIterator<ARanwarBus> StopBus(World);
            if (Test.TestTrue(TEXT("St Peter's has an interactive BEST bus"), static_cast<bool>(StopBus)) && Route)
            {
                const FTransform BeforeBus = Walker->GetActorTransform();
                const FVector Door = StopBus->GetBoardingPoint();
                if (Test.TestTrue(TEXT("A player capsule fits on the curb beside the BEST door"),
                    PlaceWalkerOnClearGround(*World, *Walker, Door)))
                {
                    Test.TestFalse(TEXT("Boarding offers an interaction prompt"), Route->GetPrompt(*Walker).IsEmpty());
                    if (Test.TestTrue(TEXT("The curb-side interaction boards the bus"), Route->Interact(*Walker)))
                    {
                        Test.TestTrue(TEXT("Boarding keeps Omkar's controls and activates the passenger camera"),
                            StopBus->IsPassenger(*Walker) && Player->GetPawn() == Walker && Player->GetViewTarget() == *StopBus
                                && Walker->GetCharacterMovement()->MovementMode == MOVE_None);
                        Test.TestTrue(TEXT("The player can use the same interaction to step off"), Route->Interact(*Walker));
                        Test.TestTrue(TEXT("Alighting restores the player camera and collision safely on the curb"),
                            !StopBus->IsPassenger(*Walker) && Player->GetViewTarget() == Walker
                                && Walker->GetActorEnableCollision() && !Walker->IsHidden()
                                && FVector::DistSquared2D(Walker->GetActorLocation(), Door) < FMath::Square(100.0));
                    }
                }
                Walker->SetActorTransform(BeforeBus, false, nullptr, ETeleportType::TeleportPhysics);
            }

            TMap<FName, ARanwarVehicle*> ParkedMeshes;
            for (TActorIterator<ARanwarVehicle> It(World); It; ++It)
            {
                if (const UStaticMesh* Asset = It->GetVehicleMesh()->GetStaticMesh())
                {
                    ParkedMeshes.Add(Asset->GetFName(), *It);
                }
            }
            for (const TCHAR* Family : {TEXT("Hatchback"), TEXT("Rickshaw"), TEXT("Motorcycle"), TEXT("Scooter")})
            {
                const FString DetailPrefix = FString(Family) + TEXT("Vinish");
                const FString ProfilePath = TEXT("/Game/Ranwar/Vehicles/") + DetailPrefix + TEXT("Profile");
                const bool bHasDetailProfile = FPackageName::DoesPackageExist(ProfilePath, nullptr, false);
                const FName ExpectedMesh = bHasDetailProfile ? FName(DetailPrefix + TEXT("Body")) : FName(Family);
                ARanwarVehicle* Parked = ParkedMeshes.FindRef(ExpectedMesh);
                Test.TestTrue(FString::Printf(TEXT("A parked %s uses its imported mesh"), Family),
                    Parked != nullptr);
                if (bHasDetailProfile && Parked)
                {
                    if (FApp::CanEverRender())
                    {
                        const UStaticMesh* Body = Parked->GetVehicleMesh()->GetStaticMesh();
                        Test.TestTrue(FString::Printf(TEXT("The %s body keeps close-range geometry and distance LODs"), Family),
                            Body->GetNumTriangles(0) > 20000 && Body->GetNumLODs() >= 2);
                    }
                    for (const TCHAR* Part : {TEXT("Fork"), TEXT("FrontWheel"), TEXT("RearWheel")})
                    {
                        const auto* Component = Cast<UStaticMeshComponent>(
                            Parked->GetDefaultSubobjectByName(FName(FString(TEXT("Visual")) + Part)));
                        const UStaticMesh* Mesh = Component ? Component->GetStaticMesh() : nullptr;
                        Test.TestTrue(FString::Printf(TEXT("The %s has its separate %s geometry"), Family, Part),
                            Mesh && Mesh->GetFName() == FName(DetailPrefix + Part));
                    }
                }
            }
            const TActorIterator<ARanwarTraffic> Traffic(World);
            Test.TestTrue(TEXT("Map contains its native traffic system"), static_cast<bool>(Traffic));
            if (Traffic)
            {
                Test.TestEqual(TEXT("The pause map shares all four imported road polylines"), Traffic->GetRoads().Num(), 4);
                Test.TestTrue(TEXT("The pause map includes the imported Nagrana Lane footway"), Traffic->GetMapFootway().Num() > 1);
                int32 DrawnSegments = 0;
                RanwarMap::Draw(**Traffic, FVector2D::ZeroVector, FVector2D(400.0, 250.0),
                    Walker->GetActorLocation(), Walker->GetActorForwardVector(), {},
                    [&DrawnSegments](const FVector2D&, const FVector2D&, const FLinearColor&, float)
                    {
                        ++DrawnSegments;
                    }, false);
                Test.TestTrue(TEXT("The normal map projection emits mapped road, lane and player-frame segments"), DrawnSegments > 10);
            }
            Test.TestTrue(TEXT("Between one and four ambient traffic vehicles are active"), CarCount >= 1 && CarCount <= 4);
            Test.TestTrue(TEXT("An ambient vehicle travels along the registered roads"), bTrafficMoved);
            if (FParse::Param(FCommandLine::Get(), TEXT("RanwarClockSmoke")))
            {
                TActorIterator<ARanwarEnvironment> Environment(World);
                if (Test.TestTrue(TEXT("The playable map has a native environment clock"), static_cast<bool>(Environment)))
                {
                    CheckEnvironmentClock(Test, *World, **Environment);
                    ClockProbe = *Environment;
                    ClockStart = Environment->GetTimeMinutes();
                }
            }
            if (Route && CheckParcelRun(Test, *World, *Route, *Walker, GuideStop))
            {
                MiraDeadline = FPlatformTime::Seconds() + 25.0;
                return false;
            }
            return true;
        }

    private:
        FAutomationTestBase& Test;
        const double Deadline;
        double MiraDeadline = 0.0;
        double MotionDeadline = 0.0;
        bool bMotionPhotoRequested = false;
        EVisibilityBasedAnimTickOption MotionVisibility = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
        FTransform MotionStart;
        FVector MotionDirection = FVector::ZeroVector;
        double MinToe = TNumericLimits<double>::Max();
        double MaxToe = TNumericLimits<double>::Lowest();
        double MinHand = TNumericLimits<double>::Max();
        double MaxHand = TNumericLimits<double>::Lowest();
        FVector GuideStop = FVector::ZeroVector;
        TWeakObjectPtr<ARanwarTrafficCar> TrackedCar;
        TWeakObjectPtr<ARanwarEnvironment> ClockProbe;
        double ClockStart = 0.0;
        FVector TrafficOrigin = FVector::ZeroVector;
    };

    class FCheckRanwarVoicedArrival final : public IAutomationLatentCommand
    {
    public:
        explicit FCheckRanwarVoicedArrival(FAutomationTestBase& InTest)
            : Test(InTest), Deadline(FPlatformTime::Seconds() + 12.0)
        {
        }

        bool Update() override
        {
            UWorld* World = GetRanwarGameWorld();
            APlayerController* Player = World ? World->GetFirstPlayerController() : nullptr;
            ARanwarCharacter* Walker = Player ? Cast<ARanwarCharacter>(Player->GetPawn()) : nullptr;
            ARanwarGameMode* Mode = World ? World->GetAuthGameMode<ARanwarGameMode>() : nullptr;
            ARanwarRoute* Route = Mode ? Mode->GetRoute() : nullptr;
            if (!Walker || !Route)
            {
                if (FPlatformTime::Seconds() < Deadline)
                {
                    return false;
                }
                Test.AddError(TEXT("The voiced arrival could not load Ranwar."));
                return true;
            }
            FVector Stop;
            if (Test.TestTrue(TEXT("Anjali speaks from the arrival stop"),
                !Route->HasSavedProgress() && Route->GetWaypoint(Stop) && InteractNear(*World, *Route, *Walker, Stop)))
            {
                Test.TestEqual(TEXT("The voice subtitle identifies Anjali"), Route->GetDialogueSpeaker().ToString(), FString(TEXT("Anjali")));
                Test.TestFalse(TEXT("The subtitle is readable even with sound disabled"), Route->GetDialogueText().IsEmpty());
                if (FParse::Param(FCommandLine::Get(), TEXT("RanwarCaptureDialogue")))
                {
                    const FVector CameraSide = Stop - Walker->GetActorForwardVector() * 110.0
                        + Walker->GetActorRightVector() * 55.0;
                    if (PlaceWalkerOnClearGround(*World, *Walker, CameraSide))
                    {
                        FRotator View = (Stop - Walker->GetActorLocation()).Rotation();
                        View.Pitch = -8.0;
                        Player->SetControlRotation(View);
                    }
                    FScreenshotRequest::RequestScreenshot(true);
                }
            }
            return true;
        }

    private:
        FAutomationTestBase& Test;
        const double Deadline;
    };
    bool IsFreshSmokeProfile()
    {
        FString UserDir;
        FParse::Value(FCommandLine::Get(), TEXT("UserDir="), UserDir);
        const FString Saved = FPaths::ConvertRelativePathToFull(FPaths::ProjectSavedDir());
        return !UserDir.IsEmpty() && !FPaths::IsRelative(UserDir) && FPaths::IsUnderDirectory(Saved, UserDir)
            && !UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProgress0"), 0)
            && !UGameplayStatics::DoesSaveGameExist(TEXT("RanwarProgress1"), 0);
    }
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FRanwarPlayableSmoke, "AamchiMumbai.Ranwar.Playable",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::ProductFilter)

bool FRanwarPlayableSmoke::RunTest(const FString&)
{
    if (!IsFreshSmokeProfile())
    {
        AddError(TEXT("Run the Ranwar smoke test with -UserDir pointing to a fresh absolute scratch directory."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FCheckRanwarPlayable(*this));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FRanwarRiderPhoto, "AamchiMumbai.Ranwar.RiderPhoto",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::ProductFilter)

bool FRanwarRiderPhoto::RunTest(const FString&)
{
    FString Selection;
    FParse::Value(FCommandLine::Get(), TEXT("RanwarRiderPhoto="), Selection);
    if (!IsFreshSmokeProfile() || !FApp::CanEverRender() || (Selection != TEXT("Motorcycle") && Selection != TEXT("Scooter")))
    {
        AddError(TEXT("Use a rendered launch with a fresh -UserDir and -RanwarRiderPhoto=Motorcycle or Scooter."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FCheckRanwarRiderPhoto(*this, FName(Selection + TEXT("VinishBody"))));
    return true;
}

IMPLEMENT_SIMPLE_AUTOMATION_TEST(FRanwarVoicedArrivalSmoke, "AamchiMumbai.Ranwar.VoicedArrival",
    EAutomationTestFlags::ClientContext | EAutomationTestFlags::ProductFilter)

bool FRanwarVoicedArrivalSmoke::RunTest(const FString&)
{
    if (!IsFreshSmokeProfile())
    {
        AddError(TEXT("Run the voiced arrival smoke test with -UserDir pointing to a fresh absolute scratch directory."));
        return false;
    }
    ADD_LATENT_AUTOMATION_COMMAND(FCheckRanwarVoicedArrival(*this));
    return true;
}

#endif
