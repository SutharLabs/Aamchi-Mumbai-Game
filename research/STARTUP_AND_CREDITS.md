# Startup identity and credits

The title introduces present-day Ranwar, Bandra West, Mumbai. The opening uses one neighborhood-scale image to connect the game name to the streets players can explore. The Windows splash identifies the game while Unreal initializes. The title menu uses native text and controls, with a dedicated Credits page.

## Aamchi Mumbai

**आमची मुंबई** reads as **“Our Mumbai.”** `आमची` is the feminine possessive form used with a feminine noun. The Maharashtra State Bureau’s Marathi–English school dictionary demonstrates that form in its example for *our*. The University of Chicago’s Marathi teaching materials describe adjective agreement and the inclusive and exclusive forms of the Marathi first person plural. This title uses an everyday Marathi expression with an affectionate sense of belonging. [Balbharati school dictionary, entry for *our*](https://books.ebalbharati.in/pdfs/dictionary.pdf) · [Marathi in Context](https://www.lib.uchicago.edu/e/su/southasia/marathi/marathi-in-context.html)

The municipal corporation has used the exact Devanagari phrase in its own portal banner. That documents civic usage of the wording. The game uses **Aamchi Mumbai Game** as its English display name and an original identity for the project. [BMC portal screenshot in its application guide](https://www.mcgm.gov.in/irj/go/km/docs/documents/Dog%20Licenses/Manual%20for%20Application%20for%20Dog%20License.pdf)

## Visual cues from Bandra

The Mumbai Metropolitan Region Heritage Conservation Society’s surveyed Bandra precinct study describes Ranwar’s close-set buildings, narrow street frontages, pitched Mangalore-tile roofs and street-facing verandahs. BMC’s heritage material locates the Bandra Village precinct along Hill Road, Waroda Road and Chapel Road. The state tourism department describes the wider suburban setting through its fishing villages, sea link, sunsets, street food and transport. These sources support a human-scale neighborhood composition inside a contemporary coastal metropolis. [MMR-HCS Bandra precinct study](https://mmrhcs.org.in/images/documents/projects/precinct-studies/Study_of_Bandra_Precinct/Bandra%20vol%20I.pdf) · [BMC heritage list, Bandra Village entry](https://portal.mcgm.gov.in/irj/go/km/docs/documents/MCGM%20Department%20List/Chief%20Engineer%20%28Development%20Plan%29/Docs/HERITAGE/Heritage%20List%20%26%20Govt.%20Notifications/Heritage%20List.pdf) · [Maharashtra Tourism, Mumbai Suburban](https://maharashtratourism.gov.in/districts/mumbai-suburban/)

For the title art, use blue-hour light, a narrow lane, verandahs and warm windows, with a black-and-yellow auto-rickshaw as a contemporary street cue. Put the strongest visual detail on the right and leave the left quiet for the menu. Rain sheen and the exact view are art direction. The underlying street layout and its source date are documented in the Ranwar map reference. [Ranwar map and acquisition](BANDRA_REFERENCE_AREA_AND_MAP.md)

## Windows splash and title menu

- Naughty Dog designed *The Last of Us Part II* main menu around a scene that reflects the story. Aamchi Mumbai uses its rainy Ranwar-inspired lane to establish place from the first screen. [Naughty Dog on the menu](https://blog.playstation.com/2020/09/25/the-last-of-us-day-2020-preview-celebrate-with-new-posters-collectibles-and-more/)
- Supergiant revised the artwork, animations and logo of *Hades* together. Aamchi Mumbai repeats its rickshaw mark, title typography and warm accent across the Windows splash, title menu and Settings. [Supergiant patch notes](https://www.supergiantgames.com/blog/hades-updates/)
- The native Windows splash is the original rainy backdrop with the game name, **Our Mumbai**, and the SutharLabs copyright baked into the BMP. Unreal displays it during startup with no added movie or fixed delay. The title menu keeps Credits reachable and the packaged Notices folder carries the longer attribution. [Unreal Windows splash settings](https://dev.epicgames.com/documentation/unreal-engine/windows-settings-in-the-unreal-engine-project-settings?application_version=5.8) · [Splash generator](../unreal/Tools/build_ranwar_splash.py) · [Project license](../LICENSE)

## Credits patterns in open-source games

| Example | Observed pattern | Application to Aamchi Mumbai Game |
|---|---|---|
| SuperTuxKart | The main menu’s About command opens a dedicated Credits screen with a back button and project website link. | Give Credits its own view and a direct return to the menu. [Menu handler](https://github.com/supertuxkart/stk-code/blob/master/src/states_screens/main_menu_screen.cpp#L514-L529) · [Credits screen layout](https://github.com/supertuxkart/stk-code/blob/master/data/gui/screens/credits.stkgui) |
| Luanti | An About tab in the main menu displays grouped credits read from a dedicated data file and provides a project URL. | Keep grouped attribution data in one place and make the links accessible. [Menu registration](https://github.com/luanti-org/luanti/blob/master/builtin/mainmenu/init.lua#L98-L110) · [About tab implementation](https://github.com/luanti-org/luanti/blob/master/builtin/mainmenu/tab_about.lua) |
| OpenTTD | A Help menu command opens a dedicated About window while the game is running. | Keep credits reachable from the pause menu as well as from startup. [Help menu and About command](https://github.com/OpenTTD/OpenTTD/blob/master/src/toolbar_gui.cpp#L993-L1104) |

The project uses an original menu layout and puts the Credits entry in the main and pause menus. This gives players a way to reach credits while the game is paused and keeps the driving HUD clear.

## Controls guide and gameplay HUD

Rockstar documents separate on-foot and vehicle controls in GTA V's pause settings. Forza Horizon 5 places remapping in settings and lets players pare down HUD elements independently. Aamchi Mumbai Game puts the complete keyboard or touch guide under **Help → Controls** from the title and pause menus. The gameplay HUD shows short contextual prompts, feedback and vehicle speed where relevant. [Rockstar Games Support](https://support.rockstargames.com/articles/4b6n5wYVseQhdCo2bNpVY5/how-to-change-vehicle-controls-in-grand-theft-auto-v) · [Forza Horizon 5 accessibility support](https://support.forza.net/hc/en-us/articles/4409280058259-Forza-Horizon-5-Accessibility-Support)

## Attribution and distributed notices

- **OpenStreetMap.** The OpenStreetMap Foundation explicitly permits a game’s credits page or menu to carry attribution. The dedicated screen credits OpenStreetMap contributors and links to copyright information, ODbL 1.0, the input extract and the adapted route. Retain the map notices and license with distributed builds and keep the extract and actual derived route publicly reachable. ODbL §4.6 addresses the data offer when a publicly used Produced Work comes from a Derivative Database. [OSMF computer-games guidance](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines#Computer_games_and_simulations) · [ODbL legal code](https://opendatacommons.org/licenses/odbl/1-0/) · [Project map attribution and data offer](../assets/maps/reference/bandra-ranwar-modern-osm-2026-11-20/ATTRIBUTION.md)
- **100STYLE.** The credits give the dataset title, creators, source and CC BY 4.0 link, and describe the adaptation. Keep the existing attribution text in the Windows package as well. [Dataset](https://www.ianxmason.com/100style/) · [CC BY 4.0 legal code, §3](https://creativecommons.org/licenses/by/4.0/legalcode.en#s3) · [Packaged notice](../prototype/character/motion/100STYLE-ATTRIBUTION.txt)
- **Godot.** The credits identify the engine and provide the Godot license link. Keep the full engine and bundled dependency notices in `Godot-NOTICES.txt` in the Windows package. [Godot’s license compliance guide](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html)
- **Noto Sans Devanagari.** The Marathi title uses the bundled font from Google Fonts source commit `06bfe0d62a98375cb09c942fa18e68bd32cff057`. The credits name the font, its authors and the SIL Open Font License 1.1. Keep the full license with the bundled font and the packaged game. [Upstream font project](https://github.com/notofonts/devanagari) · [Pinned Google Fonts source](https://github.com/google/fonts/tree/06bfe0d62a98375cb09c942fa18e68bd32cff057/ofl/notosansdevanagari) · [Bundled license](../prototype/startup/art/NotoSansDevanagari-OFL.txt)

The in-game text and links are maintained in [credits_data.gd](../prototype/startup/credits_data.gd). [Third-party ledger](../docs/THIRD_PARTY.md)
