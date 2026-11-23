#include "RanwarTraffic.h"

#include "Algo/Reverse.h"
#include "CollisionQueryParams.h"
#include "CollisionShape.h"
#include "Components/BoxComponent.h"
#include "Components/PoseableMeshComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/CollisionProfile.h"
#include "Engine/SkeletalMesh.h"
#include "Engine/StaticMesh.h"
#include "Engine/World.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "Misc/PackageName.h"
#include "ReferenceSkeleton.h"

namespace
{
    constexpr double GroundClearance = 26.0;
    constexpr double FollowGap = 150.0;
    constexpr double BrakeRate = 820.0;
    constexpr double CruiseSpeed = 550.0;
    constexpr double CornerSpeed = 260.0;
    constexpr double JunctionTolerance = 2.0;
    constexpr double SpawnGap = 2400.0;
    constexpr double ActiveRadius = 19500.0;

    FVector TrafficExtent(bool bRickshaw)
    {
        return bRickshaw ? FVector(134.0, 64.0, 76.0) : FVector(187.0, 82.0, 62.0);
    }

    struct FLane
    {
        int32 Road = INDEX_NONE;
        FVector From = FVector::ZeroVector;
        FVector To = FVector::ZeroVector;
        TArray<FVector> Points;
    };

    FVector DriveLeft(const FVector& Direction)
    {
        // Unreal uses +Y for the right side of a vehicle facing +X.
        return FVector::CrossProduct(Direction, FVector::UpVector);
    }

    FLane BuildLane(int32 RoadIndex, TArray<FVector> Centerline, double Width, bool bReverse)
    {
        if (bReverse)
        {
            Algo::Reverse(Centerline);
        }
        FLane Lane;
        Lane.Road = RoadIndex;
        Lane.From = Centerline[0];
        Lane.To = Centerline.Last();
        const double Offset = Width * 0.25;
        const FVector First = Centerline[1] - Lane.From;
        const FVector Last = Lane.To - Centerline[Centerline.Num() - 2];
        const double FirstInset = FMath::Min(Width * 0.4, First.Size2D() * 0.25);
        const double LastInset = FMath::Min(Width * 0.4, Last.Size2D() * 0.25);
        Lane.Points.Add(Lane.From + First.GetSafeNormal2D() * FirstInset
            + DriveLeft(First.GetSafeNormal2D()) * Offset);
        for (int32 Index = 1; Index + 1 < Centerline.Num(); ++Index)
        {
            const FVector Incoming = (Centerline[Index] - Centerline[Index - 1]).GetSafeNormal2D();
            const FVector Outgoing = (Centerline[Index + 1] - Centerline[Index]).GetSafeNormal2D();
            const FVector Bisector = (DriveLeft(Incoming) + DriveLeft(Outgoing)).GetSafeNormal2D();
            const double Miter = Offset / FMath::Max(0.7, FVector::DotProduct(Bisector, DriveLeft(Incoming)));
            Lane.Points.Add(Centerline[Index] + Bisector * Miter);
        }
        Lane.Points.Add(Lane.To - Last.GetSafeNormal2D() * LastInset + DriveLeft(Last.GetSafeNormal2D()) * Offset);
        return Lane;
    }

    TArray<int32> FindCycle(const TArray<FLane>& Lanes, int32 Start)
    {
        TArray<int32> Parents;
        Parents.Init(INDEX_NONE, Lanes.Num());
        Parents[Start] = Start;
        TArray<int32> Queue{Start};
        for (int32 Head = 0; Head < Queue.Num(); ++Head)
        {
            const int32 Current = Queue[Head];
            for (int32 Next = 0; Next < Lanes.Num(); ++Next)
            {
                if (Lanes[Next].Road == Lanes[Current].Road
                    || !Lanes[Current].To.Equals(Lanes[Next].From, JunctionTolerance))
                {
                    continue;
                }
                if (Next == Start)
                {
                    TArray<int32> Cycle{Current};
                    for (int32 Parent = Parents[Current]; Parent != Start; Parent = Parents[Parent])
                    {
                        Cycle.Add(Parent);
                    }
                    Cycle.Add(Start);
                    Algo::Reverse(Cycle);
                    return Cycle;
                }
                if (Parents[Next] == INDEX_NONE)
                {
                    Parents[Next] = Current;
                    Queue.Add(Next);
                }
            }
        }
        return {};
    }

