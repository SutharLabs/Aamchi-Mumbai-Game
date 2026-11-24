# Menus, HUD and voiced dialogue

Research and implementation brief for Aamchi Mumbai Game, 23 November 2026. The product target is one recognizable interface across the Godot iteration build and the Unreal playtest, with the existing Aamchi Mumbai artwork, original voices and readable information over the Ranwar street. The Windows 10 and Android 12 targets and device gates still apply. [Project brief](../docs/PROJECT_BRIEF.md) · [Phase tracker](../docs/PHASE_PROGRESS.md) · [Build workflow](../docs/BUILD_WORKFLOW.md)

## What established games do

The findings below come from publishers and engine-platform accessibility guidance. The Aamchi Mumbai choices in the last column are design inferences from those examples. Artwork, copy, interaction icons and composition remain original to this game.

| Game | Documented behavior | Aamchi Mumbai application |
| --- | --- | --- |
| Grand Theft Auto V | Pause leads to Settings, which covers controls, audio, camera and display. Vehicle controls have their own context. The official map guide describes exploring locations and setting a waypoint from the pause map. [Settings](https://support.rockstargames.com/articles/1FKIriVNBHL72WZ0hrVT8u/adjusting-settings-within-gtav) · [Vehicle input](https://support.rockstargames.com/articles/4b6n5wYVseQhdCo2bNpVY5/how-to-change-vehicle-controls-in-grand-theft-auto-v) · [Map](https://www.rockstargames.com/gta-online/guides/7772) | Give Map a clear pause entry. Preserve the existing live map toggle as the quick glance at location. Put walking and driving help next to each other, with labels based on the active input. |
| Forza Horizon 5 | Accessibility is reachable from first startup. Granular audio includes dialogue, and HUD and notifications can be adjusted. Background motion and notification duration can also be controlled. [Forza Support](https://support.forza.net/hc/en-us/articles/46523995129747-Forza-Horizon-5-Accessibility-Support) | Settings must be reachable before New Game and during pause. Start with master and dialogue levels. Leave the play view visible during pause while using a strong dark surface behind controls. |
| Assassin’s Creed Mirage | Audio, Controls, Screen and Interface group related settings. Subtitles start enabled, speaker names can be switched, text can be enlarged, and subtitle backgrounds and audio levels are adjustable. [Ubisoft accessibility features](https://www.ubisoft.com/en-us/help/assassins-creed-mirage/gameplay/article/accessibility-features-in-assassins-creed-mirage/000105449) | Text and voice are independent. Ship the main exchanges with readable subtitles and identifiable speakers. Offer a dialogue volume separate from effects. Keep categories short using one visual hierarchy. |
| Cyberpunk 2077 | The Accessibility tab gathers accessibility controls, including bottom-of-screen dialogue subtitles and background opacity. Later settings increase HUD size or remove distracting decoration. [CD PROJEKT RED support](https://support.cdprojektred.com/en/cyberpunk/mac/gameplay/issue/2939/accessibility-features-5) | Use a stable subtitle area distinct from location objectives and interaction prompts. Increase contrast and placement reliability before adding effects. Keep activity scoped HUD elements, such as vehicle instruments, tied to their context. |
| The Last of Us Part II | Its author documents subtitle size, background, speaker identity and distinct dialogue categories. Threat and awareness cues give players a visual channel for events otherwise signaled by sound. [Naughty Dog accessibility breakdown](https://blog.playstation.com/2020/06/09/the-last-of-us-part-ii-accessibility-features-detailed/) | Convey mission state and police status with text or recognizable shapes as well as color or sound. Give voice lines a visible speaker and a stable presentation through pause, resume and save restore. |

Xbox’s guidelines add short mixed-case subtitles with deliberate line breaks, customizable high-contrast backgrounds and distinct visible focus. Their examples also demonstrate confirmation and recovery for actions that could discard progress or settings. Android’s accessibility guidance provides a 48 × 48 dp touch-target baseline. Use those as design and measurement references on the actual output. [Xbox text](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/101) · [Subtitles](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/104) · [Navigation and focus](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/112) · [Destructive actions](https://learn.microsoft.com/en-us/xbox/accessibility/xbox-accessibility-guidelines/115) · [Android touch targets](https://developer.android.com/guide/topics/ui/accessibility/apps#touch-targets)

## Starting-state audit

This is the source audit at the start of the 23 November request. It records the mismatch that prompted the work.

| Surface | Godot | Unreal |
| --- | --- | --- |
| Title | Play, Profiles, Settings, Help, Credits and Quit. The active profile appears above Play. | New Game or Continue follows checkpoint state. Arrival in Ranwar is a separate synopsis. Settings, Controls, Credits and Quit follow. |
| Pause | Resume, Map, conditional Abandon job, Settings, Help, Credits and Main menu. Map includes routes, district services and landmarks. | Resume, Settings, Controls, Credits and Quit. The synopsis is title-only. |
| Settings | Master volume, camera sensitivity, Fullscreen and Live map. Apply saves. Keyboard and gamepad bindings are editable on non-touch builds. | Master volume, camera sensitivity, display mode, graphics quality and VSync. Editing applies immediately and Back saves custom preferences. Help lists actual controls. |
| Save scope | Versioned per-profile preferences, career and mission progress. | Native route save and game settings. Its Continue operates on that route save. |
| Gameplay interface | Objective and prompt share a top-left card. Lower-right navigation dock contains a live map and health, cash, alert and vehicle data. Touch has a dedicated control layer. | Canvas renders objective and distance, cash, alert and health, contextual prompt, and driving instruments. A nearby action can cover a route notice because both share the same display slot. |
| Dialogue | Arrival subtitle and authored response text use gameplay UI. | NPC responses use route notices. Pickup sound acknowledges completion without dialogue. |

Sources for the audit. [Godot menu](../prototype/startup/menu.gd) · [Godot preferences](../prototype/startup/preferences.gd) · [Godot HUD](../prototype/phase1_hud.gd) · [Unreal controller](../unreal/Source/MumbaiPilot/RanwarPlayerController.cpp) · [Unreal HUD](../unreal/Source/MumbaiPilot/RanwarGame.cpp) · [Unreal route](../unreal/Source/MumbaiPilot/RanwarRoute.cpp)

## Cross-engine interface contract

Treat the following as the design target. The phase tracker records which parts have been built and verified. Each engine owns its local save format and control implementation.

| Surface | Player-facing behavior |
| --- | --- |
| Main menu | **Continue**, **New Game**, **Profiles**, **Settings**, **Controls**, **Credits** and **Quit to Desktop** in that order. Offer Continue with recoverable progress and give New Game priority for a fresh profile. Protect an existing save if New Game would replace it. Keep the original title art and the playable arrival. Use the desktop exit on desktop platforms. |
| Pause | **Resume**, **Map**, **Settings**, **Controls** and **Main Menu** in that order. When a job is active, expose its valid management action near the map or job state. Confirm any destructive restart, job abandonment or loss of unsaved progress before committing it. |
| Audio | **Master volume** and **Dialogue volume**, each at 0–100%. Muting either must leave dialogue text readable when subtitles are enabled. |
| Display | **Fullscreen** or **Display mode** with equivalent labels and behavior on supported Windows builds. **Live map** independently hides and restores the small map. Keep graphics quality and synchronization controls where there is a real engine/platform implementation. A lower preset remains available for integrated graphics. |
| Controls | **Camera sensitivity** and a **Controls** page with on-foot and in-vehicle sections. Display active bindings when rebinding exists. Preserve entered profile data and existing binding functionality through this work. |
| Accessibility | **Subtitles** enabled by default, **Speaker names** enabled, and **Subtitle size** with a larger choice. Give text a stable, high-contrast background and keep critical objective/cash/alert feedback visible independently of dialogue. |
| Navigation | The same destination has the same label from title and pause. Back returns to the immediate parent and its originating control, then resumes gameplay only from the pause root. Use a visible focus shape, consistent confirmation/cancellation, and scroll access at compact sizes. |
| Settings persistence | **Apply Settings** commits the shared changes and reports the result. Back leaves the last applied values in effect. Preserve valid preferences when saving fails and keep display-mode changes recoverable. |

Existing features with only one implementation stay usable there while their counterpart is developed. This applies especially to native control rebinding, optional graphics tweaks and deeper map panels. A screen placed on the shared route should do useful work from normal game entry points. A report of full parity requires equivalent behavior and persistence as well as matching labels.

### Heads-up display and dialogue

- Use the top-left for current objective and approximate distance. Put health, cash and police state in a compact, predictable cluster. Print INR consistently and distinguish alert from clear by a label or icon as well as hue.
- Show speed and vehicle condition only while driving. Put the live map near a safe edge and keep touch controls and its toggle functional. Avoid overhead name labels, controls lists and long spans of text across the center of the play view.
- Give contact actions a short context prompt and an input glyph. A dialogue card is a separate bottom lane above critical touch controls. Use one speaker at a time, sentence case, a dark backing and short subtitle lines. Supply a readable text hold if audio is unavailable and leave story-critical directions in the objective or map.
- Author dialogue with stable cue IDs, original speaker names, approved text and owned or properly licensed source audio. Reuse one approved audio file per line in offline packages. Suggested initial coverage is the Anjali arrival directions and the core handoff, with further mission and story-lead voices checked against the same contract. Keep intermittent NPC barks and objective text separate from voices. Local casting and language review precede claims about authentic Mumbai speech.
- In gameplay, a successful contact transition emits its subtitle and one sound. Keep the dialogue behind the pause UI, restore its timing on resume, and stop it when returning to title or loading another session. An unavailable WAV must preserve readable text and gameplay progression. Repeated interaction during a line cannot create overlapping voice playback or a duplicate reward.

### Acceptance in both packaged builds

| Check | Evidence to retain |
| --- | --- |
| Fresh profile and returning profile | Title screenshots and save-state behavior. Start, pause, return to title, re-enter and confirm the checkpoint remains valid. |
| Menu parity | Enumerate ordered labels and destinations for title, pause and shared settings. Exercise keyboard and gamepad focus, Back and primary actions. Compare equivalent Windows screenshots at 1280 × 720 and a smaller landscape preview. |
| Persistence | Change both audio levels, subtitle display and camera sensitivity in pause. Resume and restart. Verify the saved values and live behavior. Confirm focus and view are usable after a display change and that any unsupported option is hidden by capability. |
| Voiced route | Trigger a real NPC conversation and capture the audio/subtitle cue, timing, exact text, attributed speaker and resulting objective. Repeat with zero dialogue volume, subtitles off, pause during a line and reload. |
| Small screen | Inspect subtitle wrapping, pause scrolling, touch-safe content and the overlap between action prompts and subtitle lanes. Simulated touch helps during iteration. Physical Android preserves its own acceptance gate. |
| Visual realism | Compare identical player-height views at the BEST shelter and its Hill Road approach. Check light direction, wall and curb materials, reflections appropriate to the surface, character contact and identifiable local details. Keep camera and exposure controlled in the before/after shots. Record frame-time and memory at the quality settings used. |

Use Godot F5 and focused checks for rapid UI, dialogue and composition iteration. Refresh the relevant shared inputs only when the playtest change is ready, then validate the packaged route in Unreal. Preserve the phone and integrated-GPU gate while developing the stronger optional Unreal look. [Playtest and export workflow](../docs/BUILD_WORKFLOW.md) · [Ranwar realism work order](RANWAR_REALISM_EXECUTION.md)
