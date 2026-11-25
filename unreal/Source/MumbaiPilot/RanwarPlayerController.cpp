#include "RanwarPlayerController.h"

#include "AudioDevice.h"
#include "Brushes/SlateColorBrush.h"
#include "Components/InputComponent.h"
#include "Engine/GameViewportClient.h"
#include "Engine/LocalPlayer.h"
#include "Engine/Texture2D.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "GameFramework/GameUserSettings.h"
#include "Input/Events.h"
#include "Input/Reply.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Misc/App.h"
#include "Misc/ConfigCacheIni.h"
#include "Misc/CommandLine.h"
#include "Misc/PackageName.h"
#include "Misc/Parse.h"
#include "RanwarGame.h"
#include "RanwarMap.h"
#include "RanwarProfiles.h"
#include "RanwarRoute.h"
#include "RanwarTraffic.h"
#include "Styling/CoreStyle.h"
#include "Styling/SlateTypes.h"
#include "TimerManager.h"
#include "Widgets/Images/SImage.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Input/SEditableTextBox.h"
#include "Widgets/Input/SSlider.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SScaleBox.h"
#include "Widgets/Layout/SScrollBox.h"
#include "Widgets/Layout/SWrapBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/SOverlay.h"
#include "Widgets/Text/STextBlock.h"

#define LOCTEXT_NAMESPACE "RanwarMenu"

namespace
{
    const FSlateColorBrush Backdrop(FLinearColor(0.009f, 0.022f, 0.042f, 0.80f));
    const FSlateColorBrush PanelBackground(FLinearColor(0.010f, 0.022f, 0.046f, 0.84f));
    const FLinearColor Ivory = FLinearColor::FromSRGBColor(FColor::FromHex(TEXT("F9F1E3")));
    const FLinearColor Muted = FLinearColor::FromSRGBColor(FColor::FromHex(TEXT("C3CFDE")));
    const FLinearColor Gold = FLinearColor::FromSRGBColor(FColor::FromHex(TEXT("F3C684")));
    const FLinearColor ButtonInk = FLinearColor::FromSRGBColor(FColor::FromHex(TEXT("27190D")));
    const FSlateColorBrush MapBackground(FLinearColor(0.009f, 0.021f, 0.034f));

    FSlateColorBrush ColorBrush(const TCHAR* Hex)
    {
        return FSlateColorBrush(FLinearColor::FromSRGBColor(FColor::FromHex(Hex)));
    }

    const FButtonStyle& MenuButtonStyle(bool bPrimary)
    {
        static const FButtonStyle Primary = FButtonStyle(FCoreStyle::Get().GetWidgetStyle<FButtonStyle>("Button"))
            .SetNormal(ColorBrush(TEXT("F3C684")))
            .SetHovered(ColorBrush(TEXT("FFDFAC")))
            .SetPressed(ColorBrush(TEXT("DBA859")));
        static const FButtonStyle Secondary = FButtonStyle(FCoreStyle::Get().GetWidgetStyle<FButtonStyle>("Button"))
            .SetNormal(ColorBrush(TEXT("192C44")))
            .SetHovered(ColorBrush(TEXT("344F70")))
            .SetPressed(ColorBrush(TEXT("405F81")));
        return bPrimary ? Primary : Secondary;
    }

    class SRanwarMenuRoot final : public SCompoundWidget
    {
    public:
        SLATE_BEGIN_ARGS(SRanwarMenuRoot) {}
            SLATE_DEFAULT_SLOT(FArguments, Content)
            SLATE_EVENT(FSimpleDelegate, OnBack)
        SLATE_END_ARGS()

        void Construct(const FArguments& Args)
        {
            OnBack = Args._OnBack;
            ChildSlot[Args._Content.Widget];
        }

        FReply OnPreviewKeyDown(const FGeometry& Geometry, const FKeyEvent& Event) override
        {
            const FKey Key = Event.GetKey();
            if (Key != EKeys::Escape && Key != EKeys::Gamepad_Special_Right && Key != EKeys::Gamepad_FaceButton_Right)
            {
                return FReply::Unhandled();
            }
            if (!Event.IsRepeat())
            {
                OnBack.ExecuteIfBound();
            }
            return FReply::Handled();
        }

    private:
        FSimpleDelegate OnBack;
    };

    TSharedRef<STextBlock> MenuText(TAttribute<FText> Text, int32 Size, const FLinearColor& Color, bool bWrap = true)
    {
        return SNew(STextBlock)
            .Text(MoveTemp(Text))
            .Font(FCoreStyle::GetDefaultFontStyle(Size >= 28 ? TEXT("Bold") : TEXT("Regular"), Size))
            .ColorAndOpacity(FSlateColor(Color))
            .AutoWrapText(bWrap);
    }

    constexpr int32 MaxGraphicsQuality = 3;

    FText QualityName(int32 Quality)
    {
        switch (Quality)
        {
        case 1: return LOCTEXT("Medium", "Medium");
        case 2: return LOCTEXT("High", "High");
        case 3: return LOCTEXT("Epic", "Epic");
        default: return LOCTEXT("Low", "Low");
        }
    }

    FText EnabledName(bool bEnabled)
    {
        return bEnabled ? LOCTEXT("On", "On") : LOCTEXT("Off", "Off");
    }
}