    void AppendTurn(TArray<FVector>& Route, const FLane& Incoming, const FLane& Outgoing)
    {
        const FVector Start = Incoming.Points.Last();
        const FVector End = Outgoing.Points[0];
        const double Span = FVector::Dist2D(Start, End) * 0.4;
        const FVector ControlA = Start + (Start - Incoming.Points[Incoming.Points.Num() - 2]).GetSafeNormal2D() * Span;
        const FVector ControlB = End - (Outgoing.Points[1] - End).GetSafeNormal2D() * Span;
        for (int32 Index = 1; Index < 8; ++Index)
        {
            const double T = Index / 8.0;
            const double U = 1.0 - T;
            Route.Add(Start * U * U * U + ControlA * 3.0 * U * U * T
                + ControlB * 3.0 * U * T * T + End * T * T * T);
        }
    }

    template <typename AssetType>
    AssetType* LoadTrafficAsset(const TCHAR* Package, const TCHAR* Name)
    {
        return FPackageName::DoesPackageExist(Package, nullptr, false)
            ? LoadObject<AssetType>(nullptr, *FString::Printf(TEXT("%s.%s"), Package, Name)) : nullptr;
    }

    FTransform ComponentPose(const FReferenceSkeleton& Skeleton, const TArray<FTransform>& Pose, int32 Bone)
    {
        FTransform Result = FTransform::Identity;
        for (int32 Index = Bone; Index != INDEX_NONE; Index = Skeleton.GetParentIndex(Index))
        {
            Result *= Pose[Index];
        }
        return Result;
    }

    void ApplyDriverPose(UPoseableMeshComponent& Rider, USkeletalMesh& Mesh, bool bRickshaw)
    {
        const FReferenceSkeleton& Skeleton = Mesh.GetRefSkeleton();
        const int32 Hips = Skeleton.FindBoneIndex(TEXT("Hips"));
        const int32 Foot = Skeleton.FindBoneIndex(TEXT("LeftFoot"));
        const int32 Toes = Skeleton.FindBoneIndex(TEXT("LeftToes"));
        if (Hips == INDEX_NONE || Foot == INDEX_NONE || Toes == INDEX_NONE)
        {
            return;
        }
        Rider.SetSkinnedAssetAndUpdate(&Mesh, true);
        TArray<FTransform>& Pose = Rider.BoneSpaceTransforms;
        Pose = Skeleton.GetRefBonePose();
        const FVector Forward = (ComponentPose(Skeleton, Pose, Toes).GetLocation()
            - ComponentPose(Skeleton, Pose, Foot).GetLocation()).GetSafeNormal2D();
        if (Forward.IsNearlyZero())
        {
            return;
        }
        const FQuat Facing(FVector::UpVector, -FMath::Atan2(Forward.Y, Forward.X));
        const double Scale = bRickshaw ? 0.84 : 0.72;
        const FVector Seat = bRickshaw ? FVector(18.5, 0.0, 74.5) : FVector(5.0, 35.0, 99.0);
        Rider.SetRelativeRotation(Facing);
        Rider.SetRelativeScale3D(FVector(Scale));
        Rider.SetRelativeLocation(Seat - Facing.RotateVector(ComponentPose(Skeleton, Pose, Hips).GetLocation() * Scale));

        const auto Aim = [&Skeleton, &Pose, &Facing](FName Bone, FName Child, const FVector& Direction)
        {
            const int32 BoneIndex = Skeleton.FindBoneIndex(Bone);
            const int32 ChildIndex = Skeleton.FindBoneIndex(Child);
            if (BoneIndex == INDEX_NONE || ChildIndex == INDEX_NONE || Skeleton.GetParentIndex(ChildIndex) != BoneIndex)
            {
                return;
            }
            const FTransform Current = ComponentPose(Skeleton, Pose, BoneIndex);
            const FQuat Parent = ComponentPose(Skeleton, Pose, Skeleton.GetParentIndex(BoneIndex)).GetRotation();
            const FVector CurrentDirection = Current.TransformVectorNoScale(Pose[ChildIndex].GetTranslation()).GetSafeNormal();
            const FQuat Turn = FQuat::FindBetweenNormals(CurrentDirection, Facing.UnrotateVector(Direction.GetSafeNormal()));
            Pose[BoneIndex].SetRotation((Parent.Inverse() * Turn * Current.GetRotation()).GetNormalized());
        };
        Aim(TEXT("LeftUpperLeg"), TEXT("LeftLowerLeg"), FVector(1.0, -0.22, -0.14));
        Aim(TEXT("RightUpperLeg"), TEXT("RightLowerLeg"), FVector(1.0, 0.22, -0.14));
        Aim(TEXT("LeftLowerLeg"), TEXT("LeftFoot"), FVector(0.2, 0.04, -1.0));
        Aim(TEXT("RightLowerLeg"), TEXT("RightFoot"), FVector(0.2, -0.04, -1.0));
        Aim(TEXT("LeftUpperArm"), TEXT("LeftLowerArm"), FVector(0.65, -0.35, -0.75));
        Aim(TEXT("RightUpperArm"), TEXT("RightLowerArm"), FVector(0.65, 0.35, -0.75));
        Aim(TEXT("LeftLowerArm"), TEXT("LeftHand"), FVector(1.0, 0.42, 0.35));
        Aim(TEXT("RightLowerArm"), TEXT("RightHand"), FVector(1.0, -0.42, 0.35));
        Rider.MarkRefreshTransformDirty();
        Rider.SetVisibility(true);
    }
}

