"""Stage the reviewed, native Nathan mesh, skeleton, loop, and material dependencies."""

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import tempfile


PACKAGES = {
    "SK_Ped_Nathan.uasset": "A6A8272CAB312553E0484DD32AF74FAE7F4203DB4604AD42917C18612D94A3FC",
    "SK_Ped_Nathan_Skeleton.uasset": "4A91908544EBD4195DE4C3458BC2ABA39E82A00E843E0A3321E4F6843DFA0421",
    "SK_Ped_Nathan_Anim.uasset": "7025922EF406A1B2FE0EEE0482A4453909D90C080344B8E6C550189EEB663B87",
    "rp_nathan_animated_003_mat_001.uasset": "396FF2B022B54A8EB01964195253026FE779D1C5E896C4CF37881E91AB2A7E98",
    "rp_nathan_animated_003_mat_baseColor.uasset": "BBA670497B2B51D97E5BF011662F43DC4C6BB69E841A960D2D15A657B6F59D05",
}
RELATIVE = Path("City/People/Nathan")


def sha256(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest().upper()


def plain_path(path):
    if path.resolve() != path:
        raise ValueError(f"Package path must not redirect through links: {path}")
    return path


def stage(content_root):
    project = Path(__file__).resolve().parent.parent
    source = plain_path(content_root.absolute() / RELATIVE)
    target = plain_path(project / "Content" / RELATIVE)
    if source == target or not source.is_dir():
        raise ValueError("Pass the extracted SandbarCity Content root as the separate source.")

    to_copy = []
    for name, digest in PACKAGES.items():
        original = plain_path(source / name)
        destination = plain_path(target / name)
        if not original.is_file() or sha256(original) != digest:
            raise ValueError(f"Missing or changed SandbarCity Nathan source package: {original}")
        if not destination.exists():
            to_copy.append((original, destination, digest))
        elif not destination.is_file() or sha256(destination) != digest:
            raise ValueError(f"Different item already occupies the native Nathan package: {destination}")

    if to_copy:
        target.mkdir(parents=True, exist_ok=True)
        plain_path(target)
    for original, destination, digest in to_copy:
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=target, prefix=".sandbar-nathan-", delete=False) as output:
                temporary = Path(output.name)
                with original.open("rb") as stream:
                    shutil.copyfileobj(stream, output)
            if sha256(temporary) != digest:
                raise RuntimeError(f"Source changed during Nathan staging: {original}")
            # Publish the verified bytes without replacing a concurrently created package.
            os.link(temporary, destination)
        finally:
            if temporary:
                temporary.unlink(missing_ok=True)
    print(f"SandbarCity Nathan packages installed: {len(to_copy)}. Already present: {len(PACKAGES) - len(to_copy)}.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--content-root", required=True, type=Path)
    stage(parser.parse_args().content_root)
