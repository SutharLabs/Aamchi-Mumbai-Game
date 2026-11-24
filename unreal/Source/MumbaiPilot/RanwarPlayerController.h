#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "Styling/SlateBrush.h"
#include "RanwarPlayerController.generated.h"

class FReply;
class SWidget;
class SEditableTextBox;
class UTexture2D;
class UGameViewportClient;
class ARanwarRoute;
class ARanwarTraffic;

UCLASS()
class MUMBAIPILOT_API ARanwarPlayerController : public APlayerController
{
    GENERATED_BODY()

public:
    void AddPitchInput(float Value) override;
    void AddYawInput(float Value) override;
    bool IsSubtitleEnabled() const { return Settings.bSubtitles; }
    bool ShouldShowSubtitleSpeaker() const { return Settings.bSpeakerNames; }
    bool IsSubtitleLarge() const { return Settings.bLargeSubtitles; }
    float GetDialogueVolume() const { return Settings.DialogueVolume; }
    bool IsLiveMapEnabled() const { return Settings.bLiveMap; }
    bool IsMenuOpen() const { return MenuWidget.IsValid(); }
    const ARanwarTraffic* GetMapTraffic() const;

protected:
    void BeginPlay() override;
    void EndPlay(const EEndPlayReason::Type EndPlayReason) override;
    void SetupInputComponent() override;

private:
    enum class EMenuPage : uint8
    {
        Main,
        Profiles,
        Settings,
        Help,
        Credits,
        Map,
        ConfirmNewGame,
    };

    struct FSettings
    {
        float MasterVolume = 1.0f;
        float DialogueVolume = 1.0f;
        float LookSensitivity = 1.0f;
        int32 GraphicsQuality = 0;
        bool bFullscreen = false;
        bool bVSync = true;
        bool bLiveMap = true;
        bool bSubtitles = true;
        bool bSpeakerNames = true;
        bool bLargeSubtitles = false;
    };

    UGameViewportClient* GetMenuViewport() const;
    ARanwarRoute* GetRoute() const;
    void InitializeRanwarView();
    void LoadTitleArt();
    void LoadPreferences();
    void SavePreferences() const;
    void ApplyMasterVolume();
    void HandleMenuBack();
    void RemoveMenuWidget();
    FReply ShowMenu(EMenuPage Page);
    FReply StartOrResume();
    FReply StartNewGame();
    FReply ConfirmNewGame();
    FReply ReturnToMainMenu();
    FReply AbandonJob();
    FReply ApplyPendingSettings();
    FReply SelectProfile(int32 Index);
    FReply EditProfile(bool bCreate);
    FReply QuitGame();

    UPROPERTY(Transient)
    TObjectPtr<UTexture2D> TitleBackdrop;

    UPROPERTY(Transient)
    TObjectPtr<UTexture2D> TitleMark;

    FSlateBrush TitleBackdropBrush;
    FSlateBrush TitleMarkBrush;
    TWeakObjectPtr<UGameViewportClient> MenuViewport;
    TWeakObjectPtr<ARanwarTraffic> MapTraffic;
    TSharedPtr<SWidget> MenuWidget;
    TSharedPtr<SEditableTextBox> ProfileNameInput;
    TArray<FString> ProfileNames;
    FText MenuNotice;
    FSettings Settings;
    FSettings PendingSettings;
    int32 ActiveProfile = 1;
    EMenuPage CurrentPage = EMenuPage::Main;
    bool bStartedPlaying = false;
    bool bPausedByMenu = false;
};
