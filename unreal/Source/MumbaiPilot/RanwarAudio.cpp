#include "RanwarAudio.h"

#include "RanwarVehicle.h"
#include "Audio.h"
#include "Components/AudioComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Engine/World.h"
#include "GameFramework/Character.h"
#include "Kismet/GameplayStatics.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Sound/SoundAttenuation.h"
#include "Sound/SoundWaveProcedural.h"
#include "TimerManager.h"
#include "UObject/UObjectGlobals.h"

namespace
{
    constexpr int32 SampleRate = 24000;
    constexpr float TwoPi = 6.28318531f;

    struct FVehicleAudioProfile
    {
        const TCHAR* Name;
        float ReferenceSpeed;
        float ThrottleInfluence;
        float PitchRange;
        float HornLow;
        float HornHigh;
    };

    FVehicleAudioProfile GetAudioProfile(ERanwarVehicleKind Kind)
    {
        switch (Kind)
        {
        case ERanwarVehicleKind::Rickshaw:
            return { TEXT("rickshaw"), 48.0f, 0.60f, 0.31f, 432.0f, 586.0f };
        case ERanwarVehicleKind::Motorcycle:
            return { TEXT("motorcycle"), 75.0f, 0.69f, 0.49f, 466.0f, 650.0f };
        case ERanwarVehicleKind::Scooter:
            return { TEXT("scooter"), 56.0f, 0.77f, 0.32f, 505.0f, 697.0f };
        case ERanwarVehicleKind::Hatchback:
        default:
            return { TEXT("hatchback"), 75.0f, 0.58f, 0.43f, 349.0f, 440.0f };
        }
    }

    float Sine(float Frequency, float Time)
    {
        return FMath::Sin(TwoPi * Frequency * Time);
    }

    float Envelope(float Time, float Duration, float Attack, float Release)
    {
        return FMath::Clamp(Time / Attack, 0.0f, 1.0f) * FMath::Clamp((Duration - Time) / Release, 0.0f, 1.0f);
    }

    int16 Quantize(float Sample)
    {
        return static_cast<int16>(FMath::RoundToInt(FMath::Clamp(Sample, -1.0f, 1.0f) * 32767.0f));
    }

    bool ReadRecording(const FString& FileName, int32 MinimumSamples, TArray<int16>& Recording)
    {
        const FString Path = FPaths::Combine(FPaths::ProjectContentDir(), TEXT("Audio"), TEXT("Ranwar"), FileName);
        TArray<uint8> Bytes;
        FWaveModInfo Info;
        if (!FFileHelper::LoadFileToArray(Bytes, *Path) || Bytes.Num() < 44 || !Info.ReadWaveInfo(Bytes.GetData(), Bytes.Num())
            || !Info.SampleDataStart || !Info.pFormatTag || !Info.pChannels || !Info.pBitsPerSample || !Info.pSamplesPerSec
            || *Info.pFormatTag != FWaveModInfo::WAVE_INFO_FORMAT_PCM
            || *Info.pChannels != 1 || *Info.pBitsPerSample != 16 || *Info.pSamplesPerSec != SampleRate
            || Info.SampleDataSize < MinimumSamples * sizeof(int16)
            || Info.SampleDataSize % sizeof(int16) != 0)
        {
            UE_LOG(LogTemp, Warning, TEXT("Cannot open cooked Ranwar recording: %s"), *FileName);
            return false;
        }
        const int64 Offset = Info.SampleDataStart - Bytes.GetData();
        if (Offset < 0 || Offset > Bytes.Num() || Info.SampleDataSize > Bytes.Num() - Offset)
        {
            UE_LOG(LogTemp, Warning, TEXT("Invalid Ranwar recording length: %s"), *FileName);
            return false;
        }
        Recording.SetNumUninitialized(static_cast<int32>(Info.SampleDataSize / sizeof(int16)));
        FMemory::Memcpy(Recording.GetData(), Info.SampleDataStart, Info.SampleDataSize);
        return true;
    }

    bool LoadEngineRecording(const TCHAR* Family, const TCHAR* State, TArray<int16>& Recording)
    {
        const FString FileName = FString::Printf(TEXT("%s-%s.wav"), Family, State);
        if (!ReadRecording(FileName, SampleRate / 2, Recording))
        {
            return false;
        }
        UE_LOG(LogTemp, Verbose, TEXT("Loaded recorded Ranwar engine audio: %s"), *FileName);
        return true;
    }

