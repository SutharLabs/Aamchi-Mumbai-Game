#!/usr/bin/env python3
"""Deploy and control the game's reviewed overnight worker over existing SSH.

No passwords, package installation, remote shell interpolation, tar extraction,
or source sync-back. Only the project deployment allowlist can leave the laptop.
"""
from __future__ import annotations

import argparse
import base64
from dataclasses import dataclass
from datetime import datetime, timezone
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import tempfile
import time
from typing import Any

MAX_JSON = 2 * 1024 * 1024
MAX_DEPLOY_FILE = 2 * 1024 * 1024
MAX_DEPLOY_TOTAL = 16 * 1024 * 1024
MAX_COLLECT_FILE = 128 * 1024 * 1024
MAX_CLOCK_RTT_SECONDS = 10.0
MAX_CLOCK_OFFSET_SECONDS = 1800.0
EXACT_DEPLOY = frozenset({"tools/night_queue.py", "tools/build_queued_model.py",
                          "jobs/night-queue.json", "docs/OVERNIGHT_MODELING.md"})
SAFE_NAME = re.compile(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}\Z")


class RemoteError(ValueError):
    pass


def relative_parts(relative: str) -> tuple[str, ...]:
    if not isinstance(relative, str) or not relative or len(relative) > 512:
        raise RemoteError("Expected a bounded relative path")
    if "\\" in relative or ":" in relative or "\0" in relative:
        raise RemoteError("Use a forward-slash relative path")
    parts = relative.split("/")
    if any(not part or part in {".", ".."} for part in parts):
        raise RemoteError("Path aliases and traversal are not allowed")
    if PurePosixPath(relative).is_absolute():
        raise RemoteError("Absolute project paths are not allowed")
    return tuple(parts)


def confined(root: Path, relative: str, *, required: bool = False) -> Path:
    path = root
    for part in relative_parts(relative):
        path = path / part
        if path.is_symlink() or (hasattr(path, "is_junction") and path.is_junction()):
            raise RemoteError(f"Symlink/junction refused: {relative}")
    if not path.resolve().is_relative_to(root.resolve()):
        raise RemoteError("Path escapes the project")
    if required and not path.is_file():
        raise RemoteError(f"Required project file missing: {relative}")
    return path


def allowed_deploy(relative: str) -> bool:
    try:
        parts = relative_parts(relative)
    except RemoteError:
        return False
    if relative in EXACT_DEPLOY:
        return True
    return (len(parts) == 3 and SAFE_NAME.fullmatch(parts[2]) is not None and
            ((parts[:2] == ("tools", "modeling") and parts[2].endswith(".py")) or
             (parts[:2] == ("jobs", "specs") and parts[2].endswith(".json"))))


def allowed_output(relative: str) -> bool:
    try:
        parts = relative_parts(relative)
    except RemoteError:
        return False
    return (len(parts) == 4 and parts[:2] == ("assets", "generated") and
            re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", parts[2]) is not None and
            parts[3] in {"model.blend", "model.glb", "preview.png", "front.png",
                         "rear.png", "side.png", "report.json"})


def collection_target(relative: str, node_name: str) -> str:
    """Map remote diagnostics away from the local worker's operational state."""
    if allowed_output(relative):
        return relative
    parts = relative_parts(relative)
    if relative in {".night-queue/state.json", ".night-queue/supervisor.log",
                    ".night-queue/supervisor.pid"}:
        return f"reports/remote/{node_name}/{parts[-1]}"
    if (len(parts) == 3 and parts[:2] == (".night-queue", "logs") and
            SAFE_NAME.fullmatch(parts[2]) and parts[2].endswith(".log")):
        return f"reports/remote/{node_name}/logs/{parts[2]}"
    raise RemoteError(f"Remote collection path not allowed: {relative}")