ARanwarTrafficCar::ARanwarTrafficCar()
{
    Chassis = CreateDefaultSubobject<UBoxComponent>(TEXT("Chassis"));
    SetRootComponent(Chassis);
    Chassis->InitBoxExtent(TrafficExtent(false));
    Chassis->SetCollisionProfileName(UCollisionProfile::BlockAllDynamic_ProfileName);
    Chassis->SetCollisionEnabled(ECollisionEnabled::QueryOnly);
    Chassis->SetGenerateOverlapEvents(false);

    Body = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("VehicleBody"));
    Body->SetupAttachment(Chassis);
    Body->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SeatedDriver = CreateDefaultSubobject<UPoseableMeshComponent>(TEXT("SeatedDriver"));
    SeatedDriver->SetupAttachment(Body);
    SeatedDriver->SetCollisionEnabled(ECollisionEnabled::NoCollision);
    SeatedDriver->SetVisibility(false);
}

void ARanwarTrafficCar::Configure(UStaticMesh* Vehicle, USkeletalMesh* Driver, bool bRickshaw)
{
    Chassis->SetBoxExtent(TrafficExtent(bRickshaw));
    Body->SetStaticMesh(Vehicle);
    Body->SetRelativeLocation(FVector(0.0, 0.0, -GetRideHeight()));
    if (Driver)
    {
        ApplyDriverPose(*SeatedDriver, *Driver, bRickshaw);
    }
}

double ARanwarTrafficCar::GetRideHeight() const
{
    return Chassis->GetScaledBoxExtent().Z + GroundClearance;
}

ARanwarTraffic::ARanwarTraffic()
{
    PrimaryActorTick.bCanEverTick = true;
}

void ARanwarTraffic::BeginPlay()
{
    Super::BeginPlay();
    HatchbackMesh = LoadTrafficAsset<UStaticMesh>(TEXT("/Game/Ranwar/Vehicles/Hatchback"), TEXT("Hatchback"));
    RickshawMesh = LoadTrafficAsset<UStaticMesh>(TEXT("/Game/Ranwar/Vehicles/Rickshaw"), TEXT("Rickshaw"));
    DriverMesh = LoadTrafficAsset<USkeletalMesh>(TEXT("/Game/Ranwar/Characters/Omkar/Omkar"), TEXT("Omkar"));
    if (CivilianLimit <= 0 || !(HatchbackMesh || RickshawMesh) || !BuildRoute())
    {
        SetActorTickEnabled(false);
    }
}