void ARanwarPlayerController::BeginPlay()
{
    Super::BeginPlay();
    GetWorldTimerManager().SetTimerForNextTick(this, &ARanwarPlayerController::InitializeRanwarView);
}

void ARanwarPlayerController::EndPlay(const EEndPlayReason::Type EndPlayReason)
{
    RemoveMenuWidget();
    Super::EndPlay(EndPlayReason);
}

void ARanwarPlayerController::SetupInputComponent()
{
    Super::SetupInputComponent();
    if (InputComponent)
    {
        InputComponent->BindKey(EKeys::Escape, IE_Pressed, this, &ARanwarPlayerController::HandleMenuBack)
            .bExecuteWhenPaused = true;
        InputComponent->BindKey(EKeys::Gamepad_Special_Right, IE_Pressed, this, &ARanwarPlayerController::HandleMenuBack)
            .bExecuteWhenPaused = true;
    }
}

UGameViewportClient* ARanwarPlayerController::GetMenuViewport() const
{
    if (!IsLocalController() || FApp::IsUnattended() || !FApp::CanEverRender() || !FSlateApplication::IsInitialized())
    {
        return nullptr;
    }
    const ULocalPlayer* LocalPlayer = GetLocalPlayer();
    return LocalPlayer ? LocalPlayer->ViewportClient.Get() : nullptr;
}

ARanwarRoute* ARanwarPlayerController::GetRoute() const
{
    const ARanwarGameMode* Mode = GetWorld() ? GetWorld()->GetAuthGameMode<ARanwarGameMode>() : nullptr;
    return Mode ? Mode->GetRoute() : nullptr;
}

const ARanwarTraffic* ARanwarPlayerController::GetMapTraffic() const
{
    return MapTraffic.Get();
}

void ARanwarPlayerController::InitializeRanwarView()
{
    if (IsLocalController() && Cast<ARanwarCharacter>(GetPawn()))
    {
        FRotator View = GetControlRotation();
        View.Pitch = -12.0;
        SetControlRotation(View);
        MapTraffic = Cast<ARanwarTraffic>(UGameplayStatics::GetActorOfClass(this, ARanwarTraffic::StaticClass()));
        LoadPreferences();
    }
    if (!MenuWidget && !FApp::IsUnattended() && FApp::CanEverRender())
    {
        EMenuPage InitialPage = EMenuPage::Main;
#if WITH_DEV_AUTOMATION_TESTS
        if (FParse::Param(FCommandLine::Get(), TEXT("RanwarSettingsPreview")))
        {
            InitialPage = EMenuPage::Settings;
        }
        else if (FParse::Param(FCommandLine::Get(), TEXT("RanwarMapPreview")))
        {
            bStartedPlaying = true;
            InitialPage = EMenuPage::Map;
        }
        else if (FParse::Param(FCommandLine::Get(), TEXT("RanwarPausePreview")))
        {
            bStartedPlaying = true;
        }
        else if (FParse::Param(FCommandLine::Get(), TEXT("RanwarProfilesPreview")))
        {
            InitialPage = EMenuPage::Profiles;
        }
#endif
        ShowMenu(InitialPage);
    }
}

void ARanwarPlayerController::AddPitchInput(float Value)
{
    Super::AddPitchInput(Value * Settings.LookSensitivity);
}

void ARanwarPlayerController::AddYawInput(float Value)
{
    Super::AddYawInput(Value * Settings.LookSensitivity);
}

void ARanwarPlayerController::LoadPreferences()
{
    ActiveProfile = RanwarProfiles::Load(ProfileNames);
    if (GConfig)
    {
        using RanwarProfiles::Section;
        GConfig->GetFloat(Section, TEXT("MasterVolume"), Settings.MasterVolume, GGameUserSettingsIni);
        GConfig->GetFloat(Section, TEXT("DialogueVolume"), Settings.DialogueVolume, GGameUserSettingsIni);
        GConfig->GetFloat(Section, TEXT("LookSensitivity"), Settings.LookSensitivity, GGameUserSettingsIni);
        GConfig->GetBool(Section, TEXT("LiveMap"), Settings.bLiveMap, GGameUserSettingsIni);
        GConfig->GetBool(Section, TEXT("Subtitles"), Settings.bSubtitles, GGameUserSettingsIni);
        GConfig->GetBool(Section, TEXT("SpeakerNames"), Settings.bSpeakerNames, GGameUserSettingsIni);
        GConfig->GetBool(Section, TEXT("LargeSubtitles"), Settings.bLargeSubtitles, GGameUserSettingsIni);
    }
    if (const UGameUserSettings* Video = UGameUserSettings::GetGameUserSettings())
    {
        Settings.bFullscreen = Video->GetFullscreenMode() != EWindowMode::Windowed;
        Settings.bVSync = Video->IsVSyncEnabled();
        Settings.GraphicsQuality = FMath::Clamp(Video->GetOverallScalabilityLevel(), 0, MaxGraphicsQuality);
    }
    const auto ReadFloat = [](float Value, float Minimum, float Maximum)
    {
        return FMath::IsFinite(Value) ? FMath::Clamp(Value, Minimum, Maximum) : 1.0f;
    };
    Settings.MasterVolume = ReadFloat(Settings.MasterVolume, 0.0f, 1.0f);
    Settings.DialogueVolume = ReadFloat(Settings.DialogueVolume, 0.0f, 1.0f);
    Settings.LookSensitivity = ReadFloat(Settings.LookSensitivity, 0.25f, 2.0f);
    ApplyMasterVolume();
}

