#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RanwarEnvironment.generated.h"

class ADirectionalLight;
class AExponentialHeightFog;
class ALight;
class APostProcessVolume;
class ASkyLight;
class AStaticMeshActor;
class UInstancedStaticMeshComponent;
class UMaterialInstanceDynamic;
class UStaticMeshComponent;

UCLASS()
class MUMBAIPILOT_API ARanwarEnvironment : public AActor
{
    GENERATED_BODY()

public:
    ARanwarEnvironment();
    static APostProcessVolume* CreateExposure(UWorld& World);
    double GetTimeMinutes() const { return Minutes; }
    void SetTimeMinutes(double Value);

protected:
    void BeginPlay() override;
    void Tick(float DeltaSeconds) override;

private:
    void ApplyEnvironment();

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TObjectPtr<ADirectionalLight> Sun;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TObjectPtr<ADirectionalLight> MoonFill;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TObjectPtr<ASkyLight> Sky;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TObjectPtr<AExponentialHeightFog> Haze;

    UPROPERTY(Transient)
    TObjectPtr<APostProcessVolume> Exposure;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TArray<TObjectPtr<ALight>> Streets;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TArray<TObjectPtr<ALight>> Interiors;

    UPROPERTY(EditAnywhere, Category = "Ranwar sky")
    TArray<TObjectPtr<AStaticMeshActor>> LampLenses;

    UPROPERTY(VisibleAnywhere, Category = "Ranwar sky")
    TObjectPtr<UStaticMeshComponent> CloudLayer;

    UPROPERTY(VisibleAnywhere, Category = "Ranwar sky")
    TObjectPtr<UInstancedStaticMeshComponent> DistantBuildings;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> CloudFinish;

    UPROPERTY(Transient)
    TObjectPtr<UMaterialInstanceDynamic> LampLensFinish;

    TArray<float> StreetPeak;
    TArray<float> InnerPeak;
    double Minutes = 630.0;
    bool bAdvanceClock = true;
};