@dataclass(frozen=True)
class RemoteConfig:
    node_name: str = "epyc24"
    host: str = "10.64.100.159"
    user: str = "root"
    port: int = 22
    remote_root: str = "/root/motion/mumbai-gully-heat"
    blender: str = "/root/motion/.tools/blender-5.3.0/blender"
    shared_lock: str = "/root/motion/.jobs/heavy.lock"
    threads: int = 8

    def __post_init__(self):
        if not isinstance(self.node_name, str) or not re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,31}", self.node_name):
            raise RemoteError("Invalid node_name")
        if not isinstance(self.host, str) or not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9.-]{0,251}[A-Za-z0-9])?", self.host):
            raise RemoteError("Invalid SSH host")
        if not isinstance(self.user, str) or not re.fullmatch(r"[a-z_][a-z0-9_-]{0,31}", self.user):
            raise RemoteError("Invalid SSH user")
        if type(self.port) is not int or not 1 <= self.port <= 65535:
            raise RemoteError("port must be 1–65535")
        if type(self.threads) is not int or not 1 <= self.threads <= 64:
            raise RemoteError("threads must be 1–64")
        for value in (self.remote_root, self.blender, self.shared_lock):
            if not isinstance(value, str) or not re.fullmatch(r"/[A-Za-z0-9_./-]+", value):
                raise RemoteError("Remote paths must be absolute safe POSIX paths")
            if any(p in {".", "..", ""} for p in value.split("/")[1:]):
                raise RemoteError("Remote path traversal/aliases refused")
        root = PurePosixPath(self.remote_root)
        if not root.is_relative_to(PurePosixPath("/root/motion")) or root.name != "mumbai-gully-heat":
            raise RemoteError("remote_root must be the game directory under /root/motion")
        if (not PurePosixPath(self.blender).is_relative_to(PurePosixPath("/root/motion/.tools")) or
                PurePosixPath(self.blender).name != "blender"):
            raise RemoteError("Blender must be an existing motion toolchain binary")
        if self.shared_lock != "/root/motion/.jobs/heavy.lock":
            raise RemoteError("Use the existing shared-machine heavy-job lock")

    @classmethod
    def load(cls, root: Path, relative: str = "jobs/remote.json") -> "RemoteConfig":
        path = confined(root, relative, required=True)
        if path.stat().st_size > MAX_JSON:
            raise RemoteError("Remote configuration is too large")
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        if not isinstance(data, dict) or set(data) - set(cls.__dataclass_fields__):
            raise RemoteError("Unknown remote configuration fields")
        return cls(**data)


def ssh_command(config: RemoteConfig) -> list[str]:
    return ["ssh", "-T", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
            "-o", "ConnectTimeout=10", "-p", str(config.port), "--",
            f"{config.user}@{config.host}", "python3", "-"]


