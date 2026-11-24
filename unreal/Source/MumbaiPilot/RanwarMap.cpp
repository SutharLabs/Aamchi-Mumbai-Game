#include "RanwarMap.h"

#include "RanwarTraffic.h"
#include "Rendering/DrawElements.h"
#include "Widgets/SLeafWidget.h"

namespace
{
    const FLinearColor RoadEdge(0.15f, 0.24f, 0.33f);
    const FLinearColor RoadCenter(0.52f, 0.63f, 0.72f);
    const FLinearColor Footway(0.38f, 0.77f, 0.67f);
    const FLinearColor PlayerColor(0.98f, 0.78f, 0.43f);
    const FLinearColor ObjectiveColor(1.00f, 0.45f, 0.19f);

    class SRanwarStreetMap final : public SLeafWidget
    {
    public:
        SLATE_BEGIN_ARGS(SRanwarStreetMap) {}
            SLATE_ARGUMENT(TWeakObjectPtr<const ARanwarTraffic>, Traffic)
            SLATE_ARGUMENT(FVector, Player)
            SLATE_ARGUMENT(FVector, Forward)
            SLATE_ARGUMENT(TOptional<FVector>, Objective)
        SLATE_END_ARGS()

        void Construct(const FArguments& InArgs)
        {
            Traffic = InArgs._Traffic;
            Player = InArgs._Player;
            Forward = InArgs._Forward;
            Objective = InArgs._Objective;
        }

        FVector2D ComputeDesiredSize(float LayoutScaleMultiplier) const override
        {
            return FVector2D(405.0, 260.0);
        }

        int32 OnPaint(const FPaintArgs& Args, const FGeometry& Geometry, const FSlateRect& CullingRect,
            FSlateWindowElementList& Elements, int32 LayerId, const FWidgetStyle& Style, bool bParentEnabled) const override
        {
            if (!Traffic.IsValid())
            {
                return LayerId;
            }
            RanwarMap::Draw(*Traffic.Get(), FVector2D::ZeroVector, Geometry.GetLocalSize(), Player, Forward, Objective,
                [&Elements, &Geometry, LayerId](const FVector2D& Start, const FVector2D& End,
                    const FLinearColor& Color, float Thickness)
                {
                    FSlateDrawElement::MakeLines(Elements, LayerId, Geometry.ToPaintGeometry(),
                        TArray<FVector2d>{Start, End}, ESlateDrawEffect::None, Color, true, Thickness);
                }, false);
            return LayerId;
        }

    private:
        TWeakObjectPtr<const ARanwarTraffic> Traffic;
        FVector Player = FVector::ZeroVector;
        FVector Forward = FVector::ForwardVector;
        TOptional<FVector> Objective;
    };
}

void RanwarMap::Draw(const ARanwarTraffic& Traffic, const FVector2D& Origin, const FVector2D& Size,
    const FVector& Player, const FVector& Forward, const TOptional<FVector>& Objective,
    TFunctionRef<void(const FVector2D&, const FVector2D&, const FLinearColor&, float)> Line, bool bCompact)
{
    FBox2D Bounds(ForceInit);
    for (const FRanwarTrafficRoad& Road : Traffic.GetRoads())
    {
        for (const FVector& Point : Road.Points)
        {
            Bounds += FVector2D(Point);
        }
    }
    for (const FVector& Point : Traffic.GetMapFootway())
    {
        Bounds += FVector2D(Point);
    }
    if (!Bounds.bIsValid || Size.X < 40.0 || Size.Y < 40.0)
    {
        return;
    }

    const double Margin = bCompact ? 12.0 : 20.0;
    const FVector2D Extent = Bounds.GetSize();
    const double Scale = FMath::Min((Size.X - Margin * 2.0) / FMath::Max(1.0, Extent.X),
        (Size.Y - Margin * 2.0) / FMath::Max(1.0, Extent.Y));
    const FVector2D Center = Bounds.GetCenter();
    const auto Project = [&](const FVector& Point)
    {
        const FVector2D Local = Size * 0.5 + (FVector2D(Point) - Center) * Scale;
        return Origin + FVector2D(FMath::Clamp(Local.X, Margin, Size.X - Margin),
            FMath::Clamp(Local.Y, Margin, Size.Y - Margin));
    };

    for (const FRanwarTrafficRoad& Road : Traffic.GetRoads())
    {
        for (int32 Index = 1; Index < Road.Points.Num(); ++Index)
        {
            Line(Project(Road.Points[Index - 1]), Project(Road.Points[Index]), RoadEdge, bCompact ? 5.0f : 9.0f);
        }
    }
    for (const FRanwarTrafficRoad& Road : Traffic.GetRoads())
    {
        for (int32 Index = 1; Index < Road.Points.Num(); ++Index)
        {
            Line(Project(Road.Points[Index - 1]), Project(Road.Points[Index]), RoadCenter, bCompact ? 2.0f : 3.0f);
        }
    }
    const TArray<FVector>& FootwayPoints = Traffic.GetMapFootway();
    for (int32 Index = 1; Index < FootwayPoints.Num(); ++Index)
    {
        const FVector2D Start = Project(FootwayPoints[Index - 1]);
        const FVector2D End = Project(FootwayPoints[Index]);
        const FVector2D Vector = End - Start;
        const double Length = Vector.Size();
        if (Length > 0.01)
        {
            const FVector2D Direction = Vector / Length;
            for (double Distance = 0.0; Distance < Length; Distance += 7.0)
            {
                Line(Start + Direction * Distance, Start + Direction * FMath::Min(Distance + 4.0, Length), Footway, 2.0f);
            }
        }
    }

    if (Objective.IsSet())
    {
        const FVector2D Marker = Project(Objective.GetValue());
        const double Radius = bCompact ? 4.0 : 6.0;
        const FVector2D Up = Marker + FVector2D(0.0, -Radius);
        const FVector2D Right = Marker + FVector2D(Radius, 0.0);
        const FVector2D Down = Marker + FVector2D(0.0, Radius);
        const FVector2D Left = Marker + FVector2D(-Radius, 0.0);
        Line(Up, Right, ObjectiveColor, 2.5f);
        Line(Right, Down, ObjectiveColor, 2.5f);
        Line(Down, Left, ObjectiveColor, 2.5f);
        Line(Left, Up, ObjectiveColor, 2.5f);
    }

    const FVector2D Marker = Project(Player);
    const FVector2D Direction = FVector2D(Forward).GetSafeNormal();
    const FVector2D Facing = Direction.IsNearlyZero() ? FVector2D(0.0, -1.0) : Direction;
    const FVector2D Across(-Facing.Y, Facing.X);
    const double Radius = bCompact ? 5.0 : 8.0;
    const FVector2D Nose = Marker + Facing * Radius;
    const FVector2D Left = Marker - Facing * Radius * 0.65 + Across * Radius * 0.75;
    const FVector2D Right = Marker - Facing * Radius * 0.65 - Across * Radius * 0.75;
    Line(Nose, Left, PlayerColor, 3.0f);
    Line(Left, Right, PlayerColor, 3.0f);
    Line(Right, Nose, PlayerColor, 3.0f);
}

TSharedRef<SWidget> RanwarMap::BuildWidget(const ARanwarTraffic& Traffic, const FVector& Player,
    const FVector& Forward, const TOptional<FVector>& Objective)
{
    return SNew(SRanwarStreetMap).Traffic(&Traffic).Player(Player).Forward(Forward).Objective(Objective);
}