bool ARanwarTraffic::BuildRoute()
{
    TArray<FLane> Lanes;
    if (Roads.Num() > 24)
    {
        return false;
    }
    for (int32 Index = 0; Index < Roads.Num(); ++Index)
    {
        const FRanwarTrafficRoad& Road = Roads[Index];
        if (!FMath::IsFinite(Road.Width) || Road.Width < 340.0 || Road.Width > 2400.0
            || Road.Points.Num() < 2 || Road.Points.Num() > 64)
        {
            return false;
        }
        TArray<FVector> Centerline;
        for (const FVector& Point : Road.Points)
        {
            if (Point.ContainsNaN())
            {
                return false;
            }
            if (Centerline.IsEmpty() || FVector::DistSquared2D(Point, Centerline.Last()) > 1.0)
            {
                Centerline.Add(Point);
            }
        }
        if (Centerline.Num() < 2)
        {
            return false;
        }
        if ((Road.Directions & 1) != 0)
        {
            Lanes.Add(BuildLane(Index, Centerline, Road.Width, false));
        }
        if ((Road.Directions & 2) != 0)
        {
            Lanes.Add(BuildLane(Index, Centerline, Road.Width, true));
        }
    }
    TArray<int32> Cycle;
    // This prefers the recorded West Waroda departure, then finds any valid directed circuit.
    for (int32 Start = Lanes.Num() - 1; Start >= 0 && Cycle.IsEmpty(); --Start)
    {
        Cycle = FindCycle(Lanes, Start);
    }
    if (Cycle.IsEmpty())
    {
        UE_LOG(LogTemp, Warning, TEXT("Ranwar traffic could not connect the registered roads into a directed loop."));
        return false;
    }
    for (int32 Index = 0; Index < Cycle.Num(); ++Index)
    {
        const FLane& Lane = Lanes[Cycle[Index]];
        Route.Append(Lane.Points);
        AppendTurn(Route, Lane, Lanes[Cycle[(Index + 1) % Cycle.Num()]]);
    }
    const FVector RouteStart = Route[0];
    Route.Add(RouteStart);
    double Length = 0.0;
    Distances.Add(Length);
    for (int32 Index = 1; Index < Route.Num(); ++Index)
    {
        Length += FVector::Dist2D(Route[Index - 1], Route[Index]);
        Distances.Add(Length);
    }
    UE_LOG(LogTemp, Display, TEXT("Ranwar traffic registered a %.0f m directed left-hand circuit."), Length * 0.01);
    return Length >= SpawnGap * 2.0;
}

void ARanwarTraffic::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    RefreshTime -= DeltaSeconds;
    if (RefreshTime <= 0.0)
    {
        RefreshTime = 0.7;
        if (const APlayerController* Player = GetWorld()->GetFirstPlayerController())
        {
            if (Player->IsLocalController() && Player->GetPawn())
            {
                RefreshPopulation(*Player);
            }
        }
    }
    const double Step = FMath::Min(static_cast<double>(DeltaSeconds), 0.05);
    for (FTrafficState& State : ActiveCars)
    {
        if (State.Car.IsValid())
        {
            Advance(State, Step);
        }
    }
}

void ARanwarTraffic::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    if (EndPlayReason == EEndPlayReason::Destroyed || EndPlayReason == EEndPlayReason::RemovedFromWorld)
    {
        for (FTrafficState& State : ActiveCars)
        {
            if (ARanwarTrafficCar* Car = State.Car.Get())
            {
                Car->Destroy();
            }
        }
    }
    Super::EndPlay(EndPlayReason);
}