    float ReadLoop(const TArray<int16>& Recording, float& Cursor, float Pitch)
    {
        const int32 Index = static_cast<int32>(Cursor);
        const int32 Next = Index + 1 < Recording.Num() ? Index + 1 : 0;
        const float Value = FMath::Lerp(static_cast<float>(Recording[Index]), static_cast<float>(Recording[Next]),
            Cursor - static_cast<float>(Index));
        Cursor += Pitch;
        const float Length = static_cast<float>(Recording.Num());
        if (Cursor >= Length)
        {
            Cursor -= Length;
        }
        return Value / 32768.0f;
    }

    TArray<int16> BuildHorn(const FVehicleAudioProfile& Voice)
    {
        constexpr float Duration = 0.34f;
        TArray<int16> Pcm;
        Pcm.SetNumUninitialized(FMath::RoundToInt(Duration * SampleRate));
        for (int32 Index = 0; Index < Pcm.Num(); ++Index)
        {
            const float Time = static_cast<float>(Index) / SampleRate;
            const float Movement = 1.0f + 0.009f * Sine(7.0f, Time);
            const float Low = Voice.HornLow * Movement;
            const float High = Voice.HornHigh * Movement;
            const float Tone = 0.40f * Sine(Low, Time) + 0.28f * Sine(High, Time)
                + 0.11f * Sine(2.0f * Low, Time) + 0.07f * Sine(3.0f * Low, Time);
            Pcm[Index] = Quantize(Tone * Envelope(Time, Duration, 0.012f, 0.060f));
        }
        return Pcm;
    }

    bool CanPlay(AActor& Owner)
    {
        UWorld* World = Owner.GetWorld();
        return World && World->IsGameWorld() && World->GetNetMode() != NM_DedicatedServer && World->AllowAudioPlayback();
    }

    void QueuePcm(USoundWaveProcedural& Wave, const TArray<int16>& Pcm)
    {
        static_assert(PLATFORM_LITTLE_ENDIAN, "Ranwar PCM expects little-endian samples.");
        Wave.QueueAudio(reinterpret_cast<const uint8*>(Pcm.GetData()), Pcm.Num() * static_cast<int32>(sizeof(int16)));
    }

    USoundWaveProcedural* CreateOneShot(AActor& Owner, FName Name, const TArray<int16>& Pcm)
    {
        const FName Unique = MakeUniqueObjectName(&Owner, USoundWaveProcedural::StaticClass(), Name);
        USoundWaveProcedural* Wave = NewObject<USoundWaveProcedural>(&Owner, Unique, RF_Transient);
        Wave->SetSampleRate(SampleRate);
        Wave->NumChannels = 1;
        Wave->Duration = static_cast<float>(Pcm.Num()) / SampleRate;
        Wave->bLooping = false;
        QueuePcm(*Wave, Pcm);
        return Wave;
    }

    USoundAttenuation* CreateAttenuation(AActor& Owner, float NearDistance, float Falloff)
    {
        USoundAttenuation* Attenuation = NewObject<USoundAttenuation>(&Owner, NAME_None, RF_Transient);
        Attenuation->Attenuation.bAttenuate = true;
        Attenuation->Attenuation.bSpatialize = true;
        Attenuation->Attenuation.AttenuationShape = EAttenuationShape::Sphere;
        Attenuation->Attenuation.AttenuationShapeExtents = FVector(NearDistance, 0.0f, 0.0f);
        Attenuation->Attenuation.FalloffDistance = Falloff;
        return Attenuation;
    }

    void StopAfterPlayback(AActor& Owner, UAudioComponent* Component, float Duration, float Pitch)
    {
        if (Component)
        {
            FTimerHandle Timer;
            Owner.GetWorld()->GetTimerManager().SetTimer(Timer, FTimerDelegate::CreateWeakLambda(Component, [Component]()
            {
                Component->Stop();
            }), Duration / Pitch + 0.12f, false);
        }
    }
}

bool URanwarEngineSoundWave::Initialize(ERanwarVehicleKind Kind)
{
    const FVehicleAudioProfile Profile = GetAudioProfile(Kind);
    if (!LoadEngineRecording(Profile.Name, TEXT("idle"), IdleRecording)
        || !LoadEngineRecording(Profile.Name, TEXT("loaded"), LoadedRecording))
    {
        return false;
    }
    ReferenceSpeed = Profile.ReferenceSpeed;
    ThrottleInfluence = Profile.ThrottleInfluence;
    PitchRange = Profile.PitchRange;
    SetSampleRate(SampleRate);
    NumChannels = 1;
    Duration = INDEFINITELY_LOOPING_DURATION;
    bLooping = false;
    VirtualizationMode = EVirtualizationMode::PlayWhenSilent;
    return true;
}

