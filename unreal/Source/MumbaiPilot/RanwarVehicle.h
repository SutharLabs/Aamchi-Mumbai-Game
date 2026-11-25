#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "GameFramework/Pawn.h"
#include "RanwarVehicle.generated.h"

class ARanwarCharacter;
class UAudioComponent;
class UBoxComponent;
class UPoseableMeshComponent;
class USpringArmComponent;
class USkeletalMesh;
class UStaticMesh;
class UStaticMeshComponent;

UENUM(BlueprintType)
enum class ERanwarVehicleKind : uint8
{
    Hatchback,
    Rickshaw,
    Motorcycle,
    Scooter
};

namespace RanwarDriverPose
{
    bool FitAmbient(UPoseableMeshComponent& Rider, USkeletalMesh& Mesh, ERanwarVehicleKind Kind);
}

UCLASS()
class MUMBAIPILOT_API URanwarVehicleVisualProfile : public UDataAsset
{
    GENERATED_BODY()

public:
    bool HasValidGeometry() const;

    UPROPERTY(EditAnywhere, Category = "Visual")
    TObjectPtr<UStaticMesh> Body;

    UPROPERTY(EditAnywhere, Category = "Visual")
    TObjectPtr<UStaticMesh> Fork;

    UPROPERTY(EditAnywhere, Category = "Visual")
    TObjectPtr<UStaticMesh> FrontWheel;

    UPROPERTY(EditAnywhere, Category = "Visual")
    TObjectPtr<UStaticMesh> RearWheel;

    UPROPERTY(EditAnywhere, Category = "Visual")
    FVector ForkPivot = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Visual")
    FVector SteeringAxis = FVector::UpVector;

    UPROPERTY(EditAnywhere, Category = "Visual")
    FVector FrontWheelPivot = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Visual")
    FVector RearWheelPivot = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Visual")
    FVector DriverHip = FVector::ZeroVector;

    UPROPERTY(EditAnywhere, Category = "Visual")
    double FrontWheelRadius = 0.0;

    UPROPERTY(EditAnywhere, Category = "Visual")
    double RearWheelRadius = 0.0;
};

UCLASS()
class MUMBAIPILOT_API ARanwarVehicle : public APawn
{
    GENERATED_BODY()

public:
    ARanwarVehicle();

    void SetVehicleKind(ERanwarVehicleKind Kind);
    bool PlaceOnGround(const FVector& GroundPoint, const FRotator& Heading);
    bool CanEnter(const ARanwarCharacter* Character) const;
    bool TryEnter(ARanwarCharacter* Character);
    bool HasDriver() const;
    bool ExitDriver();
    FText GetVehicleName() const;
    double GetSpeedKph() const;
    float GetCondition() const { return Condition; }
    const ARanwarCharacter* GetDriver() const;
    UStaticMeshComponent* GetVehicleMesh() const;
    virtual FVector GetVelocity() const override;

protected:
    virtual void BeginPlay() override;
    virtual void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    virtual void Tick(float DeltaSeconds) override;
    virtual void SetupPlayerInputComponent(UInputComponent* Input) override;
    virtual void UnPossessed() override;

private:
    void Advance(double Step);
    void SetThrottle(float Value);
    void SetSteering(float Value);
    void Turn(float Value);
    void LookUp(float Value);
    void TurnWithStick(float Value);
    void LookUpWithStick(float Value);
    void PressBrake();
    void ReleaseBrake();
    void RequestExit();
    void UseHorn();
    void StopEngineAudio();
    void UpdateVehicleLook(double DeltaSeconds);
    void SetDetailedVisual(URanwarVehicleVisualProfile* Profile);
    void UpdateDetailedVisual(double Travel, double DeltaSeconds);
    bool ShowDriver(ARanwarCharacter& Character);
    void RestoreDriver(ARanwarCharacter& Character, const FVector* ExitLocation);
    bool FindExitLocation(const ARanwarCharacter& Character, FVector& ExitLocation) const;
    bool SampleGround(const FVector& Position, double Up, double Down, double& GroundZ) const;
    bool HasChassisClearance(const FVector& Location, const FQuat& Rotation) const;
    double RideHeight() const;

    UPROPERTY(VisibleAnywhere, Category = "Vehicle")
    TObjectPtr<UBoxComponent> Chassis;

    UPROPERTY(VisibleAnywhere, Category = "Vehicle")
    TObjectPtr<UStaticMeshComponent> VehicleMesh;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> VisualFork;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> VisualFrontWheel;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> VisualRearWheel;

    UPROPERTY(Transient)
    TObjectPtr<URanwarVehicleVisualProfile> VisualProfile;

    UPROPERTY()
    TObjectPtr<UStaticMeshComponent> StandInBody;

    UPROPERTY()
    TArray<TObjectPtr<UStaticMeshComponent>> StandInWheels;

    UPROPERTY()
    TObjectPtr<UPoseableMeshComponent> SeatedDriver;

    UPROPERTY()
    TObjectPtr<USpringArmComponent> Arm;

    UPROPERTY()
    TObjectPtr<UAudioComponent> EngineAudio;

    UPROPERTY(EditAnywhere, Category = "Vehicle")
    ERanwarVehicleKind VehicleKind = ERanwarVehicleKind::Hatchback;

    TWeakObjectPtr<ARanwarCharacter> Driver;
    double ForwardSpeed = 0.0;
    double Throttle = 0.0;
    double Steering = 0.0;
    double VisualSteerAngle = 0.0;
    double FrontWheelRoll = 0.0;
    double RearWheelRoll = 0.0;
    double CameraYaw = 0.0;
    double CameraPitch = -12.0;
    double CameraLookTime = 0.0;
    double LastImpactAt = -1.0;
    double LastHornAt = -1.0;
    float Condition = 100.0f;
    bool bBrakePressed = false;
};
