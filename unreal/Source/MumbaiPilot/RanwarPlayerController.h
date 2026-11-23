#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "RanwarPlayerController.generated.h"

class FReply;
class SWidget;
class UGameViewportClient;

UCLASS()
class MUMBAIPILOT_API ARanwarPlayerController : public APlayerController
{
    GENERATED_BODY()

protected:
    void BeginPlay() override;
    void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    void SetupInputComponent() override;

private:
    enum class EMenuPage : uint8
    {
        Main,
        Arrival,
        Settings,
        Help,
    };

    UGameViewportClient* GetMenuViewport() const;
    void OpenStartupMenu();
    void HandleMenuBack();
    void RemoveMenuWidget();
    FReply ShowMenu(EMenuPage Page);
    FReply StartOrResume();
    FReply CycleGraphicsQuality();
    FReply ToggleVSync();
    FReply QuitGame();
    FText GetPrimaryActionText() const;
    FText GetGraphicsQualityText() const;
    FText GetVSyncText() const;

    TWeakObjectPtr<UGameViewportClient> MenuViewport;
    TSharedPtr<SWidget> MenuWidget;
    EMenuPage CurrentPage = EMenuPage::Main;
    bool bStartedPlaying = false;
    bool bPausedByMenu = false;
};
