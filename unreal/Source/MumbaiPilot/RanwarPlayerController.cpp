#include "RanwarPlayerController.h"

#include "Brushes/SlateColorBrush.h"
#include "Components/InputComponent.h"
#include "Engine/GameViewportClient.h"
#include "Engine/LocalPlayer.h"
#include "Engine/World.h"
#include "Framework/Application/SlateApplication.h"
#include "GameFramework/GameUserSettings.h"
#include "Input/Events.h"
#include "Input/Reply.h"
#include "InputCoreTypes.h"
#include "Kismet/GameplayStatics.h"
#include "Kismet/KismetSystemLibrary.h"
#include "Misc/App.h"
#include "RanwarGame.h"
#include "RanwarRoute.h"
#include "Styling/CoreStyle.h"
#include "TimerManager.h"
#include "Widgets/Input/SButton.h"
#include "Widgets/Layout/SBorder.h"
#include "Widgets/Layout/SBox.h"
#include "Widgets/Layout/SScaleBox.h"
#include "Widgets/SBoxPanel.h"
#include "Widgets/SCompoundWidget.h"
#include "Widgets/SOverlay.h"
#include "Widgets/Text/STextBlock.h"

#define LOCTEXT_NAMESPACE "RanwarMenu"

namespace
{
    const FSlateColorBrush Backdrop(FLinearColor(0.015f, 0.019f, 0.024f, 0.82f));
    const FSlateColorBrush PanelBackground(FLinearColor(0.024f, 0.038f, 0.048f, 1.0f));
    const FSlateColorBrush Accent(FLinearColor(0.85f, 0.42f, 0.13f, 1.0f));
    const FLinearColor Ivory(0.98f, 0.93f, 0.83f);
    const FLinearColor Muted(0.65f, 0.72f, 0.73f);

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
            if (Key != EKeys::Escape && Key != EKeys::Gamepad_Special_Right)
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

    TSharedRef<STextBlock> MenuText(TAttribute<FText> Text, int32 Size, const FLinearColor& Color)
    {
        return SNew(STextBlock)
            .Text(MoveTemp(Text))
            .Font(FCoreStyle::GetDefaultFontStyle(Size >= 28 ? TEXT("Bold") : TEXT("Regular"), Size))
            .ColorAndOpacity(FSlateColor(Color))
            .AutoWrapText(true);
    }

    FText QualityName(int32 Quality)
    {
        switch (Quality)
        {
        case 0: return LOCTEXT("Low", "Low");
        case 1: return LOCTEXT("Medium", "Medium");
        case 2: return LOCTEXT("High", "High");
        case 3: return LOCTEXT("Epic", "Epic");
        case 4: return LOCTEXT("Cinematic", "Cinematic");
        default: return LOCTEXT("Custom", "Custom");
        }
    }
}

