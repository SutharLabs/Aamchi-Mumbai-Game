# Remote Unreal development

Unreal Engine **5.8** is the development target for the next Aamchi Mumbai Game slice. The first level ports Ranwar's streets, shop entrances, boundaries and Omkar. The separately generated Sea Link level remains a visual study. [Ranwar exchange workflow](ContentSource/RANWAR_STREET.md)

## Remote workspace

The epyc24 development checkout is `/tmp/Aamchi-Mumbai-Game-Unreal` on branch `unreal/remote-dev`. It is a Git worktree beside the synchronized `/tmp/Aamchi-Mumbai-Game` mirror. Keep the development worktree for experiments and fast-forward it from reviewed `main` when clean. GitHub publication continues through the Ubuntu VM under the [repository workflow](../docs/AGENT_WORKFLOW.md#git-commit-synchronization-and-publishing).

The host provides 24 vCPUs, about 70 GiB of RAM, and a VMware virtual graphics adapter. The xeon32 modeling fallback provides 32 vCPUs, about 70 GiB of RAM, and the same class of virtual graphics. Use these CPUs for data conversion and Unreal compilation. A Windows workstation with a supported GPU is needed for rendered gameplay and Lumen performance measurements. [Epic Linux requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/linux-development-requirements-for-unreal-engine?application_version=5.8) · [Epic rendering requirements](https://dev.epicgames.com/documentation/en-us/unreal-engine/hardware-and-software-specifications-for-unreal-engine)

The Ranwar geometry batch uses Blender 5.3 via MotionGraphics' detached remote runner and shared heavy-job lock. The engine exchange directory is `builds/local/unreal-ranwar/` inside the Unreal worktree. It contains the FBX street and collision pieces, texture PNGs, `ranwar-level.json`, and the skinned `omkar.glb`. Keep generated exchange, imported assets, compiler output and editor logs in ignored directories.

The first epyc24 batch generated sixteen visible FBX sections, one collision section and 28 texture maps. All seventeen mesh hashes were verified on collection. The Omkar GLB has a 21-joint skin and idle, walk, and corrected run clips. [Street exchange and validation](ContentSource/RANWAR_STREET.md)

## Editor installation and first run

Epic's official Linux ZIP requires an Epic account and its download terms. Download the official **5.8.4 Linux precompiled ZIP** and extract it to a path accessible to the non-root Linux build account. Set `AMG_UE_INSTALL` to the directory that contains `Engine/`. The engine is a local toolchain under Epic's terms and belongs outside project Git. [Official Linux download](https://www.unrealengine.com/linux) · [Epic Linux setup](https://dev.epicgames.com/documentation/en-us/unreal-engine/linux-development-quickstart-for-unreal-engine?application_version=5.8) · [Unreal Engine EULA](https://www.unrealengine.com/eula/unreal)

From the Unreal worktree, under the account that will build the editor:

```bash
export AMG_UE_INSTALL=/absolute/path/to/UnrealEngine-5.8.4
bash unreal/Tools/remote-dev.sh doctor
bash unreal/Tools/remote-dev.sh build-editor
bash unreal/Tools/remote-dev.sh import-ranwar
```

The import command runs the editor with `-NullRHI`, captures the output, and checks for a newly saved `RanwarStreet.umap`. It uses Epic's Python editor commandlet. If a plugin or editor-only API needs the full editor session on the licensed build, repeat from a GPU-capable workstation using `-ExecutePythonScript` with the same script and inputs. [Epic editor Python commands](https://dev.epicgames.com/documentation/en-us/unreal-engine/scripting-the-unreal-editor-using-python?application_version=5.8)

The first Unreal acceptance run needs a compiled native module, imported Omkar skeleton and animations, playable movement and camera at St Peter's bus stop, clear doorway collision and landing foot contacts. Existing Godot story missions, traffic, career data and Android controls each require an Unreal port and equivalent tests. [Ranwar map and collision proof](ContentSource/RANWAR_STREET.md)
