# GitHub and asset reuse audit

Revised 19 November 2026. This is a static primary-source review, replacing the earlier popularity-based screening. No candidate has been cloned, built, benchmarked, or adopted. Upstream pages can change; record exact commits and tool versions during local evaluation. See the [feasibility review](FEASIBILITY_REVIEW.md).

## Candidate decisions

| Candidate | Evidence reviewed | Suggested role | Adoption gate |
|---|---|---|---|
| [OpenCity](https://github.com/webgl-games/opencity) | Actual configuration, traffic/pedestrian/switching scripts, MIT license, asset credits | Isolated walking/driving sandbox; evaluate selective reuse | Compatibility-rendered export, safe vehicle switching, measured handling, and adaptation cost for irregular left-hand roads |
| [Godot Easy Vehicle Physics](https://github.com/DAShoe1/Godot-Easy-Vehicle-Physics) | README and actual MIT license; example/demo asset sources listed separately | Compare arcade preset with simpler car controller | Chosen engine/backend works; curb/collision tests and physics CPU cost pass on baseline hardware |
| [Official Godot demo projects](https://github.com/godotengine/godot-demo-projects) | README and actual root MIT license | Selected camera/input/animation/loading examples | Match stable engine branch; inspect selected example assets; import/export succeeds |
| [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) | README, release matrix, actual MIT license | Authored dialogue and localization candidate | Compatible pinned release; mission-state integration, UI, and save behavior demonstrated |
| [Beehave](https://github.com/bitbrain/beehave) | README and actual MIT license | Optional later NPC behavior tooling | Demonstrated benefit over simple states; measured cost and compatible addon release |
| [BlenderGIS](https://github.com/domlysz/BlenderGIS) | Import functionality and GPLv3 editor-tool license | Offline OSM layout extraction/blockout | Working pinned Blender/addon pair; scale/origin and data provenance preserved |

Repository code licenses do not establish the provenance of every bundled model, texture, sound, or submodule. Record the actual selected files in [THIRD_PARTY.md](../docs/THIRD_PARTY.md) after adoption.

## OpenCity: concrete source findings

1. [`project.godot`](https://raw.githubusercontent.com/webgl-games/opencity/main/project.godot) identifies Godot 4.7 / Forward Plus and enables MSAA. A low-spec Compatibility configuration/material pass remains work to evaluate.
2. [`traffic.gd`](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/traffic.gd) explicitly uses right-hand lanes, rectangular grid constants duplicated from the city, and a fixed population count. Mumbai's intended traffic/road design requires different data conventions.
3. [`peds.gd`](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/peds.gd) uses rectangular block loops with duplicated grid settings; this is not evidence of arbitrary neighborhood navigation.
4. [`game.gd`](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/game.gd) uses a hard-coded key and fixed exit offset without a visible clearance/ground query. Safe exits and mapped input are slice requirements.
5. [`car.gd`](https://raw.githubusercontent.com/webgl-games/opencity/main/scripts/car.gd) uses VehicleBody3D. Treat handling/stability as something to prove rather than assuming either failure or production readiness.

Its [MIT license](https://raw.githubusercontent.com/webgl-games/opencity/main/LICENSE) and [credits](https://raw.githubusercontent.com/webgl-games/opencity/main/CREDITS.md) were inspected. Credits identify a Quaternius mannequin as CC0; compare the bundled license and original asset source before use. Retain upstream notices for adapted files.

## Vehicle-controller caution

GEVP's [README](https://raw.githubusercontent.com/DAShoe1/Godot-Easy-Vehicle-Physics/master/README.md) recommends at least 120 physics ticks and notes tick-rate-dependent behavior. Its [MIT license](https://raw.githubusercontent.com/DAShoe1/Godot-Easy-Vehicle-Physics/master/LICENSE) names multiple contributors. Preserve notices, check the separately sourced demo car, and benchmark the whole scene before selecting this controller. The preferred result is predictable arcade handling with an affordable CPU budget.

## Version and feature boundaries

- Official demos' [README](https://github.com/godotengine/godot-demo-projects#godot-versions) distinguishes development `master` from stable-version branches. Choose a matching branch and pin a revision.
- Dialogue Manager's [releases](https://github.com/nathanhoad/godot_dialogue_manager/releases) provide version-specific engine targets. Its [MIT license](https://raw.githubusercontent.com/nathanhoad/godot_dialogue_manager/main/LICENSE) was inspected. A stateless dialogue runtime does not own the game's objective/save state.
- Beehave's [README](https://github.com/bitbrain/beehave) describes engine/addon compatibility families and the tradeoff for simple AI; its [license](https://raw.githubusercontent.com/bitbrain/beehave/godot-4.x/LICENSE) was inspected. Keep it out of the initial stack unless needed.
- BlenderGIS's [GPLv3 license](https://github.com/domlysz/BlenderGIS/blob/master/LICENSE) concerns its code. Imported geographic data needs its own provenance/license record. Its older documented minimum Blender version does not prove current compatibility.

## Art candidates

| Publisher pack | Publisher license statement | Proposed use |
|---|---|---|
| [Kenney City Kit (Commercial)](https://kenney.nl/assets/city-kit-commercial) | CC0 | Background massing and generic props |
| [Quaternius Ultimate Buildings](https://quaternius.com/packs/ultimatetexturedbuildings.html) | Hold: see current catalogue license review | Modular shells and palette trials |
| [Quaternius Modular Streets](https://quaternius.com/packs/modularstreets.html) | Hold: see current catalogue license review | Prototype road/junction connections |

These are publisher-page findings; no downloaded pack has been checked. Test material count, scale, geometry, collision, and import behavior. Author/localize prominent Mumbai frontages and signage.

The [open model catalogue](OPEN_MODEL_CATALOGUE.md) supersedes the earlier art-source screening with specific model candidates, live license/download evidence, and the Quaternius licensing mismatch. Use that review before asset acquisition.

## Required evaluation record for every adoption

Record source URL, exact commit/tag and download hash where available, engine/tool versions, license/asset notices, owned modifications, and replacement cost. Track these separately: source inspected; imports/boots; exports; required behavior works; target-device performance passes. A source-inspected candidate has not passed the later checks.

Clone into an isolated evaluation folder after inspecting instructions. Compare the desired feature against the smallest viable alternative. Keep a component only when saved implementation time exceeds integration, performance, attribution, and maintenance costs. Do not assemble several overlapping whole-game frameworks.