# This is our fixed server program. User/config data enters through JSON, never
# through a remote shell command. It touches only guarded project/lock paths.
REMOTE_PROGRAM = r'''
import base64, fcntl, hashlib, json, math, os, re, stat, subprocess, sys, tempfile, time
from datetime import datetime, timezone, timedelta
from pathlib import Path, PurePosixPath

MAX_FILE = 128 * 1024 * 1024
EXACT = {"tools/night_queue.py", "tools/build_queued_model.py", "jobs/night-queue.json", "docs/OVERNIGHT_MODELING.md"}

def safe_parts(value):
    if not isinstance(value, str) or not value or len(value) > 512 or any(c in value for c in ("\\", ":", "\0")):
        raise ValueError("Invalid relative path")
    parts = value.split("/")
    if any(not p or p in {".", ".."} for p in parts):
        raise ValueError("Path traversal refused")
    return parts

def guard_absolute(value):
    if not isinstance(value, str) or not re.fullmatch(r"/[A-Za-z0-9_./-]+", value):
        raise ValueError("Invalid absolute path")
    if any(p in {".", "..", ""} for p in value.split("/")[1:]):
        raise ValueError("Absolute path alias refused")
    path = Path(value)
    current = Path("/")
    for part in path.parts[1:]:
        current /= part
        if current.is_symlink():
            raise ValueError("Symlink component refused")
    return path

ROOT = guard_absolute(PAYLOAD["root"])
if ROOT.name != "mumbai-gully-heat" or not ROOT.is_relative_to(Path("/root/motion")):
    raise ValueError("Invalid game root")

def inside(relative):
    path = ROOT
    for part in safe_parts(relative):
        path /= part
        if path.is_symlink():
            raise ValueError("Project symlink refused")
    if not path.resolve().is_relative_to(ROOT.resolve()):
        raise ValueError("Path escapes project")
    return path

def deploy_allowed(relative):
    p = safe_parts(relative)
    return relative in EXACT or (len(p) == 3 and re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", p[2]) and
        ((p[:2] == ["tools", "modeling"] and p[2].endswith(".py")) or
         (p[:2] == ["jobs", "specs"] and p[2].endswith(".json"))))

def output_allowed(relative):
    p = safe_parts(relative)
    return (len(p) == 4 and p[:2] == ["assets", "generated"] and
        re.fullmatch(r"[a-z0-9][a-z0-9_-]{0,63}", p[2]) and p[3] in
        {"model.blend", "model.glb", "preview.png", "front.png", "rear.png", "side.png", "report.json"})

def read_allowed(relative):
    if output_allowed(relative):
        return True
    p = safe_parts(relative)
    return (relative in {".night-queue/state.json", ".night-queue/supervisor.log", ".night-queue/supervisor.pid"} or
        (len(p) == 3 and p[:2] == [".night-queue", "logs"] and p[2].endswith(".log") and
         re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,127}", p[2])))

def atomic_write(path, data):
    path.parent.mkdir(parents=True, mode=0o700, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".transfer-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data); stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)

def bounded_read(path):
    fd = os.open(path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    with os.fdopen(fd, "rb") as stream:
        info = os.fstat(stream.fileno())
        if not stat.S_ISREG(info.st_mode) or info.st_size > MAX_FILE:
            raise ValueError("Collection requires a bounded regular file")
        data = stream.read(MAX_FILE + 1)
        if len(data) > MAX_FILE: raise ValueError("File grew beyond collection limit")
        return data

def proc_token(pid):
    try: return Path("/proc/%s/stat" % pid).read_text().rpartition(") ")[2].split()[19]
    except (OSError, IndexError): return None

def identity():
    pidfile = inside(".night-queue/supervisor.pid")
    if not pidfile.is_file(): return None
    try:
        record = json.loads(bounded_read(pidfile))
        pid = record["pid"]
        if type(pid) is not int or pid <= 1 or not record.get("start_token") or proc_token(pid) != record["start_token"]:
            return None
        argv = Path("/proc/%s/cmdline" % pid).read_bytes().split(b"\0")
        expected = str(inside("tools/night_queue.py")).encode()
        index = argv.index(b"--root")
        if expected not in argv or argv[index + 1] != str(ROOT).encode(): return None
        return record
    except (ValueError, OSError, KeyError, IndexError, TypeError): return None

def status():
    statefile = inside(".night-queue/state.json")
    state = json.loads(bounded_read(statefile)) if statefile.is_file() else {"version": 1, "jobs": {}}
    supervisor = identity()
    offset = supervisor.get("clock_offset_seconds", 0.0) if supervisor else 0.0
    native_now = time.time()
    logical_now = native_now + offset
    clock = {"native_utc": datetime.fromtimestamp(native_now, timezone.utc).isoformat(),
             "logical_utc": datetime.fromtimestamp(logical_now, timezone.utc).isoformat(),
             "logical_ist": datetime.fromtimestamp(logical_now, timezone(timedelta(hours=5, minutes=30))).isoformat(),
             "offset_seconds": offset, "calibration": supervisor.get("clock_calibration") if supervisor else None}
    return {"root": str(ROOT), "running": supervisor is not None, "supervisor": supervisor, "clock": clock,
            "paused": inside(".night-queue/PAUSE").exists(), "stopped": inside(".night-queue/STOP").exists(), "state": state}

def start():
    running = identity()
    if running: return {"already_running": True, **status()}
    if inside(".night-queue/STOP").exists(): raise ValueError("Queue is stopped; use resume")
    blender = guard_absolute(PAYLOAD["blender"])
    if not blender.is_file() or blender.name != "blender" or not blender.is_relative_to(Path("/root/motion/.tools")):
        raise ValueError("Configured Blender binary is unavailable")
    if PAYLOAD["shared_lock"] != "/root/motion/.jobs/heavy.lock": raise ValueError("Unexpected shared lock")
    shared = guard_absolute(PAYLOAD["shared_lock"])
    if not shared.parent.is_dir(): raise ValueError("Shared lock directory does not exist")
    threads = PAYLOAD["threads"]
    if type(threads) is not int or not 1 <= threads <= 64: raise ValueError("Invalid thread count")
    offset = PAYLOAD.get("clock_offset_seconds")
    calibration = PAYLOAD.get("clock_calibration")
    if type(offset) not in (int, float) or not math.isfinite(offset) or abs(offset) > 1800:
        raise ValueError("A bounded clock calibration is required before starting")
    if not isinstance(calibration, dict) or len(json.dumps(calibration)) > 8192:
        raise ValueError("Missing clock calibration metadata")
    script = inside("tools/night_queue.py")
    if not script.is_file() or not inside("jobs/night-queue.json").is_file(): raise ValueError("Deploy the project first")
    command = [sys.executable, "-u", str(script), "--root", str(ROOT), "--blender", str(blender),
        "--queue", "jobs/night-queue.json", "--threads", str(threads), "--shared-lock", str(shared), "--poll-seconds", "30",
        "--clock-offset-seconds", str(offset)]
    validation = subprocess.run(command + ["--validate"], stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
        stderr=subprocess.PIPE, timeout=30, check=False)
    if validation.returncode: raise ValueError("Remote queue validation failed: " + validation.stderr.decode(errors="replace")[:4000])
    nice = Path("/usr/bin/nice")
    if not nice.is_file(): raise ValueError("Existing nice executable is required")
    env = os.environ.copy()
    env.update({"OMP_NUM_THREADS": str(threads), "OPENBLAS_NUM_THREADS": str(threads)})
    logfile = inside(".night-queue/supervisor.log")
    with logfile.open("ab") as stream:
        process = subprocess.Popen([str(nice), "-n", "10", *command], cwd=ROOT,
            stdin=subprocess.DEVNULL, stdout=stream, stderr=subprocess.STDOUT,
            start_new_session=True, close_fds=True, env=env)
    token = proc_token(process.pid)
    if not token: raise ValueError("Supervisor exited before its identity could be recorded; read its log")
    atomic_write(inside(".night-queue/supervisor.pid"), json.dumps({"pid": process.pid, "start_token": token,
        "clock_offset_seconds": offset, "clock_calibration": calibration}).encode())
    return {"started": True, **status()}

def dispatch():
    action = PAYLOAD["action"]
    if action == "clock":
        stamp = time.time()
        return {"utc_unix_seconds": stamp, "utc": datetime.fromtimestamp(stamp, timezone.utc).isoformat()}
    if action == "status": return status()
    if action == "collect-list":
        paths = PAYLOAD["outputs"]
        if not isinstance(paths, list) or len(paths) > 4096 or any(not output_allowed(p) for p in paths):
            raise ValueError("Invalid output manifest")
        paths = list(paths) + [".night-queue/state.json", ".night-queue/supervisor.log", ".night-queue/supervisor.pid"]
        logs = inside(".night-queue/logs")
        if logs.is_dir():
            paths += [str(p.relative_to(ROOT)) for p in logs.glob("*.log") if p.is_file()]
        if len(paths) > 8192: raise ValueError("Too many collection files")
        return {"files": [{"path": rel, "size": inside(rel).stat().st_size} for rel in sorted(set(paths))
                          if read_allowed(rel) and inside(rel).is_file()]}
    if action == "collect-read":
        relative = PAYLOAD["path"]
        if not read_allowed(relative): raise ValueError("Collection path refused")
        data = bounded_read(inside(relative))
        return {"path": relative, "size": len(data), "sha256": hashlib.sha256(data).hexdigest(),
                "base64": base64.b64encode(data).decode("ascii")}
    ROOT.mkdir(parents=True, mode=0o700, exist_ok=True)
    state = inside(".night-queue")
    state.mkdir(mode=0o700, exist_ok=True)
    lockfile = inside(".night-queue/control.lock")
    with lockfile.open("a+") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if action == "deploy":
            if identity(): raise ValueError("Stop the existing supervisor before deploying changed sources")
            files = PAYLOAD["files"]
            if not isinstance(files, list) or len(files) > 512: raise ValueError("Invalid deployment manifest")
            total = 0; prepared = []; seen = set()
            for item in files:
                relative = item["path"]
                if not deploy_allowed(relative) or relative in seen: raise ValueError("Deployment path refused")
                seen.add(relative)
                data = base64.b64decode(item["base64"], validate=True)
                total += len(data)
                if len(data) > 2 * 1024 * 1024 or total > 16 * 1024 * 1024: raise ValueError("Deployment is too large")
                if hashlib.sha256(data).hexdigest() != item["sha256"]: raise ValueError("Deployment hash mismatch")
                prepared.append((inside(relative), data))
            if not EXACT.issubset(seen): raise ValueError("Required deployment files are missing")
            for path, data in prepared: atomic_write(path, data)
            return {"deployed": len(prepared), "root": str(ROOT), "bytes": total}
        if action == "start": return start()
        if action in {"pause", "stop"}:
            marker = inside(".night-queue/" + ("PAUSE" if action == "pause" else "STOP"))
            marker.touch(mode=0o600)
            return {"control": action, **status()}
        if action == "resume":
            for name in ("PAUSE", "STOP"): inside(".night-queue/" + name).unlink(missing_ok=True)
            return {"control": action, **start()}
        raise ValueError("Unknown action")

try:
    print(json.dumps({"ok": True, "result": dispatch()}), flush=True)
except Exception as exc:
    print(json.dumps({"ok": False, "error": str(exc)[:8000]}), flush=True)
    raise SystemExit(2)
'''


