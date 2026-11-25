#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "RanwarParcelContact.generated.h"

class APawn;
class UAnimSequence;
class USkeletalMeshComponent;
class UStaticMeshComponent;

UCLASS()
class MUMBAIPILOT_API ARanwarParcelContact : public AActor
{
    GENERATED_BODY()

public:
    ARanwarParcelContact();
    void RespondTo(const APawn& Visitor);
    const AActor* GetMetaHumanVisual() const { return MetaHumanVisual.Get(); }

protected:
    void BeginPlay() override;
    void EndPlay(EEndPlayReason::Type EndPlayReason) override;
    void Tick(float DeltaSeconds) override;

private:
    const APawn* FindNearbyVisitor() const;
    bool StartBreathing();

    UPROPERTY(VisibleAnywhere, Category = "Parcel contact")
    TObjectPtr<UStaticMeshComponent> Appearance;

    UPROPERTY(VisibleAnywhere, Category = "Parcel contact")
    TObjectPtr<USkeletalMeshComponent> SkeletalAppearance;

    UPROPERTY(EditAnywhere, Category = "Parcel contact")
    TSubclassOf<AActor> MetaHumanClass;

    UPROPERTY(EditAnywhere, Category = "Parcel contact")
    TObjectPtr<UAnimSequence> BreathLoop;

    UPROPERTY(EditAnywhere, Category = "Parcel contact")
    TObjectPtr<UAnimSequence> ContactGesture;

    UPROPERTY(Transient)
    TObjectPtr<USkeletalMeshComponent> AnimationBody;

    UPROPERTY(Transient)
    TObjectPtr<AActor> MetaHumanVisual;

    FRotator RestRotation = FRotator::ZeroRotator;
    FRotator ResponseFacing = FRotator::ZeroRotator;
    double ResponseUntil = 0.0;
    double BreathPosition = 0.0;
    bool bHasAnimatedAppearance = false;
    bool bPlayingGesture = false;
};
