#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "GameFramework/GameModeBase.h"
#include "SeaLinkGame.generated.h"

UCLASS()
class MUMBAIPILOT_API ASeaLinkWalker : public ACharacter
{
    GENERATED_BODY()

public:
    ASeaLinkWalker();

protected:
    void SetupPlayerInputComponent(UInputComponent* Input) override;

private:
    void WalkForward(float Value);
    void WalkRight(float Value);
};

UCLASS()
class MUMBAIPILOT_API ASeaLinkGameMode : public AGameModeBase
{
    GENERATED_BODY()

public:
    ASeaLinkGameMode();
};