def rpc(config: RemoteConfig, action: str, *, extra: dict[str, Any] | None = None,
        run=None) -> dict[str, Any]:
    payload = {"action": action, "root": config.remote_root, "blender": config.blender,
               "shared_lock": config.shared_lock, "threads": config.threads, **(extra or {})}
    # repr serializes the JSON text as one Python string literal; config content
    # cannot escape into the fixed program or the remote shell command.
    program = "import json\nPAYLOAD = json.loads(" + repr(json.dumps(payload)) + ")\n" + REMOTE_PROGRAM
    invoke = run or subprocess.run
    try:
        result = invoke(ssh_command(config), input=program.encode("utf-8"), stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE, timeout=60, check=False)
    except (OSError, subprocess.TimeoutExpired) as exc:
        raise RemoteError(f"SSH action {action} failed: {exc}") from exc
    if len(result.stdout) > MAX_COLLECT_FILE * 2:
        raise RemoteError("Remote response exceeds its size limit")
    try:
        response = json.loads(result.stdout)
    except (UnicodeError, json.JSONDecodeError) as exc:
        detail = result.stderr.decode(errors="replace")[:2000]
        raise RemoteError(f"SSH returned no valid response ({result.returncode}): {detail}") from exc
    if result.returncode or not isinstance(response, dict) or response.get("ok") is not True:
        raise RemoteError(str(response.get("error", "Remote command failed")) if isinstance(response, dict) else "Invalid remote response")
    return response["result"]


