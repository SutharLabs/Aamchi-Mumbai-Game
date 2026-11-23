#!/usr/bin/env bash
set -euo pipefail

action=${1:-doctor}
if (( $# > 1 )); then
    printf '%s\n' 'Usage: bash unreal/Tools/remote-dev.sh {doctor|build-editor|import-ranwar}' >&2
    exit 2
fi

tool_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
repo_dir=$(cd -- "$tool_dir/../.." && pwd)
project="$repo_dir/unreal/AamchiMumbaiUnreal.uproject"
exchange="$repo_dir/builds/local/unreal-ranwar"
engine_home=${AMG_UE_INSTALL:-}

die() {
    printf '%s\n' "$*" >&2
    exit 2
}

check_engine() {
    [[ -n "$engine_home" ]] || die 'Set AMG_UE_INSTALL to the official Unreal 5.8 Linux installation directory.'
    local build_version="$engine_home/Engine/Build/Build.version"
    [[ -r "$build_version" ]] || die "Could not find Unreal Build.version under $engine_home/Engine/Build."
    python3 - "$build_version" <<'PYTHON'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    version = json.load(source)
major, minor, patch = (version[k] for k in ("MajorVersion", "MinorVersion", "PatchVersion"))
if (major, minor) != (5, 8):
    raise SystemExit(f"Ranwar expects Unreal Engine 5.8.x. Found {major}.{minor}.{patch}.")
print(f"Unreal Engine {major}.{minor}.{patch}")
PYTHON
    builder="$engine_home/Engine/Build/BatchFiles/Linux/Build.sh"
    editor="$engine_home/Engine/Binaries/Linux/UnrealEditor-Cmd"
    [[ -r "$builder" ]] || die "Missing Linux build script: $builder"
    if [[ ! -x "$editor" ]]; then
        editor="$engine_home/Engine/Binaries/Linux/UnrealEditor"
    fi
    [[ -x "$editor" ]] || die 'The Linux editor executable is missing from this installation.'
}

check_build_user() {
    [[ $(id -u) -ne 0 ]] || die 'Run Unreal as a non-root build account with access to the project and engine.'
    [[ -w "$repo_dir/unreal" ]] || die "The build account needs write access to $repo_dir/unreal."
}

case "$action" in
    doctor)
        printf 'Ranwar project: %s\n' "$project"
        printf 'Host: %s (%s), %s logical CPUs\n' "$(hostname)" "$(uname -m)" "$(getconf _NPROCESSORS_ONLN)"
        git -C "$repo_dir" rev-parse --verify HEAD
        df -h "$repo_dir"
        for device in /sys/class/drm/renderD*/device; do
            if [[ -r "$device/vendor" && -r "$device/device" ]]; then
                printf 'Graphics adapter: %s:%s\n' "$(cat "$device/vendor")" "$(cat "$device/device")"
            fi
        done
        if [[ -s "$exchange/ranwar-level.json" && -s "$exchange/omkar.glb" ]]; then
            printf '%s\n' 'Ranwar street and Omkar exchange present.'
        else
            printf '%s\n' "Generate the Ranwar street and Omkar exchange under $exchange."
        fi
        check_engine
        check_build_user
        ;;
    build-editor)
        check_engine
        check_build_user
        cd -- "$repo_dir/unreal"
        exec nice -n 10 bash "$builder" AamchiMumbaiUnrealEditor Linux Development "-Project=$project" -WaitMutex
        ;;
    import-ranwar)
        check_engine
        check_build_user
        [[ -s "$exchange/ranwar-level.json" && -s "$exchange/omkar.glb" ]] ||
            die "The Ranwar street and Omkar exchange must be present under $exchange."
        [[ ! -e "$repo_dir/unreal/Content/Ranwar/RanwarStreet.umap" ]] ||
            die 'RanwarStreet already exists. Keep the generated level or move it before rebuilding.'
        log="$exchange/unreal-import.log"
        cd -- "$repo_dir/unreal"
        nice -n 10 "$editor" "$project" -run=pythonscript "-script=$tool_dir/create_ranwar_level.py" \
            -unattended -nosound -NoP4 -NullRHI -stdout -FullStdOutLogOutput 2>&1 | tee "$log"
        [[ -s "$repo_dir/unreal/Content/Ranwar/RanwarStreet.umap" ]] &&
            grep -Fq 'Saved /Game/Ranwar/RanwarStreet with' "$log" ||
            die "RanwarStreet did not finish importing. See $log."
        ;;
    *)
        die 'Expected doctor, build-editor, or import-ranwar.'
        ;;
esac
