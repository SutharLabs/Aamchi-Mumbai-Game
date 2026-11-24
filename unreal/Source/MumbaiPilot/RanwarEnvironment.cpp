#include "RanwarEnvironment.h"

#include "Components/ExponentialHeightFogComponent.h"
#include "Components/InstancedStaticMeshComponent.h"
#include "Components/LightComponent.h"
#include "Components/SceneComponent.h"
#include "Components/SkyLightComponent.h"
#include "Components/StaticMeshComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/ExponentialHeightFog.h"
#include "Engine/Light.h"
#include "Engine/PostProcessVolume.h"
#include "Engine/SkyLight.h"
#include "Engine/StaticMeshActor.h"
#include "Engine/World.h"
#include "Materials/MaterialInstanceDynamic.h"
#include "Misc/CommandLine.h"
#include "Misc/Parse.h"

namespace
{
    constexpr double MinutesPerDay = 1440.0;
    constexpr double Dawn = 360.0;
    constexpr double StartMinutes = 630.0;

    void PrepareBackdrop(UPrimitiveComponent& Component)
    {
        Component.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        Component.SetGenerateOverlapEvents(false);
        Component.SetCastShadow(false);
    }

    void CaptureIntensities(const TArray<TObjectPtr<ALight>>& Lights, TArray<float>& Intensities)
    {
        for (const ALight* Light : Lights)
        {
            Intensities.Add(IsValid(Light) && Light->GetLightComponent() ? Light->GetLightComponent()->Intensity : 0.0f);
        }
    }

    void ApplyLights(const TArray<TObjectPtr<ALight>>& Lights, const TArray<float>& Intensities, float Weight)
    {
        for (int32 Index = 0; Index < Lights.Num(); ++Index)
        {
            if (ALight* Light = Lights[Index]; IsValid(Light) && Light->GetLightComponent())
            {
                ULightComponent* Component = Light->GetLightComponent();
                const float Intensity = Intensities[Index] * Weight;
                Component->SetVisibility(Intensity > 3.0f);
                Component->SetIntensity(Intensity);
            }
        }
    }
}

ARanwarEnvironment::ARanwarEnvironment()
{
    PrimaryActorTick.bCanEverTick = true;
    PrimaryActorTick.TickInterval = 0.25f;
    RootComponent = CreateDefaultSubobject<USceneComponent>(TEXT("EnvironmentOrigin"));
    CloudLayer = CreateDefaultSubobject<UStaticMeshComponent>(TEXT("CloudLayer"));
    CloudLayer->SetupAttachment(RootComponent);
    PrepareBackdrop(*CloudLayer);
    DistantBuildings = CreateDefaultSubobject<UInstancedStaticMeshComponent>(TEXT("DistantBuildings"));
    DistantBuildings->SetupAttachment(RootComponent);
    PrepareBackdrop(*DistantBuildings);
}

APostProcessVolume* ARanwarEnvironment::CreateExposure(UWorld& World)
{
    APostProcessVolume* Volume = World.SpawnActor<APostProcessVolume>();
    if (Volume)
    {
        Volume->bUnbound = true;
        FPostProcessSettings& Settings = Volume->Settings;
        Settings.bOverride_AutoExposureMethod = true;
        Settings.AutoExposureMethod = AEM_Manual;
        Settings.bOverride_AutoExposureApplyPhysicalCameraExposure = true;
        Settings.AutoExposureApplyPhysicalCameraExposure = true;
        Settings.bOverride_AutoExposureBias = true;
        Settings.AutoExposureBias = 0.9f;
        Settings.bOverride_CameraISO = true;
        Settings.CameraISO = 100.0f;
        Settings.bOverride_CameraShutterSpeed = true;
        Settings.CameraShutterSpeed = 125.0f;
        Settings.bOverride_DepthOfFieldFstop = true;
        Settings.DepthOfFieldFstop = 8.0f;
        Settings.bOverride_BloomIntensity = true;
        Settings.BloomIntensity = 0.22f;
        Settings.bOverride_MotionBlurAmount = true;
        Settings.MotionBlurAmount = 0.0f;
    }
    return Volume;
}

