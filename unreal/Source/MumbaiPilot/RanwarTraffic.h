#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RanwarTraffic.generated.h"

class APlayerController;
class UBoxComponent;
class UPoseableMeshComponent;
class USkeletalMesh;
class UStaticMesh;
class UStaticMeshComponent;

USTRUCT(BlueprintType)
struct MUMBAIPILOT_API FRanwarTrafficRoad
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, Category = "Traffic")
    TArray<FVector> Points;

    UPROPERTY(EditAnywhere, Category = "Traffic", meta = (ClampMin = "0.0", Units = "cm"))
    double Width = 800.0;

    // Bit 1 permits the input direction, bit 2 permits its reverse.
    UPROPERTY(EditAnywhere, Category = "Traffic", meta = (ClampMin = "1", ClampMax = "3"))
    int32 Directions = 3;
};

UCLASS()
class MUMBAIPILOT_API ARanwarTrafficCar : public AActor
{
    GENERATED_BODY()

public:
    ARanwarTrafficCar();
    void Configure(UStaticMesh* Vehicle, USkeletalMesh* Driver, bool bRickshaw);
    double GetRideHeight() const;

private:
    UPROPERTY()
    TObjectPtr<UBoxComponent> Chassis;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> Body;

    UPROPERTY()
    TObjectPtr<UPoseableMeshComponent> SeatedDriver;
};

UCLASS()
class MUMBAIPILOT_API ARanwarTraffic : public AActor
{
    GENERATED_BODY()

public:
    ARanwarTraffic();
    const TArray<FRanwarTrafficRoad>& GetRoads() const { return Roads; }
    const TArray<FVector>& GetMapFootway() const { return MapFootway; }

protected:
    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;

private:
    struct FTrafficState
    {
        TWeakObjectPtr<ARanwarTrafficCar> Car;
        double Distance = 0.0;
        double Speed = 0.0;
        double StoppedSeconds = 0.0;
    };

    bool BuildRoute();
    void RefreshPopulation(const APlayerController& Player);
    void Advance(FTrafficState& State, double DeltaSeconds);
    FVector PositionAt(double Distance) const;
    FVector DirectionAt(double Distance) const;
    double ClosestDistance(const FVector& Position) const;
    double WrapDistance(double Distance) const;

    // These points are already registered to the imported Ranwar mesh in world centimetres.
    UPROPERTY(EditAnywhere, Category = "Traffic")
    TArray<FRanwarTrafficRoad> Roads;

    UPROPERTY(EditAnywhere, Category = "Map")
    TArray<FVector> MapFootway;

    UPROPERTY(EditAnywhere, Category = "Traffic", meta = (ClampMin = "0", ClampMax = "4"))
    int32 CivilianLimit = 4;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> HatchbackMesh;

    UPROPERTY(Transient)
    TObjectPtr<UStaticMesh> RickshawMesh;

    UPROPERTY(Transient)
    TObjectPtr<USkeletalMesh> DriverMesh;

    TArray<FVector> Route;
    TArray<double> Distances;
    TArray<FTrafficState> ActiveCars;
    double RefreshTime = 0.0;
    int32 SpawnCount = 0;
};
