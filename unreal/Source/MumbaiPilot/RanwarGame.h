#pragma once

#include "CoreMinimal.h"
#include "Engine/TimerHandle.h"
#include "GameFramework/Actor.h"
#include "GameFramework/Character.h"
#include "GameFramework/GameModeBase.h"
#include "GameFramework/HUD.h"
#include "RanwarGame.generated.h"

class USceneComponent;
class UTextRenderComponent;
class UAnimSequence;

UCLASS()
class MUMBAIPILOT_API ARanwarLandmark : public AActor
{
    GENERATED_BODY()

public:
    ARanwarLandmark();
    const FText& GetDisplayName() const { return DisplayName; }
    const FText& GetDetails() const { return Details; }

protected:
    void OnConstruction(const FTransform& Transform) override;
    void BeginPlay() override;

private:
    UPROPERTY(EditAnywhere, Category = "Ranwar")
    FText DisplayName;

    UPROPERTY(EditAnywhere, Category = "Ranwar", meta = (MultiLine = "true"))
    FText Details;

    UPROPERTY()
    TObjectPtr<UTextRenderComponent> Sign;
};

UCLASS()
class MUMBAIPILOT_API ARanwarCharacter : public ACharacter
{
    GENERATED_BODY()

public:
    ARanwarCharacter();
    FText GetInteractionPrompt() const;
    FText GetInteractionDetails() const;

protected:
    void BeginPlay() override;
    void Tick(float DeltaSeconds) override;
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
    FTimerHandle LandmarkScanTimer;
    FText InteractionDetails;
    double DetailsUntil = 0.0;
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
};
