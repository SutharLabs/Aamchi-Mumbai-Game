#pragma once

#include "CoreMinimal.h"
#include "Sound/SoundWaveProcedural.h"
#include "Templates/Atomic.h"
#include "RanwarAudio.generated.h"

class AActor;
class UAudioComponent;
enum class ERanwarVehicleKind : uint8;

UCLASS()
class URanwarEngineSoundWave final : public USoundWaveProcedural
{
    GENERATED_BODY()

public:
    bool Initialize(ERanwarVehicleKind Kind);
    void SetOperatingPoint(float SpeedKph, float Throttle);

protected:
    int32 OnGeneratePCMAudio(TArray<uint8>& OutAudio, int32 NumSamples) override;

private:
    TArray<int16> IdleRecording;
    TArray<int16> LoadedRecording;
    TAtomic<float> RequestedSpeed{0.0f};
    TAtomic<float> RequestedLoad{0.0f};
    float ReferenceSpeed = 70.0f;
    float ThrottleInfluence = 0.67f;
    float PitchRange = 0.34f;
    float IdleCursor = 0.0f;
    float LoadedCursor = 0.0f;
    float FilteredSpeed = 0.0f;
    float FilteredLoad = 0.0f;
    float FadeInGain = 0.0f;
};

namespace RanwarAudio
{
    // Loops are owned by the audio world. Retain the returned component to adjust or stop it.
    UAudioComponent* StartVehicleEngine(AActor& Owner, ERanwarVehicleKind Kind);
    void UpdateVehicleEngine(UAudioComponent* Engine, float SpeedKph, float Throttle);
    void PlayHorn(AActor& Owner, ERanwarVehicleKind Kind);
    void PlayParcelPickup(AActor& Owner, const FVector& Position);
    UAudioComponent* PlayDialogue(AActor& Owner, FName Id, float Volume);
    void PlayFootstep(AActor& Owner, bool bRunning, bool bRightFoot);
}