def calibrate_clock(config: RemoteConfig, *, call=None, wall_time=None, monotonic=None) -> dict[str, Any]:
    """Estimate local-minus-remote wall time without changing either host clock.

    The remote timestamp lies within the measured round trip. Its midpoint
    estimate therefore has at least half the round-trip uncertainty; bounds
    refuse a slow response, local wall-clock adjustment, or excessive drift.
    """
    invoke = call or rpc
    wall = wall_time or time.time
    steady = monotonic or time.monotonic
    before_utc, before_mono = wall(), steady()
    response = invoke(config, "clock")
    after_mono, after_utc = steady(), wall()
    rtt = after_mono - before_mono
    if not math.isfinite(rtt) or not 0 <= rtt <= MAX_CLOCK_RTT_SECONDS:
        raise RemoteError("Clock calibration round trip exceeds the 10-second bound")
    if not all(math.isfinite(v) for v in (before_utc, after_utc)) or abs((after_utc - before_utc) - rtt) > 1.0:
        raise RemoteError("Local clock changed during calibration; retry")
    remote_utc = response.get("utc_unix_seconds") if isinstance(response, dict) else None
    if type(remote_utc) not in (int, float) or not math.isfinite(remote_utc):
        raise RemoteError("Remote clock returned an invalid UTC timestamp")
    midpoint = (before_utc + after_utc) / 2.0
    offset = midpoint - remote_utc
    if not math.isfinite(offset) or abs(offset) > MAX_CLOCK_OFFSET_SECONDS:
        raise RemoteError("Remote clock differs by more than 1800 seconds; calibration refused")
    metadata = {"method": "client_utc_midpoint_minus_remote_utc", "client_midpoint_utc_unix_seconds": midpoint,
                "client_midpoint_utc": datetime.fromtimestamp(midpoint, timezone.utc).isoformat(),
                "remote_utc_unix_seconds": remote_utc, "round_trip_seconds": rtt,
                "uncertainty_seconds": rtt / 2.0, "offset_seconds": offset}
    return {"clock_offset_seconds": offset, "clock_calibration": metadata}


def control(config: RemoteConfig, action: str, *, call=None, calibrate=None) -> dict[str, Any]:
    invoke = call or rpc
    if action in {"start", "resume"}:
        calibration = (calibrate or calibrate_clock)(config)
        return invoke(config, action, extra=calibration)
    return invoke(config, action)