void ARanwarPlayerController::BeginPlay()
{
    Super::BeginPlay();
    if (!FApp::IsUnattended() && FApp::CanEverRender())
    {
        GetWorldTimerManager().SetTimerForNextTick(this, &ARanwarPlayerController::OpenStartupMenu);
    }
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

void ARanwarPlayerController::OpenStartupMenu()
{
    if (!MenuWidget)
    {
        ShowMenu(EMenuPage::Main);
    }
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
    RemoveMenuWidget();
    CurrentPage = Page;

    TSharedRef<SVerticalBox> Content = SNew(SVerticalBox);
    TSharedPtr<SButton> FirstButton;
    const auto AddButton = [&Content, &FirstButton](TAttribute<FText> Text, FOnClicked Action, bool bPrimary = false)
    {
        const TSharedRef<SButton> Button = SNew(SButton)
            .OnClicked(MoveTemp(Action))
            .ContentPadding(FMargin(14.0f, 8.0f))
            .ButtonColorAndOpacity(bPrimary ? FLinearColor(0.48f, 0.22f, 0.08f) : FLinearColor(0.17f, 0.24f, 0.28f))
            [
                MenuText(MoveTemp(Text), 18, Ivory)
            ];
        if (!FirstButton)
        {
            FirstButton = Button;
        }
        Content->AddSlot().AutoHeight().Padding(0.0f, 3.0f)[Button];
    };
    const auto AddText = [&Content](const FText& Text, int32 Size, const FLinearColor& Color)
    {
        Content->AddSlot().AutoHeight().Padding(0.0f, 0.0f, 0.0f, 10.0f)[MenuText(Text, Size, Color)];
    };
    const auto PageAction = [this](EMenuPage Destination)
    {
        return FOnClicked::CreateUObject(this, &ARanwarPlayerController::ShowMenu, Destination);
    };

    if (Page == EMenuPage::Main)
    {
        AddText(LOCTEXT("Brand", "Aamchi Mumbai Game"), 34, Ivory);
        AddText(bStartedPlaying ? LOCTEXT("Paused", "Paused") : LOCTEXT("Location", "Ranwar, Bandra West"), 17, Muted);
        AddButton(TAttribute<FText>::Create(TAttribute<FText>::FGetter::CreateUObject(this, &ARanwarPlayerController::GetPrimaryActionText)),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::StartOrResume), true);
        if (!bStartedPlaying)
        {
            AddButton(LOCTEXT("ArrivalButton", "Arrival in Ranwar"), PageAction(EMenuPage::Arrival));
        }
        AddButton(LOCTEXT("SettingsButton", "Settings"), PageAction(EMenuPage::Settings));
        AddButton(LOCTEXT("HelpButton", "Help"), PageAction(EMenuPage::Help));
        AddButton(LOCTEXT("QuitButton", "Quit"), FOnClicked::CreateUObject(this, &ARanwarPlayerController::QuitGame));
    }
    else if (Page == EMenuPage::Arrival)
    {
        AddText(LOCTEXT("ArrivalTitle", "Arrival in Ranwar"), 34, Ivory);
        AddText(LOCTEXT("ArrivalDescription",
            "Omkar steps off a BEST bus by St Peter's Church in Bandra West. Anjali is waiting nearby to help him get settled."),
            18, Ivory);
    }
    else if (Page == EMenuPage::Settings)
    {
        AddText(LOCTEXT("SettingsTitle", "Settings"), 34, Ivory);
        AddText(LOCTEXT("SettingsDescription", "Graphics changes apply immediately and are saved on this device."), 17, Muted);
        AddButton(TAttribute<FText>::Create(TAttribute<FText>::FGetter::CreateUObject(this, &ARanwarPlayerController::GetGraphicsQualityText)),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::CycleGraphicsQuality));
        AddButton(TAttribute<FText>::Create(TAttribute<FText>::FGetter::CreateUObject(this, &ARanwarPlayerController::GetVSyncText)),
            FOnClicked::CreateUObject(this, &ARanwarPlayerController::ToggleVSync));
    }
    else
    {
        AddText(LOCTEXT("ControlsTitle", "Controls"), 34, Ivory);
        AddText(LOCTEXT("ControlMovement", "W A S D or left stick   Walk and drive"), 17, Ivory);
        AddText(LOCTEXT("ControlLook", "Mouse or right stick   Look around"), 17, Ivory);
        AddText(LOCTEXT("ControlRun", "Left Shift or X   Run on foot"), 17, Ivory);
        AddText(LOCTEXT("ControlJump", "Space or A   Jump on foot or brake in a vehicle"), 17, Ivory);
        AddText(LOCTEXT("ControlInteract", "E or B   Talk, interact, enter or exit a vehicle"), 17, Ivory);
        AddText(LOCTEXT("ControlPause", "Esc or Menu   Pause"), 17, Ivory);
    }
    if (Page != EMenuPage::Main)
    {
        AddButton(LOCTEXT("BackButton", "Back"), PageAction(EMenuPage::Main));
    }

    MenuWidget = SNew(SRanwarMenuRoot)
        .OnBack(FSimpleDelegate::CreateUObject(this, &ARanwarPlayerController::HandleMenuBack))
        [
            SNew(SOverlay)
            + SOverlay::Slot()[SNew(SBorder).BorderImage(&Backdrop).Padding(0.0f)]
            + SOverlay::Slot().HAlign(HAlign_Center).VAlign(VAlign_Center).Padding(24.0f)
            [
                SNew(SScaleBox).Stretch(EStretch::ScaleToFit).StretchDirection(EStretchDirection::DownOnly)
                [
                    SNew(SBox).WidthOverride(510.0f)
                    [
                        SNew(SVerticalBox)
                        + SVerticalBox::Slot().AutoHeight()
                        [
                            SNew(SBox).HeightOverride(4.0f)
                            [
                                SNew(SBorder).BorderImage(&Accent).Padding(0.0f)
                            ]
                        ]
                        + SVerticalBox::Slot().AutoHeight()
                        [
                            SNew(SBorder).BorderImage(&PanelBackground).Padding(26.0f)
                            [
                                Content
                            ]
                        ]
                    ]
                ]
            ]
        ];

    MenuViewport = Viewport;
    Viewport->AddViewportWidgetContent(MenuWidget.ToSharedRef(), 50);

    bShowMouseCursor = true;
    FInputModeGameAndUI InputMode;
    InputMode.SetWidgetToFocus(FirstButton);
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

FText ARanwarPlayerController::GetPrimaryActionText() const
{
    if (bStartedPlaying)
    {
        return LOCTEXT("Resume", "Resume");
    }
    const ARanwarGameMode* Mode = GetWorld() ? GetWorld()->GetAuthGameMode<ARanwarGameMode>() : nullptr;
    const ARanwarRoute* Route = Mode ? Mode->GetRoute() : nullptr;
    return Route && Route->HasSavedProgress() ? LOCTEXT("Continue", "Continue") : LOCTEXT("NewGame", "New Game");
}

FText ARanwarPlayerController::GetGraphicsQualityText() const
{
    const UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings();
    return Settings
        ? FText::Format(LOCTEXT("QualityLabel", "Graphics quality   {0}"), QualityName(Settings->GetOverallScalabilityLevel()))
        : LOCTEXT("QualityUnavailable", "Graphics quality unavailable");
}

FReply ARanwarPlayerController::CycleGraphicsQuality()
{
    if (UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings())
    {
        const int32 Current = Settings->GetOverallScalabilityLevel();
        Settings->SetOverallScalabilityLevel(Current >= 0 && Current < 3 ? Current + 1 : 0);
        Settings->ApplyNonResolutionSettings();
        Settings->SaveSettings();
    }
    return FReply::Handled();
}

FText ARanwarPlayerController::GetVSyncText() const
{
    const UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings();
    return !Settings ? LOCTEXT("VSyncUnavailable", "VSync unavailable")
        : Settings->IsVSyncEnabled() ? LOCTEXT("VSyncOn", "VSync   On") : LOCTEXT("VSyncOff", "VSync   Off");
}

FReply ARanwarPlayerController::ToggleVSync()
{
    if (UGameUserSettings* Settings = UGameUserSettings::GetGameUserSettings())
    {
        Settings->SetVSyncEnabled(!Settings->IsVSyncEnabled());
        Settings->ApplyNonResolutionSettings();
        Settings->SaveSettings();
    }
    return FReply::Handled();
}

FReply ARanwarPlayerController::QuitGame()
{
    UKismetSystemLibrary::QuitGame(this, this, EQuitPreference::Quit, false);
    return FReply::Handled();
}

#undef LOCTEXT_NAMESPACE