void ARanwarPlayerController::SavePreferences() const
{
    if (GConfig)
    {
        using RanwarProfiles::Section;
        GConfig->SetFloat(Section, TEXT("MasterVolume"), Settings.MasterVolume, GGameUserSettingsIni);
        GConfig->SetFloat(Section, TEXT("DialogueVolume"), Settings.DialogueVolume, GGameUserSettingsIni);
        GConfig->SetFloat(Section, TEXT("LookSensitivity"), Settings.LookSensitivity, GGameUserSettingsIni);
        GConfig->SetBool(Section, TEXT("LiveMap"), Settings.bLiveMap, GGameUserSettingsIni);
        GConfig->SetBool(Section, TEXT("Subtitles"), Settings.bSubtitles, GGameUserSettingsIni);
        GConfig->SetBool(Section, TEXT("SpeakerNames"), Settings.bSpeakerNames, GGameUserSettingsIni);
        GConfig->SetBool(Section, TEXT("LargeSubtitles"), Settings.bLargeSubtitles, GGameUserSettingsIni);
        GConfig->Flush(false, GGameUserSettingsIni);
    }
}

void ARanwarPlayerController::ApplyMasterVolume()
{
    if (UWorld* World = GetWorld())
    {
        if (FAudioDeviceHandle Audio = World->GetAudioDevice(); Audio.IsValid())
        {
            Audio->SetTransientPrimaryVolume(Settings.MasterVolume);
        }
    }
}

void ARanwarPlayerController::LoadTitleArt()
{
    if (TitleBackdrop)
    {
        return;
    }
    TitleBackdrop = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Ranwar/UI/TitleBackdrop.TitleBackdrop"));
    TitleMark = LoadObject<UTexture2D>(nullptr, TEXT("/Game/Ranwar/UI/TitleMark.TitleMark"));
    TitleBackdropBrush.SetResourceObject(TitleBackdrop);
    TitleBackdropBrush.SetImageSize(FVector2D(1600.0, 900.0));
    TitleBackdropBrush.DrawAs = ESlateBrushDrawType::Image;
    TitleMarkBrush.SetResourceObject(TitleMark);
    TitleMarkBrush.SetImageSize(FVector2D(54.0, 54.0));
    TitleMarkBrush.DrawAs = ESlateBrushDrawType::Image;
}

void ARanwarPlayerController::HandleMenuBack()
{
    if (!MenuWidget)
    {
        ShowMenu(EMenuPage::Main);
    }
    else if (CurrentPage != EMenuPage::Main)
    {
        ShowMenu(EMenuPage::Main);
    }
    else if (bStartedPlaying)
    {
        StartOrResume();
    }
}

void ARanwarPlayerController::RemoveMenuWidget()
{
    if (MenuWidget && MenuViewport.IsValid())
    {
        MenuViewport->RemoveViewportWidgetContent(MenuWidget.ToSharedRef());
    }
    MenuWidget.Reset();
    MenuViewport.Reset();
    ProfileNameInput.Reset();
}