void ARanwarEnvironment::BeginPlay()
{
    Super::BeginPlay();
    CaptureIntensities(Streets, StreetPeak);
    CaptureIntensities(Interiors, InnerPeak);
    Exposure = CreateExposure(*GetWorld());
    if (CloudLayer->GetMaterial(0))
    {
        CloudFinish = CloudLayer->CreateDynamicMaterialInstance(0);
    }
    if (!LampLenses.IsEmpty() && LampLenses[0])
    {
        LampLensFinish = LampLenses[0]->GetStaticMeshComponent()->CreateDynamicMaterialInstance(0);
        for (AStaticMeshActor* Lens : LampLenses)
        {
            if (Lens && LampLensFinish)
            {
                Lens->GetStaticMeshComponent()->SetMaterial(0, LampLensFinish);
            }
        }
    }
#if WITH_DEV_AUTOMATION_TESTS
    double Preview = 0.0;
    if (FParse::Value(FCommandLine::Get(), TEXT("RanwarTime="), Preview) && FMath::IsFinite(Preview))
    {
        bAdvanceClock = false;
        SetActorTickEnabled(false);
        SetTimeMinutes(Preview);
        return;
    }
#endif
    ApplyEnvironment();
}

void ARanwarEnvironment::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    if (bAdvanceClock)
    {
        SetTimeMinutes(Minutes + DeltaSeconds);
    }
}

void ARanwarEnvironment::SetTimeMinutes(double Value)
{
    if (FMath::IsFinite(Value))
    {
        Minutes = FMath::Fmod(FMath::Fmod(Value, MinutesPerDay) + MinutesPerDay, MinutesPerDay);
        ApplyEnvironment();
    }
}

void ARanwarEnvironment::ApplyEnvironment()
{
    const double Phase = UE_DOUBLE_TWO_PI * (Minutes - Dawn) / MinutesPerDay;
    const float Elevation = FMath::Sin(Phase);
    const float Day = FMath::SmoothStep(-0.07f, 0.54f, Elevation);
    const float Twilight = FMath::SmoothStep(-0.19f, 0.03f, Elevation)
        * (1.0f - FMath::SmoothStep(0.06f, 0.45f, Elevation));
    const float Lamps = 1.0f - FMath::SmoothStep(-0.12f, 0.27f, Elevation);
    if (Sun)
    {
        Sun->SetActorRotation(FRotator(-50.0 * Elevation, -41.0 + (Minutes - StartMinutes) * 0.25, 0.0));
        ULightComponent* Light = Sun->GetLightComponent();
        Light->SetIntensity(28000.0f * Day);
        Light->SetTemperature(FMath::Lerp(5950.0f, 3150.0f, Twilight));
        Light->SetCastShadows(Day > 0.11f);
    }
    if (MoonFill)
    {
        MoonFill->GetLightComponent()->SetIntensity(780.0f * (1.0f - Day) + 1300.0f * Twilight);
    }
    if (Sky)
    {
        USkyLightComponent* Light = Sky->GetLightComponent();
        Light->SetIntensity(FMath::Lerp(0.68f, 1.64f, Day));
    }
    if (Haze)
    {
        UExponentialHeightFogComponent* Fog = Haze->GetComponent();
        Fog->SetFogDensity(FMath::Lerp(0.016f, 0.024f, Day));
        Fog->SetFogInscatteringColor(FMath::Lerp(FLinearColor(0.015f, 0.025f, 0.043f),
            FLinearColor(0.36f, 0.49f, 0.56f), Day));
    }
    if (Exposure)
    {
        FPostProcessSettings& Camera = Exposure->Settings;
        // Hold daylight at the original exposure. A wider aperture, longer shutter and
        // moderate ISO keep the street readable under much weaker dusk and night light.
        Camera.DepthOfFieldFstop = FMath::Lerp(2.8f, 8.0f, Day);
        Camera.CameraShutterSpeed = FMath::Lerp(62.5f, 125.0f, Day);
        Camera.CameraISO = FMath::Lerp(135.0f, 100.0f, Day);
        Camera.AutoExposureBias = FMath::Lerp(3.65f, 0.9f, Day);
    }
    if (CloudFinish)
    {
        const FLinearColor CloudDay = FMath::Lerp(FLinearColor::White, FLinearColor(1.0f, 0.56f, 0.40f), Twilight);
        CloudFinish->SetVectorParameterValue(TEXT("CloudTint"),
            FMath::Lerp(FLinearColor(65.0f, 95.0f, 140.0f), CloudDay * 6900.0f, Day));
        CloudFinish->SetScalarParameterValue(TEXT("CloudOpacity"), FMath::Lerp(0.14f, 0.44f, Day));
    }
    if (LampLensFinish)
    {
        LampLensFinish->SetVectorParameterValue(TEXT("LensGlow"), FLinearColor(350.0f, 248.0f, 144.0f) * Lamps);
    }
    ApplyLights(Streets, StreetPeak, Lamps);
    ApplyLights(Interiors, InnerPeak, FMath::Lerp(0.10f, 1.0f, Day * Day));
}