void ARanwarTraffic::RefreshPopulation(const APlayerController& Player)
{
    const FVector PawnPosition = Player.GetPawn()->GetActorLocation();
    FVector CameraLocation;
    FRotator CameraRotation;
    Player.GetPlayerViewPoint(CameraLocation, CameraRotation);
    const FVector CameraDirection = CameraRotation.Vector();
    const auto Visible = [&CameraLocation, &CameraDirection](const FVector& Point)
    {
        return FVector::DotProduct((Point - CameraLocation).GetSafeNormal(), CameraDirection) > 0.60;
    };
    for (int32 Index = ActiveCars.Num() - 1; Index >= 0; --Index)
    {
        FTrafficState& State = ActiveCars[Index];
        ARanwarTrafficCar* Car = State.Car.Get();
        if (Car)
        {
            const FVector Position = Car->GetActorLocation();
            const double Range = FVector::DistSquared2D(PawnPosition, Position);
            const bool bStalled = State.StoppedSeconds > 10.0 && Range > FMath::Square(5200.0);
            if ((Range > FMath::Square(ActiveRadius) || bStalled) && !Visible(Position))
            {
                Car->Destroy();
                Car = nullptr;
            }
        }
        if (!Car)
        {
            ActiveCars.RemoveAtSwap(Index);
        }
    }
    if (ActiveCars.Num() >= FMath::Clamp(CivilianLimit, 0, 4))
    {
        return;
    }

    const bool bRickshaw = RickshawMesh && (SpawnCount % 3 == 1 || !HatchbackMesh);
    UStaticMesh* Mesh = bRickshaw ? RickshawMesh.Get() : HatchbackMesh.Get();
    const FVector Extent = TrafficExtent(bRickshaw);
    const double NearDistance = ClosestDistance(PawnPosition);
    constexpr double SpawnOffsets[] = {4400.0, -4800.0, -7100.0, 7300.0, -9800.0, 10400.0, 13000.0, -13400.0};
    for (const double Offset : SpawnOffsets)
    {
        const double Distance = WrapDistance(NearDistance + Offset);
        const FVector Location = PositionAt(Distance) + FVector(0.0, 0.0, Extent.Z + GroundClearance);
        const double Range = FVector::DistSquared2D(PawnPosition, Location);
        if (Range < FMath::Square(2600.0) || Range > FMath::Square(14800.0)
            || (Visible(Location) && (SpawnCount > 0 || Range < FMath::Square(6000.0))))
        {
            continue;
        }
        const bool bSpacing = !ActiveCars.ContainsByPredicate([&Location](const FTrafficState& Traffic)
        {
            const ARanwarTrafficCar* Other = Traffic.Car.Get();
            return Other && FVector::DistSquared2D(Other->GetActorLocation(), Location) < FMath::Square(SpawnGap);
        });
        const FRotator Heading = DirectionAt(Distance).Rotation();
        const FCollisionQueryParams SpawnQuery(SCENE_QUERY_STAT(RanwarTrafficSpawn), false);
        if (!bSpacing || GetWorld()->OverlapBlockingTestByProfile(
            Location, Heading.Quaternion(), UCollisionProfile::BlockAllDynamic_ProfileName,
            FCollisionShape::MakeBox(Extent), SpawnQuery))
        {
            continue;
        }
        FActorSpawnParameters Parameters;
        Parameters.Owner = this;
        Parameters.SpawnCollisionHandlingOverride = ESpawnActorCollisionHandlingMethod::AlwaysSpawn;
        if (ARanwarTrafficCar* Car = GetWorld()->SpawnActor<ARanwarTrafficCar>(Location, Heading, Parameters))
        {
            Car->Configure(Mesh, DriverMesh.Get(), bRickshaw);
            ActiveCars.Add({Car, Distance, 0.0, 0.0});
            ++SpawnCount;
        }
        return;
    }
}