FReply ARanwarPlayerController::ShowMenu(EMenuPage Page)
{
    UGameViewportClient* Viewport = GetMenuViewport();
    if (!Viewport)
    {
        return FReply::Unhandled();
    }

    if (!MenuWidget)
    {
        bPausedByMenu = !UGameplayStatics::IsGamePaused(this) && SetPause(true);
        SetIgnoreMoveInput(true);
        SetIgnoreLookInput(true);
    }
    if (Page != CurrentPage)
    {
        MenuNotice = FText::GetEmpty();
    }
    if (Page == EMenuPage::Settings && (!MenuWidget || CurrentPage != EMenuPage::Settings))
    {
        PendingSettings = Settings;
    }
    RemoveMenuWidget();
    CurrentPage = Page;
    if (!bStartedPlaying)
    {
        LoadTitleArt();
    }
    const bool bIllustrated = !bStartedPlaying && IsValid(TitleBackdrop);

    TSharedRef<SVerticalBox> Content = SNew(SVerticalBox);
    TSharedPtr<SWidget> FirstFocus;
    TArray<TPair<FText, TSharedRef<SWidget>>> SettingsSections;
    const FText GameCopyright = LOCTEXT("GameCopyright", "© 2026 SutharLabs");
    const auto MakeButton = [](TAttribute<FText> Text, FOnClicked Action, bool bPrimary)
    {
        return SNew(SButton)
            .OnClicked(MoveTemp(Action))
            .ContentPadding(FMargin(15.0f, 9.0f))
            .ButtonStyle(&MenuButtonStyle(bPrimary))
            [
                MenuText(MoveTemp(Text), 18, bPrimary ? ButtonInk : Ivory)
            ];
    };
    const auto AddButton = [&FirstFocus, &MakeButton](SVerticalBox& Parent, TAttribute<FText> Text,
        FOnClicked Action, bool bPrimary = false)
    {
        const TSharedRef<SButton> Button = MakeButton(MoveTemp(Text), MoveTemp(Action), bPrimary);
        if (!FirstFocus)
        {
            FirstFocus = Button;
        }
        Parent.AddSlot().AutoHeight().Padding(0.0f, 3.0f)[Button];
    };
    const auto AddText = [&Content](const FText& Text, int32 Size, const FLinearColor& Color, bool bWrap = true)
    {
        Content->AddSlot().AutoHeight().Padding(0, 0, 0, 9)[MenuText(Text, Size, Color, bWrap)];
    };
    const auto AddNotice = [this, &Content]()
    {
        Content->AddSlot().AutoHeight().Padding(1, 7)
        [
            MenuText(TAttribute<FText>::CreateLambda([this]() { return MenuNotice; }), 16, Gold)
        ];
    };
    const auto PageAction = [this](EMenuPage Destination)
    {
        return FOnClicked::CreateUObject(this, &ARanwarPlayerController::ShowMenu, Destination);
    };
    const ARanwarRoute* Route = GetRoute();

    if (Page == EMenuPage::Main && bStartedPlaying)
    {
        AddText(LOCTEXT("Paused", "Paused"), 46, Ivory);
        AddText(LOCTEXT("PausedName", "Omkar Shirodkar"), 19, Muted);
        AddButton(*Content, LOCTEXT("Resume", "Resume"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::StartOrResume), true);
        if (MapTraffic.IsValid())
        {
            AddButton(*Content, LOCTEXT("MapButton", "Map"), PageAction(EMenuPage::Map));
        }
        if (Route && Route->CanAbandonJob())
        {
            AddButton(*Content, LOCTEXT("AbandonJobButton", "Abandon job"),
                FOnClicked::CreateUObject(this, &ARanwarPlayerController::AbandonJob));
        }
        AddButton(*Content, LOCTEXT("SettingsButton", "Settings"), PageAction(EMenuPage::Settings));
        AddButton(*Content, LOCTEXT("ControlsButton", "Controls"), PageAction(EMenuPage::Help));
        AddButton(*Content, LOCTEXT("MainMenuButton", "Main Menu"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::ReturnToMainMenu));
    }
    else if (Page == EMenuPage::Main)
    {
        TSharedRef<SHorizontalBox> Identity = SNew(SHorizontalBox);
        if (TitleMark)
        {
            Identity->AddSlot().AutoWidth().Padding(0, 0, 14, 0)
            [
                SNew(SImage).Image(&TitleMarkBrush).Visibility(EVisibility::HitTestInvisible)
            ];
        }
        Identity->AddSlot().AutoWidth().VAlign(VAlign_Center)
        [
            MenuText(LOCTEXT("District", "RANWAR, BANDRA WEST"), 17, Gold, false)
        ];
        Content->AddSlot().AutoHeight().Padding(0, 0, 0, 10)[Identity];
        AddText(LOCTEXT("Title", "Aamchi\nMumbai Game"), 46, Ivory, false);
        AddText(LOCTEXT("TitleMeaning", "Our Mumbai"), 22, Gold);
        if (ProfileNames.IsValidIndex(ActiveProfile - 1))
        {
            AddText(FText::Format(LOCTEXT("TitleProfile", "Profile  ·  {0}"),
                FText::FromString(ProfileNames[ActiveProfile - 1])), 17, Muted);
        }
        const bool bHasProgress = Route && Route->HasSavedProgress();
        if (bHasProgress)
        {
            AddButton(*Content, LOCTEXT("Continue", "Continue"),
                FOnClicked::CreateUObject(this, &ARanwarPlayerController::StartOrResume), true);
        }
        AddButton(*Content, LOCTEXT("NewGame", "New Game"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::StartNewGame), !bHasProgress);
        AddButton(*Content, LOCTEXT("ProfilesButton", "Profiles"), PageAction(EMenuPage::Profiles));
        AddButton(*Content, LOCTEXT("SettingsButton", "Settings"), PageAction(EMenuPage::Settings));
        AddButton(*Content, LOCTEXT("ControlsButton", "Controls"), PageAction(EMenuPage::Help));
        AddButton(*Content, LOCTEXT("CreditsButton", "Credits"), PageAction(EMenuPage::Credits));
#if PLATFORM_DESKTOP
        AddButton(*Content, LOCTEXT("QuitButton", "Quit to Desktop"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::QuitGame));
#endif
        Content->AddSlot().AutoHeight().Padding(1, 9, 0, 0)[MenuText(GameCopyright, 14, Muted)];
    }
    else if (Page == EMenuPage::Profiles)
    {
        AddText(LOCTEXT("ProfilesTitle", "Profiles"), 34, Ivory);
        AddText(LOCTEXT("ProfilesDescription", "Select the local profile for your next session."), 16, Muted);
        for (int32 Index = 0; Index < ProfileNames.Num(); ++Index)
        {
            const bool bSelected = Index + 1 == ActiveProfile;
            const FText Name = FText::FromString(ProfileNames[Index]);
            AddButton(*Content, bSelected ? FText::Format(LOCTEXT("ActiveProfile", "{0}  ·  Active"), Name) : Name,
                FOnClicked::CreateUObject(this, &ARanwarPlayerController::SelectProfile, Index), bSelected);
        }
        ProfileNameInput = SNew(SEditableTextBox)
            .HintText(LOCTEXT("ProfileNameHint", "Enter a name"))
            .MinDesiredWidth(220.0f);
        Content->AddSlot().AutoHeight().Padding(0, 12, 0, 4)
        [
            SNew(SBox).MinDesiredHeight(40.0f)[ProfileNameInput.ToSharedRef()]
        ];
        if (ProfileNames.Num() < RanwarProfiles::MaxProfiles)
        {
            AddButton(*Content, LOCTEXT("CreateProfile", "Create profile"),
                FOnClicked::CreateUObject(this, &ARanwarPlayerController::EditProfile, true));
        }
        AddButton(*Content, LOCTEXT("RenameProfile", "Rename active profile"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::EditProfile, false));
        AddNotice();
    }
    else if (Page == EMenuPage::ConfirmNewGame)
    {
        AddText(LOCTEXT("ConfirmNewGameTitle", "Start a new game?"), 34, Ivory);
        AddText(LOCTEXT("ConfirmNewGameDescription",
            "This starts Omkar's story over for the active profile. To keep its progress, create a separate profile."), 18, Ivory);
        AddButton(*Content, LOCTEXT("Cancel", "Cancel"), PageAction(EMenuPage::Main), true);
        AddButton(*Content, LOCTEXT("ConfirmNewGame", "Start New Game"),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::ConfirmNewGame));
        AddNotice();
    }
    else if (Page == EMenuPage::Settings)
    {
        const auto AddGroup = [&Content, &SettingsSections](const FText& Caption)
        {
            const TSharedRef<STextBlock> Heading = MenuText(Caption, 19, Gold);
            Content->AddSlot().AutoHeight().Padding(0, 9, 0, 3)[Heading];
            SettingsSections.Emplace(Caption, Heading);
        };
        const auto AddSlider = [this, &Content, &FirstFocus](const FText& Caption, float FSettings::* Member,
            float Lower, float Upper, float Step, bool bPercentage)
        {
            Content->AddSlot().AutoHeight().Padding(5, 6, 5, 3)
            [
                SNew(SHorizontalBox)
                + SHorizontalBox::Slot().FillWidth(1.0f)[MenuText(Caption, 17, Ivory)]
                + SHorizontalBox::Slot().AutoWidth()
                [
                    MenuText(TAttribute<FText>::CreateLambda([this, Member, bPercentage]()
                    {
                        const float Value = PendingSettings.*Member;
                        if (bPercentage)
                        {
                            return FText::AsPercent(Value);
                        }
                        FNumberFormattingOptions Format;
                        Format.SetMaximumFractionalDigits(2);
                        return FText::Format(LOCTEXT("SensitivityMultiplier", "{0}×"), FText::AsNumber(Value, &Format));
                    }), 17, Muted)
                ]
            ];
            const TSharedRef<SSlider> Slider = SNew(SSlider)
                .Value_Lambda([this, Member]() { return PendingSettings.*Member; })
                .MinValue(Lower).MaxValue(Upper).StepSize(Step)
                .SliderBarColor(Muted).SliderHandleColor(Gold)
                .OnValueChanged_Lambda([this, Member](float Value)
                {
                    PendingSettings.*Member = Value;
                    MenuNotice = FText::GetEmpty();
                });
            if (!FirstFocus)
            {
                FirstFocus = Slider;
            }
            Content->AddSlot().AutoHeight().Padding(5, 1, 5, 8)[SNew(SBox).MinDesiredHeight(26)[Slider]];
        };
        const auto AddToggle = [this, &Content, &AddButton](const FText& Caption, bool FSettings::* Member,
            const FText& On, const FText& Off)
        {
            AddButton(*Content, TAttribute<FText>::CreateLambda([this, Caption, Member, On, Off]()
            {
                return FText::Format(LOCTEXT("SettingsRow", "{0}   ·   {1}"), Caption, PendingSettings.*Member ? On : Off);
            }), FOnClicked::CreateLambda([this, Member]()
            {
                PendingSettings.*Member = !(PendingSettings.*Member);
                MenuNotice = FText::GetEmpty();
                return FReply::Handled();
            }));
        };
        AddGroup(LOCTEXT("GameplayGroup", "Gameplay"));
        AddToggle(LOCTEXT("LiveMap", "Live Map"), &FSettings::bLiveMap, EnabledName(true), EnabledName(false));
        AddGroup(LOCTEXT("ControlsGroup", "Controls"));
        AddSlider(LOCTEXT("CameraSensitivity", "Camera Sensitivity"), &FSettings::LookSensitivity, 0.25f, 2.0f, 0.05f, false);
        AddGroup(LOCTEXT("AudioGroup", "Audio"));
        AddSlider(LOCTEXT("MasterVolume", "Master Volume"), &FSettings::MasterVolume, 0.0f, 1.0f, 0.01f, true);
        AddSlider(LOCTEXT("DialogueVolume", "Dialogue Volume"), &FSettings::DialogueVolume, 0.0f, 1.0f, 0.01f, true);
        AddGroup(LOCTEXT("DisplayGroup", "Display"));
        if (FPlatformProperties::SupportsWindowedMode())
        {
            AddToggle(LOCTEXT("WindowMode", "Window Mode"), &FSettings::bFullscreen,
                LOCTEXT("Fullscreen", "Fullscreen"), LOCTEXT("Windowed", "Windowed"));
        }
        AddButton(*Content, TAttribute<FText>::CreateLambda([this]()
        {
            return FText::Format(LOCTEXT("GraphicsQuality", "Graphics Quality   ·   {0}"), QualityName(PendingSettings.GraphicsQuality));
        }), FOnClicked::CreateLambda([this]()
        {
            PendingSettings.GraphicsQuality = (PendingSettings.GraphicsQuality + 1) % (MaxGraphicsQuality + 1);
            MenuNotice = FText::GetEmpty();
            return FReply::Handled();
        }));
        AddToggle(LOCTEXT("VSync", "VSync"), &FSettings::bVSync, EnabledName(true), EnabledName(false));
        AddGroup(LOCTEXT("AccessibilityGroup", "Accessibility"));
        AddToggle(LOCTEXT("Subtitles", "Subtitles"), &FSettings::bSubtitles, EnabledName(true), EnabledName(false));
        AddToggle(LOCTEXT("SpeakerNames", "Speaker Names"), &FSettings::bSpeakerNames, EnabledName(true), EnabledName(false));
        AddToggle(LOCTEXT("SubtitleSize", "Subtitle Size"), &FSettings::bLargeSubtitles,
            LOCTEXT("Large", "Large"), LOCTEXT("Standard", "Standard"));
    }
    else if (Page == EMenuPage::Map)
    {
        AddText(LOCTEXT("MapTitle", "Ranwar map"), 34, Ivory);
        const APawn* LocalPawn = GetPawn();
        const ARanwarTraffic* Traffic = MapTraffic.Get();
        if (Traffic && LocalPawn)
        {
            FVector Destination;
            TOptional<FVector> Objective;
            if (Route && Route->GetWaypoint(Destination))
            {
                Objective = Destination;
            }
            Content->AddSlot().AutoHeight().Padding(0, 4, 0, 13)
            [
                SNew(SBorder).BorderImage(&MapBackground).Padding(0)
                [
                    RanwarMap::BuildWidget(*Traffic, LocalPawn->GetActorLocation(), LocalPawn->GetActorForwardVector(), Objective)
                ]
            ];
            AddText(LOCTEXT("MapPlayer", "Gold arrow  ·  Your position"), 16, Gold);
            AddText(LOCTEXT("MapFootway", "Dashed path  ·  Nagrana Lane"), 16, Muted);
            if (Objective.IsSet())
            {
                AddText(LOCTEXT("MapObjective", "Orange diamond  ·  Objective"), 16, Muted);
            }
            AddText(LOCTEXT("MapAttribution", "© OpenStreetMap contributors"), 13, Muted);
        }
    }
    else if (Page == EMenuPage::Credits)
    {
        AddText(LOCTEXT("CreditsTitle", "Credits"), 34, Ivory);
        AddText(LOCTEXT("CreditsDeveloper", "Aamchi Mumbai Game\nSutharLabs"), 21, Gold);
        AddText(GameCopyright, 15, Muted);
        AddText(LOCTEXT("CreditsUnrealTrademark", "Aamchi Mumbai Game uses Unreal® Engine. Unreal® is a trademark or registered trademark of Epic Games, Inc. in the United States of America and elsewhere."), 16, Ivory);
        AddText(LOCTEXT("CreditsUnrealCopyright", "Unreal® Engine, Copyright 1998 – 2026, Epic Games, Inc. All rights reserved."), 16, Ivory);
        AddText(LOCTEXT("CreditsMap", "Map data: OpenStreetMap contributors, ODbL 1.0."), 17, Ivory);
        AddText(LOCTEXT("CreditsSources", "See the Notices folder for model, sound, motion and other source credits."), 17, Muted);
    }
    else
    {
        AddText(LOCTEXT("ControlsTitle", "Controls"), 34, Ivory);
        AddText(LOCTEXT("ControlFootGroup", "On foot"), 19, Gold);
        AddText(LOCTEXT("ControlMovement", "W A S D / Left stick   Walk"), 17, Ivory);
        AddText(LOCTEXT("ControlLook", "Mouse / Right stick   Look around"), 17, Ivory);
        AddText(LOCTEXT("ControlRun", "Left Shift / X   Run while moving"), 17, Ivory);
        AddText(LOCTEXT("ControlJump", "Space / A   Jump"), 17, Ivory);
        AddText(LOCTEXT("ControlInteract", "E / B   Talk, enter or mount"), 17, Ivory);
        AddText(LOCTEXT("ControlDrivingGroup", "Driving"), 19, Gold);
        AddText(LOCTEXT("ControlDriving", "W A S D / Left stick   Steer and control speed"), 17, Ivory);
        AddText(LOCTEXT("ControlBrake", "Space / A   Brake"), 17, Ivory);
        AddText(LOCTEXT("ControlHorn", "H / Left stick click   Sound the horn"), 17, Ivory);
        AddText(LOCTEXT("ControlExit", "E / B   Exit when stopped"), 17, Ivory);
        AddText(LOCTEXT("ControlPause", "Esc / Menu   Pause"), 17, Ivory);
    }
    if (Page != EMenuPage::Main && Page != EMenuPage::ConfirmNewGame && Page != EMenuPage::Settings)
    {
        AddButton(*Content, LOCTEXT("BackButton", "Back"), PageAction(EMenuPage::Main));
    }

    const TSharedRef<SScrollBox> Scroll = SNew(SScrollBox)
        .ScrollWhenFocusChanges(EScrollWhenFocusChanges::InstantScroll)
        .NavigationScrollPadding(10.0f)
        + SScrollBox::Slot()[Content];
    TSharedRef<SWidget> Panel = Scroll;
    if (Page == EMenuPage::Settings)
    {
        TSharedRef<SHorizontalBox> SettingsIdentity = SNew(SHorizontalBox);
        if (TitleMark)
        {
            SettingsIdentity->AddSlot().AutoWidth().VAlign(VAlign_Center).Padding(0, 0, 8, 0)
            [
                SNew(SBox).WidthOverride(28.0f).HeightOverride(28.0f)
                [SNew(SImage).Image(&TitleMarkBrush).Visibility(EVisibility::HitTestInvisible)]
            ];
        }
        SettingsIdentity->AddSlot().AutoWidth().VAlign(VAlign_Center)
        [MenuText(LOCTEXT("SettingsGameName", "AAMCHI MUMBAI GAME"), 15, Gold, false)];
        const TSharedRef<SWrapBox> Shortcuts = SNew(SWrapBox)
            .PreferredSize(660.0f)
            .UseAllottedSize(true)
            .InnerSlotPadding(FVector2D(6.0f, 6.0f));
        for (const auto& Section : SettingsSections)
        {
            Shortcuts->AddSlot()
            [
                SNew(SButton).ContentPadding(FMargin(8, 6)).ButtonStyle(&MenuButtonStyle(false))
                .OnClicked_Lambda([WeakScroll = TWeakPtr<SScrollBox>(Scroll), Anchor = TWeakPtr<SWidget>(Section.Value)]()
                {
                    if (const TSharedPtr<SScrollBox> ActiveScroll = WeakScroll.Pin())
                    {
                        ActiveScroll->ScrollDescendantIntoView(Anchor.Pin(), true, EDescendantScrollDestination::TopOrLeft);
                    }
                    return FReply::Handled();
                })
                [
                    MenuText(Section.Key, 16, Ivory, false)
                ]
            ];
        }
        Panel = SNew(SVerticalBox)
            + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 5)[SettingsIdentity]
            + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 13)[MenuText(LOCTEXT("SettingsTitle", "Settings"), 40, Ivory)]
            + SVerticalBox::Slot().AutoHeight().Padding(0, 0, 0, 9)[Shortcuts]
            + SVerticalBox::Slot().FillHeight(1.0f)[Scroll]
            + SVerticalBox::Slot().AutoHeight().Padding(0, 4, 0, 3)
            [
                SNew(SBox).MinDesiredHeight(22.0f)
                [
                    MenuText(TAttribute<FText>::CreateLambda([this]() { return MenuNotice; }), 16, Gold)
                ]
            ]
            + SVerticalBox::Slot().AutoHeight()
            [
                SNew(SHorizontalBox)
                + SHorizontalBox::Slot().FillWidth(1.0f).Padding(0, 0, 8, 0)
                [
                    MakeButton(LOCTEXT("ApplySettingsButton", "Apply Settings"),
                        FOnClicked::CreateUObject(this, &ARanwarPlayerController::ApplyPendingSettings), true)
                ]
                + SHorizontalBox::Slot().AutoWidth()
                [
                    MakeButton(LOCTEXT("BackButton", "Back"), PageAction(EMenuPage::Main), false)
                ]
            ];
    }

    TSharedRef<SOverlay> Layout = SNew(SOverlay).Clipping(EWidgetClipping::ClipToBounds);
    if (bIllustrated)
    {
        Layout->AddSlot()
        [
            SNew(SScaleBox).Stretch(EStretch::ScaleToFill).Clipping(EWidgetClipping::ClipToBounds)
            [
                SNew(SImage).Image(&TitleBackdropBrush).Visibility(EVisibility::HitTestInvisible)
            ]
        ];
    }
    else
    {
        Layout->AddSlot()[SNew(SBorder).BorderImage(&Backdrop).Padding(0)];
    }
    const bool bUseArtMargin = bIllustrated && Page == EMenuPage::Main;
    const float PanelWidth = Page == EMenuPage::Settings ? 705.0f : Page == EMenuPage::Map ? 540.0f : 465.0f;
    const float LeftMargin = Page == EMenuPage::Settings ? 76.0f : 48.0f;
    Layout->AddSlot().HAlign(HAlign_Left).VAlign(VAlign_Center).Padding(FMargin(LeftMargin, 22, 24, 22))
    [
        SNew(SScaleBox).Stretch(EStretch::ScaleToFitX).StretchDirection(EStretchDirection::DownOnly)
        [
            SNew(SBox).WidthOverride(PanelWidth)
            .MaxDesiredHeight_Lambda([WeakViewport = TWeakObjectPtr<UGameViewportClient>(Viewport)]()
            {
                FVector2D Size(1280.0, 720.0);
                if (const UGameViewportClient* ActiveViewport = WeakViewport.Get())
                {
                    ActiveViewport->GetViewportSize(Size);
                }
                return FOptionalSize(static_cast<float>(FMath::Max(150.0, Size.Y - 50.0)));
            })
            [
                SNew(SBorder).BorderImage(bUseArtMargin ? FCoreStyle::Get().GetBrush("NoBrush") : &PanelBackground)
                .Padding(bUseArtMargin ? 0.0f : 18.0f)
                [
                    Panel
                ]
            ]
        ]
    ];

    MenuWidget = SNew(SRanwarMenuRoot)
        .OnBack(FSimpleDelegate::CreateUObject(this, &ARanwarPlayerController::HandleMenuBack))
        [
            Layout
        ];

    MenuViewport = Viewport;
    Viewport->AddViewportWidgetContent(MenuWidget.ToSharedRef(), 50);

    bShowMouseCursor = true;
    FInputModeGameAndUI InputMode;
    InputMode.SetWidgetToFocus(FirstFocus);
    InputMode.SetHideCursorDuringCapture(false);
    InputMode.SetLockMouseToViewportBehavior(EMouseLockMode::DoNotLock);
    SetInputMode(InputMode);
    return FReply::Handled();
}