void URanwarEngineSoundWave::SetOperatingPoint(float SpeedKph, float Throttle)
{
    const float Speed = FMath::IsFinite(SpeedKph) ? FMath::Clamp(FMath::Abs(SpeedKph) / ReferenceSpeed, 0.0f, 1.0f) : 0.0f;
    const float Load = FMath::IsFinite(Throttle) ? FMath::Clamp(FMath::Abs(Throttle), 0.0f, 1.0f) : 0.0f;
    RequestedSpeed.Store(Speed);
    RequestedLoad.Store(Load);
}

int32 URanwarEngineSoundWave::OnGeneratePCMAudio(TArray<uint8>& OutAudio, int32 NumSamples)
{
    if (IdleRecording.IsEmpty() || LoadedRecording.IsEmpty())
    {
        return 0;
    }
    const float Speed = RequestedSpeed.Load();
    const float Load = RequestedLoad.Load();
    // Approximately 80 ms of smoothing across buffer boundaries. A stopped vehicle
    // stays on its recorded idle, while throttle and road speed bring in the loaded recording.
    constexpr float Response = 0.00053f;
    OutAudio.SetNumUninitialized(NumSamples * static_cast<int32>(sizeof(int16)));
    for (int32 Index = 0; Index < NumSamples; ++Index)
    {
        FilteredSpeed += Response * (Speed - FilteredSpeed);
        FilteredLoad += Response * (Load - FilteredLoad);
        FadeInGain = FMath::Min(1.0f, FadeInGain + 1.0f / (0.04f * SampleRate));
        const float Blend = FMath::SmoothStep(0.12f, 0.86f, FilteredSpeed * 0.59f + FilteredLoad * ThrottleInfluence);
        const float IdlePitch = 0.96f + 0.29f * FilteredSpeed + 0.23f * FilteredLoad;
        const float LoadedPitch = 0.72f + PitchRange * FilteredSpeed + 0.27f * FilteredLoad;
        const float Idle = ReadLoop(IdleRecording, IdleCursor, IdlePitch);
        const float Loaded = ReadLoop(LoadedRecording, LoadedCursor, LoadedPitch);
        const float MixGain = FadeInGain * (0.82f + 0.18f * FilteredLoad);
        const uint16 Sample = static_cast<uint16>(Quantize(FMath::Lerp(Idle, Loaded, Blend) * MixGain));
        OutAudio[2 * Index] = static_cast<uint8>(Sample & 0xffu);
        OutAudio[2 * Index + 1] = static_cast<uint8>(Sample >> 8);
    }
    return NumSamples;
}

UAudioComponent* RanwarAudio::StartVehicleEngine(AActor& Owner, ERanwarVehicleKind Kind)
{
    USceneComponent* Root = Owner.GetRootComponent();
    if (!Root || !CanPlay(Owner))
    {
        return nullptr;
    }
    const FName Name = MakeUniqueObjectName(&Owner, URanwarEngineSoundWave::StaticClass(), TEXT("RanwarEngine"));
    URanwarEngineSoundWave* Wave = NewObject<URanwarEngineSoundWave>(&Owner, Name, RF_Transient);
    if (!Wave->Initialize(Kind))
    {
        return nullptr;
    }
    return UGameplayStatics::SpawnSoundAttached(Wave, Root, NAME_None, FVector::ZeroVector,
        EAttachLocation::KeepRelativeOffset, true, 0.57f, 1.0f, 0.0f, CreateAttenuation(Owner, 440.0f, 1700.0f), nullptr, true);
}

void RanwarAudio::UpdateVehicleEngine(UAudioComponent* Engine, float SpeedKph, float Throttle)
{
    if (!IsValid(Engine))
    {
        return;
    }
    if (URanwarEngineSoundWave* Wave = Cast<URanwarEngineSoundWave>(Engine->GetSound()))
    {
        Wave->SetOperatingPoint(SpeedKph, Throttle);
    }
}

void RanwarAudio::PlayHorn(AActor& Owner, ERanwarVehicleKind Kind)
{
    USceneComponent* Root = Owner.GetRootComponent();
    if (!Root || !CanPlay(Owner))
    {
        return;
    }
    USoundWaveProcedural* Wave = CreateOneShot(Owner, TEXT("RanwarHorn"), BuildHorn(GetAudioProfile(Kind)));
    UAudioComponent* Component = UGameplayStatics::SpawnSoundAttached(Wave, Root, NAME_None, FVector(85.0f, 0.0f, 35.0f),
        EAttachLocation::KeepRelativeOffset, true, 0.50f, 1.0f, 0.0f, CreateAttenuation(Owner, 480.0f, 2600.0f), nullptr, true);
    StopAfterPlayback(Owner, Component, Wave->Duration, 1.0f);
}

