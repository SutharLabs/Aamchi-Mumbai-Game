#pragma once

#include "Animation/AnimInstance.h"
#include "RanwarStrideAnimation.generated.h"

class UAnimSequence;
class FRanwarStrideProxy;

struct FRanwarFootMotion
{
    FVector Forward = FVector::ForwardVector;
    double StrideScale = 1.0;
    FVector2D PivotYaw = FVector2D::ZeroVector;
    FVector2D Lift = FVector2D::ZeroVector;
};

// Evaluates the stride at a position supplied by the actor's actual travel.
UCLASS(Transient)
class URanwarStrideAnimation final : public UAnimInstance
{
    GENERATED_BODY()

public:
    void Present(UAnimSequence* Clip, double Position, float DeltaSeconds, bool bBlendFromPreviousPose = false,
        const FRanwarFootMotion& FootMotion = FRanwarFootMotion());

protected:
    FAnimInstanceProxy* CreateAnimInstanceProxy() override;
    void DestroyAnimInstanceProxy(FAnimInstanceProxy* Proxy) override;

private:
    friend class FRanwarStrideProxy;

    UPROPERTY(Transient)
    TObjectPtr<UAnimSequence> CurrentClip;

    UPROPERTY(Transient)
    TObjectPtr<UAnimSequence> PreviousClip;

    double CurrentPosition = 0.0;
    double PreviousPosition = 0.0;
    double CurrentRate = 0.0;
    double PreviousRate = 0.0;
    FRanwarFootMotion CurrentFootMotion;
    FRanwarFootMotion PreviousFootMotion;
    float Blend = 1.0f;
};
