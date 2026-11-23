#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "RanwarVehicle.generated.h"

class ARanwarCharacter;
class UBoxComponent;
class UPoseableMeshComponent;
class USpringArmComponent;
class UStaticMeshComponent;

UENUM(BlueprintType)
enum class ERanwarVehicleKind : uint8
{
    Hatchback,
    Rickshaw,
    Motorcycle,
    Scooter
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
    void UpdateVehicleLook(double DeltaSeconds);
    void ShowDriver(const ARanwarCharacter& Character);
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
    TObjectPtr<UStaticMeshComponent> StandInBody;

    UPROPERTY()
    TArray<TObjectPtr<UStaticMeshComponent>> StandInWheels;

    UPROPERTY()
    TObjectPtr<UPoseableMeshComponent> SeatedDriver;

    UPROPERTY()
    TObjectPtr<USpringArmComponent> Arm;

    UPROPERTY(EditAnywhere, Category = "Vehicle")
    ERanwarVehicleKind VehicleKind = ERanwarVehicleKind::Hatchback;

    TWeakObjectPtr<ARanwarCharacter> Driver;
    double ForwardSpeed = 0.0;
    double Throttle = 0.0;
    double Steering = 0.0;
    double CameraYaw = 0.0;
    double CameraPitch = -12.0;
    double CameraLookTime = 0.0;
    double LastImpactAt = -1.0;
    float Condition = 100.0f;
    bool bBrakePressed = false;
};
