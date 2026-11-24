#pragma once

#include "CoreMinimal.h"

class ARanwarTraffic;
class SWidget;

namespace RanwarMap
{
    void Draw(const ARanwarTraffic& Traffic, const FVector2D& Origin, const FVector2D& Size,
        const FVector& Player, const FVector& Forward, const TOptional<FVector>& Objective,
        TFunctionRef<void(const FVector2D&, const FVector2D&, const FLinearColor&, float)> Line,
        bool bCompact);

    TSharedRef<SWidget> BuildWidget(const ARanwarTraffic& Traffic, const FVector& Player,
        const FVector& Forward, const TOptional<FVector>& Objective);
}
