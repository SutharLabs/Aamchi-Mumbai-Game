#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RanwarAmbientPedestrian.generated.h"

class UAnimSequence;
class UCapsuleComponent;
class USkeletalMeshComponent;

namespace RanwarCast
{
    USkeletalMeshComponent* SpawnGroundedMetaHuman(AActor& Owner, TSubclassOf<AActor> ActorClass,
        int32 MinimumLOD, float ZOffset = 0.0f, float YawOffset = 0.0f, FVector* PoseForward = nullptr);
}

UCLASS()
class MUMBAIPILOT_API ARanwarAmbientPedestrian : public AActor
{
    GENERATED_BODY()

public:
    ARanwarAmbientPedestrian();

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Pedestrian")
    TObjectPtr<USkeletalMeshComponent> SkeletalMesh;

    UPROPERTY(EditAnywhere, Category = "Pedestrian")
    TSubclassOf<AActor> MetaHumanClass;

    // World-space feet positions supplied by the map's grounded sidewalk placement.
    UPROPERTY(EditAnywhere, Category = "Pedestrian")
    TArray<FVector> PathPoints;

    UPROPERTY(EditAnywhere, Category = "Pedestrian")
    TObjectPtr<UAnimSequence> WalkAnimation;

    UPROPERTY(EditAnywhere, Category = "Pedestrian")
    TObjectPtr<UAnimSequence> IdleAnimation;

    UPROPERTY(EditAnywhere, Category = "Pedestrian")
    bool bBlocksPassage = false;

    UPROPERTY(EditAnywhere, Category = "Pedestrian", meta = (ClampMin = "30.0", ClampMax = "180.0", Units = "cm/s"))
    float WalkSpeed = 98.0f;

    UPROPERTY(EditAnywhere, Category = "Pedestrian", meta = (ClampMin = "1.0", Units = "cm/s"))
    float WalkClipSpeed = 98.0f;

    // Fraction of the authored route length measured from the first waypoint.
    UPROPERTY(EditAnywhere, Category = "Pedestrian", meta = (ClampMin = "0.0", ClampMax = "1.0"))
    float InitialProgress = 0.0f;

    UPROPERTY(EditAnywhere, Category = "Pedestrian", meta = (Units = "cm"))
    float MeshZOffset = 0.0f;

    UPROPERTY(EditAnywhere, Category = "Pedestrian", meta = (Units = "Degrees"))
    float MeshYawOffset = 0.0f;

protected:
    virtual void BeginPlay() override;
    virtual void EndPlay(EEndPlayReason::Type EndPlayReason) override;
    virtual void Tick(float DeltaSeconds) override;

private:
    bool CachePathDistances();
    bool LoadVisual();
    void TurnTowards(double TargetYaw, float DeltaSeconds);
    int32 GetPathSegment() const;
    void PresentMovement(double Traveled, float DeltaSeconds);

    UPROPERTY(Transient)
    TObjectPtr<AActor> MetaHumanVisual;

    UPROPERTY(Transient)
    TObjectPtr<USkeletalMeshComponent> Body;

    UPROPERTY(VisibleAnywhere, Category = "Pedestrian")
    TObjectPtr<UCapsuleComponent> PassageCollider;

    TArray<double> PathDistances;
    FVector PoseForward = FVector::ForwardVector;
    double TravelDistance = 0.0;
    double WalkPosition = 0.0;
    double StandingPosition = 0.0;
    double IdlePosition = 0.0;
    double CurrentSpeed = 0.0;
    double TurnStartYaw = 0.0;
    double TurnAngle = 0.0;
    double TurnProgress = 0.0;
    bool bStationary = false;
    bool bForward = true;
    bool bWithinRange = true;
    bool bWalking = false;
};