void RanwarAudio::PlayParcelPickup(AActor& Owner, const FVector& Position)
{
    TArray<int16> Pcm;
    if (!CanPlay(Owner) || !ReadRecording(TEXT("parcel-pickup.wav"), 1, Pcm))
    {
        return;
    }
    UE_LOG(LogTemp, Verbose, TEXT("Loaded shared Ranwar pickup cue: parcel-pickup.wav"));
    USoundWaveProcedural* Wave = CreateOneShot(Owner, TEXT("RanwarParcelPickup"), Pcm);
    UAudioComponent* Component = UGameplayStatics::SpawnSoundAtLocation(&Owner, Wave, Position, FRotator::ZeroRotator,
        0.71f, 1.0f, 0.0f, CreateAttenuation(Owner, 300.0f, 1300.0f), nullptr, true);
    StopAfterPlayback(Owner, Component, Wave->Duration, 1.0f);
}

UAudioComponent* RanwarAudio::PlayDialogue(AActor& Owner, FName Id, float Volume)
{
    TArray<int16> Pcm;
    const FString FileName = FString::Printf(TEXT("Dialogue/%s.wav"), *Id.ToString());
    if (Volume <= 0.0f || !CanPlay(Owner) || !ReadRecording(FileName, SampleRate / 2, Pcm))
    {
        return nullptr;
    }
    USoundWaveProcedural* Wave = CreateOneShot(Owner, TEXT("RanwarDialogue"), Pcm);
    UAudioComponent* Component = UGameplayStatics::SpawnSound2D(&Owner, Wave, FMath::Clamp(Volume, 0.0f, 1.0f));
    StopAfterPlayback(Owner, Component, Wave->Duration, 1.0f);
    if (Component)
    {
        UE_LOG(LogTemp, Verbose, TEXT("Playing Ranwar dialogue: %s"), *Id.ToString());
    }
    return Component;
}

void RanwarAudio::PlayFootstep(AActor& Owner, bool bRunning, bool bRightFoot)
{
    if (!CanPlay(Owner))
    {
        return;
    }
    struct FStepSample
    {
        TArray<int16> PCM;
        bool bTriedLoad = false;
    };
    static FStepSample Samples[2][3];
    static int32 NextSample[2] = {};
    const int32 Gait = bRunning ? 1 : 0;
    const int32 Index = NextSample[Gait];
    NextSample[Gait] = (Index + 1) % UE_ARRAY_COUNT(Samples[0]);
    FStepSample& Sample = Samples[Gait][Index];
    if (!Sample.bTriedLoad)
    {
        Sample.bTriedLoad = true;
        const FString FileName = FString::Printf(TEXT("sandal-%s-%d.wav"), bRunning ? TEXT("run") : TEXT("walk"), Index + 1);
        if (ReadRecording(FileName, SampleRate / 20, Sample.PCM))
        {
            UE_LOG(LogTemp, Verbose, TEXT("Loaded recorded Ranwar footstep: %s"), *FileName);
        }
    }
    if (Sample.PCM.IsEmpty())
    {
        return;
    }
    FVector Position = Owner.GetActorLocation() + Owner.GetActorRightVector() * (bRightFoot ? 10.0f : -10.0f);
    if (const ACharacter* Walker = Cast<ACharacter>(&Owner))
    {
        const double FloorZ = Position.Z - Walker->GetCapsuleComponent()->GetScaledCapsuleHalfHeight();
        const FName Toe = bRightFoot ? FName(TEXT("RightToes")) : FName(TEXT("LeftToes"));
        if (const USkeletalMeshComponent* Mesh = Walker->GetMesh(); Mesh && Mesh->DoesSocketExist(Toe))
        {
            Position = Mesh->GetSocketLocation(Toe);
        }
        Position.Z = FloorZ + 4.0f;
    }
    USoundWaveProcedural* Wave = CreateOneShot(Owner, TEXT("RanwarFootstep"), Sample.PCM);
    const float Pitch = bRightFoot ? 1.02f : 0.99f;
    UAudioComponent* Component = UGameplayStatics::SpawnSoundAtLocation(&Owner, Wave, Position, FRotator::ZeroRotator,
        bRunning ? 0.50f : 0.35f, Pitch, 0.0f, CreateAttenuation(Owner, 300.0f, 900.0f), nullptr, true);
    StopAfterPlayback(Owner, Component, Wave->Duration, Pitch);
}
