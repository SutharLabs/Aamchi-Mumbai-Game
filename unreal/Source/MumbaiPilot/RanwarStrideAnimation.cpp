#include "RanwarStrideAnimation.h"

#include "Animation/AnimInstanceProxy.h"
#include "Animation/AnimNodeBase.h"
#include "Animation/AnimSequence.h"
#include "Animation/AnimationPoseData.h"
#include "AnimationRuntime.h"
#include "TwoBoneIK.h"

namespace
{
    void ApplyFootMotion(FCompactPose& Pose, const FRanwarFootMotion& Motion)
    {
        if (Motion.StrideScale == 1.0 && Motion.PivotYaw.IsNearlyZero() && Motion.Lift.IsNearlyZero())
        {
            return;
        }
        const FBoneContainer& Bones = Pose.GetBoneContainer();
        FCSPose<FCompactPose> ComponentSpace;
        ComponentSpace.InitPose(Pose);
        static const FName AnkleNames[] = {TEXT("foot_l"), TEXT("foot_r")};
        for (int32 Side = 0; Side < UE_ARRAY_COUNT(AnkleNames); ++Side)
        {
            const int32 MeshIndex = Bones.GetPoseBoneIndexForBoneName(AnkleNames[Side]);
            if (MeshIndex == INDEX_NONE)
            {
                continue;
            }
            const FCompactPoseBoneIndex Ankle = Bones.MakeCompactPoseIndex(FMeshPoseBoneIndex(MeshIndex));
            if (Ankle.GetInt() == INDEX_NONE)
            {
                continue;
            }
            const FCompactPoseBoneIndex Knee = Pose.GetParentBoneIndex(Ankle);
            if (Knee.GetInt() == INDEX_NONE)
            {
                continue;
            }
            const FCompactPoseBoneIndex Hip = Pose.GetParentBoneIndex(Knee);
            if (Hip.GetInt() == INDEX_NONE)
            {
                continue;
            }
            const FCompactPoseBoneIndex Parent = Pose.GetParentBoneIndex(Hip);
            if (Parent.GetInt() == INDEX_NONE)
            {
                continue;
            }

            FTransform Upper = ComponentSpace.GetComponentSpaceTransform(Hip);
            FTransform Lower = ComponentSpace.GetComponentSpaceTransform(Knee);
            FTransform Foot = ComponentSpace.GetComponentSpaceTransform(Ankle);
            const FQuat Pivot(FVector::UpVector, FMath::DegreesToRadians(Motion.PivotYaw[Side]));
            const FVector Original = Foot.GetTranslation();
            const FVector ShorterStep = Motion.Forward * (FVector::DotProduct(Original, Motion.Forward)
                * (Motion.StrideScale - 1.0));
            const FVector Target = Pivot.RotateVector(Original + ShorterStep) + FVector(0.0, 0.0, Motion.Lift[Side]);
            AnimationCore::SolveTwoBoneIK(Upper, Lower, Foot, Lower.GetTranslation() + Motion.Forward * 8.0,
                Target, false, 1.0, 1.0);
            Foot.SetRotation((Pivot * Foot.GetRotation()).GetNormalized());
            Pose[Hip] = Upper.GetRelativeTransform(ComponentSpace.GetComponentSpaceTransform(Parent));
            Pose[Knee] = Lower.GetRelativeTransform(Upper);
            Pose[Ankle] = Foot.GetRelativeTransform(Lower);
        }
    }
}

class FRanwarStrideProxy final : public FAnimInstanceProxy
{
public:
    explicit FRanwarStrideProxy(UAnimInstance* Instance) : FAnimInstanceProxy(Instance) {}

    void PreUpdate(UAnimInstance* Instance, float DeltaSeconds) override
    {
        FAnimInstanceProxy::PreUpdate(Instance, DeltaSeconds);
        const URanwarStrideAnimation* Stride = CastChecked<URanwarStrideAnimation>(Instance);
        Current = Stride->CurrentClip;
        Previous = Stride->PreviousClip;
        CurrentPosition = Stride->CurrentPosition;
        PreviousPosition = Stride->PreviousPosition;
        CurrentFootMotion = Stride->CurrentFootMotion;
        PreviousFootMotion = Stride->PreviousFootMotion;
        Blend = Stride->Blend;
    }

    bool Evaluate(FPoseContext& Output) override
    {
        if (!Current)
        {
            Output.ResetToRefPose();
            return true;
        }

        FAnimationPoseData Pose(Output);
        Current->GetAnimationPose(Pose, FAnimExtractContext(CurrentPosition, Current->HasRootMotion()));
        ApplyFootMotion(Output.Pose, CurrentFootMotion);
        if (Previous && Blend < 1.0f)
        {
            FPoseContext PreviousContext(Output);
            FAnimationPoseData PreviousPose(PreviousContext);
            Previous->GetAnimationPose(PreviousPose, FAnimExtractContext(PreviousPosition, Previous->HasRootMotion()));
            ApplyFootMotion(PreviousContext.Pose, PreviousFootMotion);
            FAnimationRuntime::BlendTwoPosesTogetherInPlace(Pose, PreviousPose, Blend);
        }
        return true;
    }

private:
    const UAnimSequence* Current = nullptr;
    const UAnimSequence* Previous = nullptr;
    double CurrentPosition = 0.0;
    double PreviousPosition = 0.0;
    FRanwarFootMotion CurrentFootMotion;
    FRanwarFootMotion PreviousFootMotion;
    float Blend = 1.0f;
};

void URanwarStrideAnimation::Present(UAnimSequence* Clip, double Position, float DeltaSeconds, bool bBlendFromPreviousPose,
    const FRanwarFootMotion& FootMotion)
{
    if (Clip != CurrentClip || bBlendFromPreviousPose)
    {
        PreviousClip = CurrentClip;
        PreviousPosition = CurrentPosition;
        PreviousRate = CurrentRate;
        PreviousFootMotion = CurrentFootMotion;
        CurrentClip = Clip;
        CurrentRate = 0.0;
        Blend = PreviousClip ? 0.0f : 1.0f;
    }
    else if (Clip && DeltaSeconds > UE_SMALL_NUMBER)
    {
        const double Duration = Clip->GetPlayLength();
        const double Advance = Position - CurrentPosition;
        CurrentRate = FMath::Clamp((Advance < 0.0 ? Advance + Duration : Advance) / DeltaSeconds, 0.0, 3.0);
    }
    CurrentPosition = Position;
    CurrentFootMotion = FootMotion;
    constexpr float TransitionSeconds = 0.22f;
    Blend = FMath::Min(Blend + FMath::Max(DeltaSeconds, 0.0f) / TransitionSeconds, 1.0f);
    if (Blend >= 1.0f)
    {
        PreviousClip = nullptr;
    }
    else if (PreviousClip && PreviousClip->GetPlayLength() > UE_SMALL_NUMBER)
    {
        PreviousPosition = FMath::Fmod(PreviousPosition + PreviousRate * FMath::Max(DeltaSeconds, 0.0f),
            static_cast<double>(PreviousClip->GetPlayLength()));
    }
}

FAnimInstanceProxy* URanwarStrideAnimation::CreateAnimInstanceProxy()
{
    return new FRanwarStrideProxy(this);
}

void URanwarStrideAnimation::DestroyAnimInstanceProxy(FAnimInstanceProxy* Proxy)
{
    delete Proxy;
}