FReply ARanwarPlayerController::StartOrResume()
{
    bStartedPlaying = true;
    RemoveMenuWidget();
    if (bPausedByMenu)
    {
        SetPause(false);
        bPausedByMenu = false;
    }
    SetIgnoreMoveInput(false);
    SetIgnoreLookInput(false);
    bShowMouseCursor = false;
    SetInputMode(FInputModeGameOnly());
    return FReply::Handled();
}

FReply ARanwarPlayerController::StartNewGame()
{
    const ARanwarRoute* Route = GetRoute();
    return Route && Route->HasSavedProgress() ? ShowMenu(EMenuPage::ConfirmNewGame) : StartOrResume();
}

FReply ARanwarPlayerController::ConfirmNewGame()
{
    if (ARanwarRoute* Route = GetRoute(); Route && !Route->ResetProgress())
    {
        MenuNotice = LOCTEXT("RestartFailed", "Starting over could not be saved. Your current progress is still available.");
        return FReply::Handled();
    }
    return StartOrResume();
}

FReply ARanwarPlayerController::ReturnToMainMenu()
{
    if (const UWorld* World = GetWorld())
    {
        const FString MapPath = FPackageName::GetLongPackagePath(World->GetOutermost()->GetName())
            / UGameplayStatics::GetCurrentLevelName(this, true);
        UGameplayStatics::OpenLevel(this, FName(*MapPath));
    }
    return FReply::Handled();
}