def deployment_files(root: Path) -> list[dict[str, str]]:
    paths = set(EXACT_DEPLOY)
    for directory, pattern in (("tools/modeling", "*.py"), ("jobs/specs", "*.json")):
        parent = confined(root, directory)
        if parent.is_dir():
            paths.update(p.relative_to(root).as_posix() for p in parent.glob(pattern))
    files, total = [], 0
    for relative in sorted(paths):
        if not allowed_deploy(relative):
            raise RemoteError(f"Deployment path refused: {relative}")
        path = confined(root, relative, required=True)
        if path.stat().st_size > MAX_DEPLOY_FILE:
            raise RemoteError(f"Deployment file too large: {relative}")
        data = path.read_bytes(); total += len(data)
        if total > MAX_DEPLOY_TOTAL:
            raise RemoteError("Deployment exceeds its total size limit")
        files.append({"path": relative, "sha256": hashlib.sha256(data).hexdigest(),
                      "base64": base64.b64encode(data).decode("ascii")})
    return files


def expected_outputs(root: Path) -> list[str]:
    path = confined(root, "jobs/night-queue.json", required=True)
    if path.stat().st_size > MAX_JSON:
        raise RemoteError("Queue exceeds size limit")
    payload = json.loads(path.read_text(encoding="utf-8-sig"))
    if not isinstance(payload, dict) or payload.get("version") != 1 or not isinstance(payload.get("jobs"), list):
        raise RemoteError("Invalid queue structure")
    paths = []
    for job in payload["jobs"]:
        if not isinstance(job, dict) or not isinstance(job.get("outputs"), list):
            raise RemoteError("Invalid job outputs")
        for relative in job["outputs"]:
            if not allowed_output(relative):
                raise RemoteError(f"Collection output is not allowed: {relative!r}")
            confined(root, relative)
            paths.append(relative)
    if len(paths) > 4096:
        raise RemoteError("Too many output paths")
    return sorted(set(paths))


def write_collected(root: Path, relative: str, data: bytes) -> None:
    target = confined(root, relative)
    target.parent.mkdir(parents=True, exist_ok=True)
    # Re-check after creating parents; an existing symlink must never redirect a
    # remote artifact into scripts, credentials, or another workspace.
    target = confined(root, relative)
    fd, temporary = tempfile.mkstemp(prefix=".collect-", dir=target.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(data); stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, target)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)


def collect(root: Path, config: RemoteConfig, *, call=None) -> dict[str, Any]:
    invoke = call or rpc
    outputs = expected_outputs(root)
    output_set = set(outputs)
    listing = invoke(config, "collect-list", extra={"outputs": outputs})
    if not isinstance(listing, dict) or not isinstance(listing.get("files"), list) or len(listing["files"]) > 8192:
        raise RemoteError("Invalid remote collection manifest")
    collected, total = [], 0
    for item in listing["files"]:
        if not isinstance(item, dict) or not isinstance(item.get("path"), str):
            raise RemoteError("Invalid remote file record")
        relative = item["path"]
        if allowed_output(relative) and relative not in output_set:
            raise RemoteError("Remote returned an undeclared generated output")
        destination = collection_target(relative, config.node_name)
        size = item.get("size")
        if type(size) is not int or not 0 <= size <= MAX_COLLECT_FILE:
            raise RemoteError("Remote file exceeds size limit")
        total += size
        if total > 1024 * 1024 * 1024:
            raise RemoteError("Collection exceeds 1 GiB; collect a reviewed smaller queue")
        # Validate local parents before asking the remote to transfer a file.
        confined(root, destination)
        response = invoke(config, "collect-read", extra={"path": relative})
        if response.get("path") != relative:
            raise RemoteError("Remote file identity mismatch")
        try:
            data = base64.b64decode(response["base64"], validate=True)
        except (KeyError, TypeError, ValueError) as exc:
            raise RemoteError("Invalid file encoding") from exc
        if len(data) > MAX_COLLECT_FILE or len(data) != response.get("size") or hashlib.sha256(data).hexdigest() != response.get("sha256"):
            raise RemoteError("Collected file hash/size verification failed")
        write_collected(root, destination, data)
        collected.append(destination)
    return {"collected": collected, "files": len(collected), "bytes_listed": total,
            "note": "Generated outputs copied; remote diagnostics are under reports/remote. No sources copied back."}


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["deploy", "start", "status", "collect", "pause", "resume", "stop"])
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--config", default="jobs/remote.json")
    args = parser.parse_args(argv)
    try:
        root = args.root.resolve(strict=True)
        config = RemoteConfig.load(root, args.config)
        if args.action == "deploy":
            result = rpc(config, "deploy", extra={"files": deployment_files(root)})
        elif args.action == "collect":
            result = collect(root, config)
        else:
            result = control(config, args.action)
        print(json.dumps(result, indent=2))
        return 0
    except (RemoteError, OSError, json.JSONDecodeError) as exc:
        print(f"Remote queue error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
