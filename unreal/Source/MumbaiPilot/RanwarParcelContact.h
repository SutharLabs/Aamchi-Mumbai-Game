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

protected:
    void BeginPlay() override;
    void Tick(float DeltaSeconds) override;

private:
    const APawn* FindNearbyVisitor() const;
    bool StartBreathing();

    UPROPERTY(VisibleAnywhere, Category = "Parcel contact")
    TObjectPtr<UStaticMeshComponent> Appearance;

    UPROPERTY(VisibleAnywhere, Category = "Parcel contact")
    TObjectPtr<USkeletalMeshComponent> SkeletalAppearance;

    UPROPERTY(EditAnywhere, Category = "Parcel contact")
    TObjectPtr<UAnimSequence> BreathLoop;

    UPROPERTY(EditAnywhere, Category = "Parcel contact")
    TObjectPtr<UAnimSequence> ContactGesture;

    FRotator RestRotation = FRotator::ZeroRotator;
    FRotator ResponseFacing = FRotator::ZeroRotator;
    double ResponseUntil = 0.0;
    bool bHasAnimatedAppearance = false;
    bool bPlayingGesture = false;
};