FReply ARanwarPlayerController::AbandonJob()
{
    if (ARanwarRoute* Route = GetRoute())
    {
        Route->AbandonJob();
    }
    return StartOrResume();
}

FReply ARanwarPlayerController::ApplyPendingSettings()
{
    Settings = PendingSettings;
    ApplyMasterVolume();
    if (ARanwarRoute* Route = GetRoute())
    {
        Route->SetDialogueVolume(Settings.DialogueVolume);
    }
    if (UGameUserSettings* Video = UGameUserSettings::GetGameUserSettings())
    {
        const EWindowMode::Type DesiredMode = Settings.bFullscreen ? EWindowMode::WindowedFullscreen : EWindowMode::Windowed;
        const bool bWindowModeChanged = FPlatformProperties::SupportsWindowedMode() && Video->GetFullscreenMode() != DesiredMode;
        if (bWindowModeChanged)
        {
            Video->SetFullscreenMode(DesiredMode);
            Video->ApplyResolutionSettings(false);
            Video->ConfirmVideoMode();
        }
        Video->SetVSyncEnabled(Settings.bVSync);
        Video->SetOverallScalabilityLevel(Settings.GraphicsQuality);
        Video->ApplyNonResolutionSettings();
        Video->SaveSettings();
    }
    SavePreferences();
    MenuNotice = LOCTEXT("SettingsSaved", "Settings saved.");
    return FReply::Handled();
}