void ARanwarTraffic::Advance(FTrafficState& State, double DeltaSeconds)
{
    ARanwarTrafficCar* Car = State.Car.Get();
    const FVector Origin = Car->GetActorLocation();
    const FVector Rise(0.0, 0.0, Car->GetRideHeight());
    const FVector Direction = DirectionAt(State.Distance);
    const FVector NextDirection = DirectionAt(State.Distance + 500.0);
    const double Dot = FVector::DotProduct(Direction, NextDirection);
    double Target = FMath::GetMappedRangeValueClamped(FVector2D(0.84, 0.985), FVector2D(CornerSpeed, CruiseSpeed), Dot);
    const UBoxComponent* Chassis = CastChecked<UBoxComponent>(Car->GetRootComponent());
    const FVector Size = Chassis->GetScaledBoxExtent();
    const ECollisionChannel Channel = Chassis->GetCollisionObjectType();
    const FCollisionResponseParams Responses(Chassis->GetCollisionResponseToChannels());
    const FCollisionQueryParams Query(SCENE_QUERY_STAT(RanwarTrafficAhead), false, Car);
    const double LookAhead = FollowGap + FMath::Square(State.Speed) / (2.0 * BrakeRate) + 75.0;
    const FCollisionShape Sensor = FCollisionShape::MakeBox(FVector(Size.X, Size.Y + 14.0, Size.Z * 0.80));
    FHitResult Ahead;
    if (GetWorld()->SweepSingleByChannel(Ahead, Origin, PositionAt(State.Distance + LookAhead) + Rise,
        Car->GetActorQuat(), Channel, Sensor, Query, Responses))
    {
        const double Remaining = FMath::Max(0.0, Ahead.Distance - FollowGap);
        Target = FMath::Min(Target, FMath::Sqrt(2.0 * BrakeRate * Remaining));
    }
    State.Speed = FMath::FInterpConstantTo(State.Speed, Target, DeltaSeconds, Target < State.Speed ? BrakeRate : 380.0);
    if (State.Speed < 3.0)
    {
        State.StoppedSeconds += DeltaSeconds;
        return;
    }
    const double Travel = State.Speed * DeltaSeconds;
    const double NextDistance = WrapDistance(State.Distance + Travel);
    const FRotator Heading = DirectionAt(NextDistance).Rotation();
    const FCollisionShape Footprint = FCollisionShape::MakeBox(Size - FVector(1.0));
    if (GetWorld()->OverlapBlockingTestByChannel(Origin, Heading.Quaternion(), Channel, Footprint, Query, Responses))
    {
        State.Speed = 0.0;
        State.StoppedSeconds += DeltaSeconds;
        return;
    }
    FHitResult Hit;
    Car->SetActorLocationAndRotation(PositionAt(NextDistance) + Rise, Heading, true, &Hit);
    if (Hit.bBlockingHit)
    {
        State.Distance = WrapDistance(State.Distance + Travel * Hit.Time);
        State.Speed = 0.0;
        State.StoppedSeconds += DeltaSeconds;
        return;
    }
    State.Distance = NextDistance;
    State.StoppedSeconds = 0.0;
}

double ARanwarTraffic::WrapDistance(double Distance) const
{
    const double Length = Distances.Last();
    const double Wrapped = FMath::Fmod(Distance, Length);
    return Wrapped < 0.0 ? Wrapped + Length : Wrapped;
}

FVector ARanwarTraffic::PositionAt(double Distance) const
{
    const double Wrapped = WrapDistance(Distance);
    for (int32 Index = 1; Index < Distances.Num(); ++Index)
    {
        if (Wrapped < Distances[Index])
        {
            const double Span = Distances[Index] - Distances[Index - 1];
            const double Alpha = (Wrapped - Distances[Index - 1]) / Span;
            return FMath::Lerp(Route[Index - 1], Route[Index], Alpha);
        }
    }
    return Route[0];
}

FVector ARanwarTraffic::DirectionAt(double Distance) const
{
    return (PositionAt(Distance + 150.0) - PositionAt(Distance - 150.0)).GetSafeNormal2D();
}

double ARanwarTraffic::ClosestDistance(const FVector& Position) const
{
    double Closest = 0.0;
    double Best = TNumericLimits<double>::Max();
    for (int32 Index = 1; Index < Route.Num(); ++Index)
    {
        const FVector& Start = Route[Index - 1];
        const FVector2D Delta(Route[Index] - Start);
        const double Span = Delta.SizeSquared();
        if (Span <= UE_SMALL_NUMBER)
        {
            continue;
        }
        const double T = FMath::Clamp(FVector2D::DotProduct(FVector2D(Position - Start), Delta) / Span, 0.0, 1.0);
        const double Range = FVector::DistSquared2D(Position, FMath::Lerp(Start, Route[Index], T));
        if (Range < Best)
        {
            Best = Range;
            Closest = FMath::Lerp(Distances[Index - 1], Distances[Index], T);
        }
    }
    return Closest;
}
