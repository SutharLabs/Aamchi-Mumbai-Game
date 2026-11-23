#include "SeaLinkGame.h"

#include "Camera/CameraComponent.h"
#include "Components/CapsuleComponent.h"
#include "Components/InputComponent.h"
#include "GameFramework/CharacterMovementComponent.h"
#include "Modules/ModuleManager.h"

IMPLEMENT_PRIMARY_GAME_MODULE(FDefaultGameModuleImpl, MumbaiPilot, "MumbaiPilot");

ASeaLinkWalker::ASeaLinkWalker()
{
    UCameraComponent* Camera = CreateDefaultSubobject<UCameraComponent>(TEXT("Eye"));
    Camera->SetupAttachment(GetCapsuleComponent());
    Camera->SetRelativeLocation(FVector(0.0, 0.0, 68.0));
    Camera->bUsePawnControlRotation = true;
    Camera->SetFieldOfView(90.0f);
    GetCharacterMovement()->MaxWalkSpeed = 420.0f;
}

void ASeaLinkWalker::SetupPlayerInputComponent(UInputComponent* Input)
{
    Super::SetupPlayerInputComponent(Input);
    Input->BindAxis(TEXT("MoveForward"), this, &ASeaLinkWalker::WalkForward);
    Input->BindAxis(TEXT("MoveRight"), this, &ASeaLinkWalker::WalkRight);
    Input->BindAxis(TEXT("Turn"), this, &ASeaLinkWalker::AddControllerYawInput);
    Input->BindAxis(TEXT("LookUp"), this, &ASeaLinkWalker::AddControllerPitchInput);
    Input->BindAction(TEXT("Jump"), IE_Pressed, this, &ASeaLinkWalker::Jump);
    Input->BindAction(TEXT("Jump"), IE_Released, this, &ASeaLinkWalker::StopJumping);
}

void ASeaLinkWalker::WalkForward(float Value)
{
    const FRotator Heading(0.0, GetControlRotation().Yaw, 0.0);
    AddMovementInput(Heading.Vector(), Value);
}

void ASeaLinkWalker::WalkRight(float Value)
{
    const FRotator Heading(0.0, GetControlRotation().Yaw + 90.0, 0.0);
    AddMovementInput(Heading.Vector(), Value);
}

ASeaLinkGameMode::ASeaLinkGameMode()
{
    DefaultPawnClass = ASeaLinkWalker::StaticClass();
}