FReply ARanwarPlayerController::SelectProfile(int32 Index)
{
    if (!ProfileNames.IsValidIndex(Index))
    {
        return FReply::Unhandled();
    }
    ActiveProfile = Index + 1;
    RanwarProfiles::Save(ProfileNames, ActiveProfile);
    if (ARanwarRoute* Route = GetRoute())
    {
        Route->SelectProfile(ActiveProfile);
    }
    MenuNotice = LOCTEXT("ProfileSelected", "Profile selected.");
    return ShowMenu(EMenuPage::Profiles);
}

FReply ARanwarPlayerController::EditProfile(bool bCreate)
{
    if (!ProfileNameInput || !ProfileNames.IsValidIndex(ActiveProfile - 1))
    {
        return FReply::Unhandled();
    }
    const FString NewName = RanwarProfiles::NormalizeName(ProfileNameInput->GetText().ToString());
    if (NewName.IsEmpty())
    {
        MenuNotice = LOCTEXT("ProfileNameInvalid", "Enter a name up to 32 characters.");
        return FReply::Handled();
    }
    const int32 ExistingIndex = ProfileNames.IndexOfByPredicate([&NewName](const FString& Existing)
    {
        return Existing.Equals(NewName, ESearchCase::IgnoreCase);
    });
    if (ExistingIndex != INDEX_NONE && (bCreate || ExistingIndex != ActiveProfile - 1))
    {
        MenuNotice = LOCTEXT("ProfileNameDuplicate", "A profile already uses that name.");
        return FReply::Handled();
    }
    if (bCreate)
    {
        if (ProfileNames.Num() >= RanwarProfiles::MaxProfiles)
        {
            return FReply::Handled();
        }
        SelectProfile(ProfileNames.Add(NewName));
        MenuNotice = LOCTEXT("ProfileCreated", "Profile created.");
    }
    else
    {
        ProfileNames[ActiveProfile - 1] = NewName;
        RanwarProfiles::Save(ProfileNames, ActiveProfile);
        MenuNotice = LOCTEXT("ProfileRenamed", "Profile renamed.");
        ShowMenu(EMenuPage::Profiles);
    }
    return FReply::Handled();
}

FReply ARanwarPlayerController::QuitGame()
{
    UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, false);
    return FReply::Handled();
}

#undef LOCTEXT_NAMESPACE
