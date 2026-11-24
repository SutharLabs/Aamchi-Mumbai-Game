#pragma once

#include "CoreMinimal.h"
#include "Engine/TimerHandle.h"
#include "GameFramework/Actor.h"
#include "GameFramework/Character.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/HUD.h"
#include "RanwarGame.generated.h"

class USceneComponent;
class UAnimSequence;
class ARanwarRoute;
class ARanwarVehicle;

UCLASS()
class MUMBAIPILOT_API ARanwarLandmark : public AActor
{
    GENERATED_BODY()

public:
    ARanwarLandmark();
    const FText& GetDisplayName() const { return DisplayName; }
    const FText& GetDetails() const { return Details; }

private:
    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FText DisplayName;

    UPROPERTY(EditAnywhere, Category = "Ranwar", meta = (MultiLine = "true"))
    FText Details;

};

UCLASS()
class MUMBAIPILOT_API ARanwarCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ARanwarCharacter();
    FText GetInteractionPrompt() const;
    FText GetInteractionDetails() const;
    float GetHealth() const { return Health; }
    float TakeDamage(float DamageAmount, const FDamageEvent& DamageEvent, AController* EventInstigator,
        AActor* DamageCauser) override;

protected:
    void BeginPlay() override;
    void Tick(float DeltaSeconds) override;
    void Landed(const FHitResult& Hit) override;
    void FellOutOfWorld(const UDamageType& DamageType) override;
    void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    void SetupPlayerInputComponent(UInputComponent* Input) override;
    void UnPossessed() override;

private:
    void MoveForward(float Value);
    void MoveRight(float Value);
    void TurnWithStick(float Value);
    void LookUpWithStick(float Value);
    void StartRunning();
    void StopRunning();
    void LoadOmkarAppearance();
    void UpdateLocomotion();
    void UpdateLandmarkFocus();
    void Interact();
    void RecoverAtStop();

    UPROPERTY()
    TObjectPtr<USceneComponent> WalkTestMarker;

    UPROPERTY()
    TObjectPtr<UAnimSequence> IdleLoop;

    UPROPERTY()
    TObjectPtr<UAnimSequence> WalkLoop;

    UPROPERTY()
    TObjectPtr<UAnimSequence> RunLoop;

    UPROPERTY()
    TObjectPtr<UAnimSequence> ActiveLoop;

    TWeakObjectPtr<ARanwarLandmark> NearbyLandmark;
    TWeakObjectPtr<ARanwarVehicle> NearbyVehicle;
    FTimerHandle LandmarkScanTimer;
    FTimerHandle RecoveryTimer;
    FText InteractionDetails;
    double DetailsUntil = 0.0;
    double LastDamageTime = 0.0;
    double DistanceSinceStep = 0.0;
    double LastRunStepPosition = -1.0;
    float Health = 100.0f;
    bool bRightFootNext = false;
    FTransform StartTransform;
    FTransform SafeGroundTransform;
};

UCLASS()
class MUMBAIPILOT_API ARanwarHUD : public AHUD
{
    GENERATED_BODY()

protected:
    void DrawHUD() override;
};

UCLASS()
class MUMBAIPILOT_API ARanwarGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    ARanwarGameMode();
    UClass* GetDefaultPawnClassForController_Implementation(AController* InController) override;
    ARanwarRoute* GetRoute() const { return Route.Get(); }

protected:
    void BeginPlay() override;

private:
    TWeakObjectPtr<ARanwarRoute> Route;
};
