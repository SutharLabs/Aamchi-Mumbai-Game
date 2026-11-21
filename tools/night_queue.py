#!/usr/bin/env python3
"""Run bounded Blender jobs in an IST night window without an agent session.

Only reviewed, project-local Python generators are executed. This is an execution
supervisor, not a sandbox for untrusted Blender scripts. See --help for controls.
"""
from __future__ import annotations

import argparse
from contextlib import ExitStack
from datetime import datetime, timedelta, timezone
import hashlib
import json
import math
import os
from pathlib import Path, PurePosixPath
import re
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from typing import Any, Callable

IST = timezone(timedelta(hours=5, minutes=30), name="Asia/Kolkata")
UTC = timezone.utc
ID_PATTERN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_-]{0,63}\Z")
MAX_JSON_BYTES = 2 * 1024 * 1024
MAX_LOG_BYTES = 64 * 1024 * 1024


class QueueError(ValueError):
    pass


class BusyError(RuntimeError):
    pass


class WindowClosed(QueueError):
    """The scheduling window expired before a child could be launched."""
    pass


class AnchoredClock:
    """Correct a known host-clock offset without modifying the host clock.

    Night-window calculations advance from a corrected UTC anchor using a
    monotonic timer, so later host NTP/wall-clock jumps cannot extend a job.
    File timestamps remain in the native host-clock domain separately.
    """
    def __init__(self, offset_seconds: float = 0.0, *, wall_time: Callable[[], float] = time.time,
                 monotonic: Callable[[], float] = time.monotonic):
        if not math.isfinite(offset_seconds) or abs(offset_seconds) > 1800:
            raise QueueError("Clock offset must be finite and within +/-1800 seconds")
        self.anchor = datetime.fromtimestamp(wall_time() + offset_seconds, UTC)
        self.monotonic = monotonic
        self.started = monotonic()

    def __call__(self) -> datetime:
        return self.anchor + timedelta(seconds=max(0.0, self.monotonic() - self.started))


def confined_path(root: Path, relative: str, *, exists: bool = False) -> Path:
    """Reject traversal and symlink/junction components, including output parents."""
    if not isinstance(relative, str) or not relative or len(relative) > 512:
        raise QueueError("Project paths must be nonempty relative strings (max 512 chars)")
    if "\\" in relative or ":" in relative or "\0" in relative:
        raise QueueError(f"Use a relative forward-slash path: {relative!r}")
    parts = PurePosixPath(relative).parts
    if PurePosixPath(relative).is_absolute() or any(p in {"..", "."} for p in relative.split("/")):
        raise QueueError(f"Path escapes or aliases the project: {relative!r}")
    current = root
    for part in parts:
        current = current / part
        if current.is_symlink() or (hasattr(current, "is_junction") and current.is_junction()):
            raise QueueError(f"Symlink/junction paths are not allowed: {relative!r}")
    try:
        current.resolve().relative_to(root)
    except ValueError as exc:
        raise QueueError(f"Path escapes project: {relative!r}") from exc
    if exists and (not current.is_file() or current.is_symlink()):
        raise QueueError(f"Required regular file is missing: {relative}")
    return current


def read_json(path: Path) -> Any:
    if path.stat().st_size > MAX_JSON_BYTES:
        raise QueueError(f"JSON exceeds {MAX_JSON_BYTES} bytes: {path.name}")
    try:
        return json.loads(path.read_text(encoding="utf-8-sig"))
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise QueueError(f"Invalid JSON: {path.name}: {exc}") from exc


def atomic_json(path: Path, value: Any) -> None:
    fd, temporary = tempfile.mkstemp(prefix=".state-", suffix=".tmp", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            json.dump(value, handle, indent=2, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


class FileLock:
    """Nonblocking OS lock; abrupt process exit releases it automatically."""
    def __init__(self, path: Path):
        self.path = path
        self.fd: int | None = None

    def __enter__(self):
        if self.path.is_symlink():
            raise QueueError(f"Refusing symlink lock: {self.path}")
        flags = os.O_RDWR | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0)
        self.fd = os.open(self.path, flags, 0o600)
        try:
            if not stat.S_ISREG(os.fstat(self.fd).st_mode):
                raise QueueError("Lock must be a regular file")
            if os.name == "nt":
                import msvcrt
                if os.fstat(self.fd).st_size == 0:
                    os.write(self.fd, b"\0")
                os.lseek(self.fd, 0, os.SEEK_SET)
                msvcrt.locking(self.fd, msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(self.fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except (OSError, QueueError) as exc:
            os.close(self.fd)
            self.fd = None
            if isinstance(exc, QueueError):
                raise
            raise BusyError(f"Lock is held: {self.path}") from exc
        return self

    def __exit__(self, *_):
        if self.fd is not None:
            os.close(self.fd)
            self.fd = None


class NightWindow:
    def __init__(self, specification: str = "22:00-08:00"):
        try:
            first, last = specification.split("-")
            self.start = datetime.strptime(first, "%H:%M").time()
            self.end = datetime.strptime(last, "%H:%M").time()
        except (ValueError, TypeError) as exc:
            raise QueueError("Window must be HH:MM-HH:MM") from exc
        if self.start == self.end:
            raise QueueError("A 24-hour or empty window is not allowed")

    def deadline(self, now: datetime) -> datetime | None:
        local = now.astimezone(IST)
        clock = local.time().replace(tzinfo=None)
        overnight = self.start > self.end
        active = (clock >= self.start or clock < self.end) if overnight else self.start <= clock < self.end
        if not active:
            return None
        day = local.date() + (timedelta(days=1) if overnight and clock >= self.start else timedelta())
        return datetime.combine(day, self.end, IST)

    def next_start(self, now: datetime) -> datetime:
        local = now.astimezone(IST)
        candidate = datetime.combine(local.date(), self.start, IST)
        return candidate if candidate > local else candidate + timedelta(days=1)


def digest(path: Path) -> str:
    result = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def load_jobs(root: Path, queue_relative: str) -> list[dict[str, Any]]:
    queue_path = confined_path(root, queue_relative, exists=True)
    if queue_path.suffix.lower() != ".json":
        raise QueueError("Queue must be a JSON file")
    payload = read_json(queue_path)
    if not isinstance(payload, dict) or type(payload.get("version")) is not int or payload.get("version") != 1:
        raise QueueError("Queue must be an object with version: 1")
    jobs = payload.get("jobs")
    if not isinstance(jobs, list) or not 1 <= len(jobs) <= 256:
        raise QueueError("Queue must contain 1–256 jobs")
    ids: set[str] = set()
    output_owners: set[str] = set()
    for job in jobs:
        if not isinstance(job, dict) or not isinstance(job.get("id"), str) or not ID_PATTERN.fullmatch(job["id"]):
            raise QueueError("Each job needs a safe unique id (letters/digits/hyphen/underscore)")
        if job["id"] in ids:
            raise QueueError(f"Duplicate job id: {job['id']}")
        ids.add(job["id"])
        if not isinstance(job.get("enabled", True), bool):
            raise QueueError("enabled must be boolean")
        script = confined_path(root, job.get("script", ""), exists=job.get("enabled", True))
        if script.suffix.lower() != ".py":
            raise QueueError("Only project-local .py generator scripts are allowed")
        arguments = job.get("args", [])
        if not isinstance(arguments, list) or len(arguments) > 128 or any(not isinstance(a, str) or len(a) > 4096 or "\0" in a for a in arguments):
            raise QueueError("args must be a bounded list of strings")
        inputs = job.get("inputs", [])
        if not isinstance(inputs, list) or len(inputs) > 128:
            raise QueueError("inputs must be a list of relative paths")
        for relative in inputs:
            confined_path(root, relative, exists=job.get("enabled", True))
        outputs = job.get("outputs")
        if not isinstance(outputs, list) or not 1 <= len(outputs) <= 32:
            raise QueueError("Each job needs 1–32 declared output files")
        for relative in outputs:
            path = confined_path(root, relative)
            if relative.startswith(".night-queue/") or path == script or relative in inputs:
                raise QueueError("Outputs cannot overwrite supervisor state, scripts, or inputs")
            normalized = os.path.normcase(str(path))
            if normalized in output_owners:
                raise QueueError(f"Output is declared by more than one job: {relative}")
            output_owners.add(normalized)
        for key, default, minimum, maximum in (("timeout_seconds", 3600, 1, 36000), ("max_attempts", 2, 1, 5), ("minimum_window_seconds", 30, 1, 36000)):
            value = job.get(key, default)
            if isinstance(value, bool) or not isinstance(value, int) or not minimum <= value <= maximum:
                raise QueueError(f"Invalid {key} for {job['id']}")
        if job.get("validation_report"):
            if job["validation_report"] not in outputs:
                raise QueueError("validation_report must be one of the declared outputs")
    protected = {os.path.normcase(str(queue_path))}
    for job in jobs:
        protected.add(os.path.normcase(str(confined_path(root, job["script"]))))
        protected.update(os.path.normcase(str(confined_path(root, value))) for value in job.get("inputs", []))
    if protected.intersection(output_owners):
        raise QueueError("An output would overwrite queue configuration or another job's input/script")
    return jobs


def fingerprint(root: Path, job: dict[str, Any]) -> str:
    result = hashlib.sha256(json.dumps(job, sort_keys=True, separators=(",", ":")).encode())
    for relative in [job["script"], *job.get("inputs", [])]:
        result.update(relative.encode())
        result.update(bytes.fromhex(digest(confined_path(root, relative, exists=True))))
    return result.hexdigest()


def output_snapshot(root: Path, job: dict[str, Any]) -> dict[str, tuple | None]:
    snapshot = {}
    for relative in job["outputs"]:
        path = confined_path(root, relative)
        info = path.stat() if path.exists() else None
        snapshot[relative] = (info.st_mtime_ns, info.st_ctime_ns, info.st_size, info.st_ino) if info else None
    return snapshot


def accepted_outputs(root: Path, job: dict[str, Any], before: dict, started_at: float) -> tuple[bool, str, dict]:
    records = {}
    after = output_snapshot(root, job)
    for relative in job["outputs"]:
        path = confined_path(root, relative)
        if not path.is_file() or path.stat().st_size <= 0:
            return False, f"Missing/empty output: {relative}", {}
        if after[relative] == before.get(relative) or path.stat().st_mtime < started_at - 2:
            return False, f"Output was not freshly written: {relative}", {}
        records[relative] = {"size": path.stat().st_size, "sha256": digest(path)}
    report = job.get("validation_report")
    if report:
        data = read_json(confined_path(root, report, exists=True))
        if not isinstance(data, dict) or not (data.get("passed") is True or data.get("status") == "ok"):
            return False, "Validation report did not declare passed:true or status:ok", {}
    return True, "All declared outputs freshly written", records


def outputs_unchanged(root: Path, job: dict, record: dict) -> bool:
    try:
        for relative in job["outputs"]:
            path = confined_path(root, relative, exists=True)
            expected = record.get("outputs", {}).get(relative, {})
            if path.stat().st_size != expected.get("size") or digest(path) != expected.get("sha256"):
                return False
        return True
    except (OSError, QueueError):
        return False


def process_token(pid: int) -> str | None:
    """Linux PID start time prevents treating an unrelated reused PID as our worker."""
    if sys.platform.startswith("linux"):
        try:
            return Path(f"/proc/{pid}/stat").read_text().rpartition(") ")[2].split()[19]
        except (OSError, IndexError):
            return None
    return None


def process_alive(pid: int, token: str | None) -> bool:
    if not isinstance(pid, int) or pid <= 1:
        return False
    if sys.platform.startswith("linux"):
        current = process_token(pid)
        return current is not None and (token is None or current == token)
    if os.name == "nt":
        import ctypes
        handle = ctypes.windll.kernel32.OpenProcess(0x1000, False, pid)
        if not handle:
            return False
        ctypes.windll.kernel32.CloseHandle(handle)
        return True
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def terminate_worker(process: subprocess.Popen) -> None:
    """Only terminate the child launched by this supervisor, never unrelated work."""
    if process.poll() is not None:
        return
    try:
        if os.name == "nt":
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)
        else:
            os.killpg(process.pid, signal.SIGTERM)
        process.wait(timeout=5)
    except (OSError, subprocess.TimeoutExpired):
        if process.poll() is None:
            if os.name == "nt":
                process.kill()
            else:
                try:
                    os.killpg(process.pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
            process.wait(timeout=5)


def guarded_command(command: list[str], seconds: float) -> list[str]:
    """Linux timeout survives supervisor death and independently bounds work.

    The hard timeout is intentional: generators must write outputs atomically.
    A killed/incomplete job is never accepted solely because files exist.
    """
    if seconds <= 0:
        raise WindowClosed("Night window cutoff reached before worker launch")
    if not sys.platform.startswith("linux"):
        return command
    executable = next((candidate for candidate in (Path("/usr/bin/timeout"), Path("/bin/timeout")) if candidate.is_file()), None)
    if executable is None:
        raise QueueError("Linux execution requires GNU timeout for independent job/cutoff enforcement")
    # Round down and leave a small launch allowance rather than extending 08:00.
    duration = max(0.001, seconds - 0.25)
    return [str(executable), "--signal=KILL", f"{duration:.3f}s", *command]


class Supervisor:
    def __init__(self, root: Path, queue: str, blender: Path | None, *, window: NightWindow | None = None,
                 threads: int = 8, shared_lock: Path | None = None,
                 now: Callable[[], datetime] | None = None, monotonic: Callable[[], float] = time.monotonic,
                 sleep: Callable[[float], None] = time.sleep, popen: Callable = subprocess.Popen,
                 clock_offset_seconds: float = 0.0, wall_time: Callable[[], float] = time.time):
        self.root = root.resolve(strict=True)
        self.queue = queue
        self.blender = blender.resolve(strict=True) if blender else None
        if self.blender and (not self.blender.is_file() or (os.name != "nt" and not os.access(self.blender, os.X_OK))):
            raise QueueError("Blender must be a regular executable file")
        self.window = window or NightWindow()
        self.threads = threads
        self.shared_lock = shared_lock
        if not math.isfinite(clock_offset_seconds) or abs(clock_offset_seconds) > 1800:
            raise QueueError("Clock offset must be finite and within +/-1800 seconds")
        self.clock_offset_seconds = clock_offset_seconds
        self.clock_mode = "injected" if now is not None else "corrected_utc_monotonic_anchor"
        self.wall_time = wall_time
        self.now = now or AnchoredClock(clock_offset_seconds, wall_time=wall_time, monotonic=monotonic)
        self.monotonic, self.sleep, self.popen = monotonic, sleep, popen
        self.state_dir = confined_path(self.root, ".night-queue")
        self.state_path = confined_path(self.root, ".night-queue/state.json")
        self.state = read_json(self.state_path) if self.state_path.exists() else {"version": 1, "jobs": {}}
        if not isinstance(self.state, dict) or self.state.get("version") != 1 or not isinstance(self.state.get("jobs"), dict):
            raise QueueError("Invalid state file; preserve it for review instead of resetting progress")

    def save(self):
        self.state["updated_at"] = self.now().isoformat()
        self.state["clock"] = {"mode": self.clock_mode, "offset_seconds": self.clock_offset_seconds}
        atomic_json(self.state_path, self.state)

    def status(self) -> dict:
        now = self.now()
        deadline = self.window.deadline(now)
        return {"now_ist": now.astimezone(IST).isoformat(), "in_window": deadline is not None,
                "logical_utc_now": now.astimezone(UTC).isoformat(),
                "host_utc_now": datetime.fromtimestamp(self.wall_time(), UTC).isoformat(),
                "clock_mode": self.clock_mode, "clock_offset_seconds": self.clock_offset_seconds,
                "cutoff_ist": deadline.isoformat() if deadline else None,
                "next_start_ist": self.window.next_start(now).isoformat(),
                "paused": (self.state_dir / "PAUSE").exists(), "stopped": (self.state_dir / "STOP").exists(),
                "jobs": self.state["jobs"]}

    def reconcile(self, jobs: list[dict]) -> bool:
        """Recover checkpoints; a still-live orphan is held, never duplicated/killed."""
        orphan_alive = False
        for job in jobs:
            if not job.get("enabled", True):
                continue
            current = fingerprint(self.root, job)
            record = self.state["jobs"].get(job["id"], {})
            if record.get("status") == "running":
                if process_alive(record.get("pid", 0), record.get("process_token")):
                    orphan_alive = True
                    continue
                record.update(status="interrupted", attempts=max(0, record.get("attempts", 1) - 1), reason="Prior worker ended without an accepted checkpoint")
            if record.get("fingerprint") != current:
                record = {"fingerprint": current, "status": "pending", "attempts": 0, "launches": 0,
                          "reason": "New job or generator/input/specification changed"}
            elif record.get("status") == "completed" and not outputs_unchanged(self.root, job, record):
                record.update(status="pending", attempts=0, reason="Accepted outputs changed or are missing")
            self.state["jobs"][job["id"]] = record
        self.save()
        return orphan_alive

    def execute(self, job: dict, record: dict, cutoff: datetime, shared_lock_fd: int | None = None) -> str:
        if self.blender is None or not self.blender.is_file():
            raise QueueError("An existing Blender executable is required for execution")
        before = output_snapshot(self.root, job)
        for relative in job["outputs"]:
            confined_path(self.root, relative).parent.mkdir(parents=True, exist_ok=True)
        script = confined_path(self.root, job["script"], exists=True)
        record["attempts"] = record.get("attempts", 0) + 1
        record["launches"] = record.get("launches", 0) + 1
        logfile = confined_path(self.root, f".night-queue/logs/{job['id']}-{record['launches']:03d}-{uuid.uuid4().hex[:12]}.log")
        logfile.parent.mkdir(parents=True, exist_ok=True)
        record.update(status="running", started_at=self.now().isoformat(), log=str(logfile.relative_to(self.root)))
        self.save()
        # Output mtimes belong to native OS wall time, not corrected logical UTC.
        started_wall = self.wall_time()
        started_mono = self.monotonic()
        command = [str(self.blender), "--factory-startup", "--disable-autoexec", "-b", "-t", str(self.threads), "--python", str(script), "--", *job.get("args", [])]
        options = {"cwd": str(self.root), "stdin": subprocess.DEVNULL, "stderr": subprocess.STDOUT}
        if os.name == "nt":
            options["creationflags"] = subprocess.CREATE_NEW_PROCESS_GROUP | subprocess.CREATE_NO_WINDOW
        else:
            options["start_new_session"] = True
            if shared_lock_fd is not None:
                # Keep the shared heavy-job lock alive in the timeout/Blender
                # descendants even if the Python supervisor is killed.
                options["pass_fds"] = (shared_lock_fd,)
        process = None
        interruption = None
        try:
            log_fd = os.open(logfile, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(log_fd, "wb") as output:
                available_window_seconds = (cutoff - self.now()).total_seconds()
                remaining = min(job.get("timeout_seconds", 3600), available_window_seconds)
                window_limited = available_window_seconds <= job.get("timeout_seconds", 3600)
                process = self.popen(guarded_command(command, remaining), stdout=output, **options)
                record.update(pid=process.pid, process_token=process_token(process.pid))
                self.save()
                while process.poll() is None:
                    if (self.state_dir / "STOP").exists() or (self.state_dir / "PAUSE").exists():
                        interruption = "Stopped or paused by operator"
                    elif self.now() >= cutoff or self.window.deadline(self.now()) is None:
                        interruption = "Night window cutoff reached"
                    elif self.monotonic() - started_mono >= job.get("timeout_seconds", 3600):
                        interruption = "Job timeout exceeded"
                    elif logfile.stat().st_size > MAX_LOG_BYTES:
                        interruption = "Job log exceeded 64 MiB limit"
                    if interruption:
                        terminate_worker(process)
                        break
                    self.sleep(min(1.0, max(0.01, (cutoff - self.now()).total_seconds())))
                returncode = process.wait()
            if interruption is None and self.now() >= cutoff:
                interruption = "Night window cutoff reached"
            elif interruption is None and window_limited and returncode in {-9, 124, 137} and self.now() >= cutoff - timedelta(seconds=1):
                # The independent timeout intentionally fires slightly before
                # 08:00. Preserve its job for next night instead of spending a
                # failure attempt on an ordinary window interruption.
                interruption = "Night window cutoff reached"
            if interruption:
                retryable_cutoff = interruption in {"Stopped or paused by operator", "Night window cutoff reached"}
                if retryable_cutoff:
                    record["attempts"] = max(0, record["attempts"] - 1)
                record.update(status="interrupted" if retryable_cutoff else "failed", reason=interruption)
            elif returncode != 0:
                record.update(status="failed", reason=f"Blender exited with code {returncode}")
            else:
                passed, reason, outputs = accepted_outputs(self.root, job, before, started_wall)
                record.update(status="completed" if passed else "failed", reason=reason, outputs=outputs)
        except WindowClosed as exc:
            record.update(status="interrupted", reason=str(exc), attempts=max(0, record["attempts"] - 1))
        except (KeyboardInterrupt, SystemExit):
            if process:
                terminate_worker(process)
            record.update(status="interrupted", reason="Supervisor interrupted", attempts=max(0, record["attempts"] - 1))
            self.save()
            raise
        except Exception as exc:
            if process:
                terminate_worker(process)
            record.update(status="failed", reason=f"{type(exc).__name__}: {exc}")
        record.pop("pid", None)
        record.pop("process_token", None)
        record["finished_at"] = self.now().isoformat()
        if record["status"] == "failed" and record["attempts"] >= job.get("max_attempts", 2):
            record["status"] = "exhausted"
        self.save()
        return record["status"]

    def tick(self) -> str:
        jobs = load_jobs(self.root, self.queue)
        if self.reconcile(jobs):
            return "waiting_for_prior_worker"
        if (self.state_dir / "STOP").exists():
            return "stopped"
        if (self.state_dir / "PAUSE").exists():
            return "paused"
        cutoff = self.window.deadline(self.now())
        if cutoff is None:
            return "outside_window"
        for job in jobs:
            if not job.get("enabled", True):
                continue
            record = self.state["jobs"][job["id"]]
            if record["status"] in {"completed", "exhausted"}:
                continue
            if (cutoff - self.now()).total_seconds() < job.get("minimum_window_seconds", 30):
                return "insufficient_window"
            with ExitStack() as stack:
                lock_fd = None
                if self.shared_lock:
                    try:
                        shared = stack.enter_context(FileLock(self.shared_lock))
                        lock_fd = shared.fd
                    except BusyError:
                        return "shared_worker_busy"
                return self.execute(job, record, cutoff, shared_lock_fd=lock_fd)
        exhausted = any(job.get("enabled", True) and self.state["jobs"].get(job["id"], {}).get("status") == "exhausted" for job in jobs)
        return "queue_exhausted" if exhausted else "queue_complete"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--queue", default="jobs/night-queue.json", help="Project-relative JSON queue")
    parser.add_argument("--blender", type=Path, help="Explicit existing Blender executable")
    parser.add_argument("--threads", type=int, default=8)
    parser.add_argument("--window", default="22:00-08:00")
    parser.add_argument("--timezone", choices=["Asia/Kolkata", "Asia/Calcutta"], default="Asia/Kolkata")
    parser.add_argument("--clock-offset-seconds", type=float, default=0.0,
                        help="Client-calibrated UTC minus host UTC, within +/-1800; logical scheduling only")
    parser.add_argument("--shared-lock", type=Path, help="Existing shared-machine lock directory; lock acquired nonblocking")
    parser.add_argument("--poll-seconds", type=float, default=30)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument("--once", action="store_true", help="One scheduling tick; outside window returns immediately")
    modes.add_argument("--status", action="store_true", help="Read state without starting work or writing files")
    modes.add_argument("--validate", action="store_true", help="Validate queue and local input paths, read-only")
    modes.add_argument("--pause", action="store_true", help="Pause queue and interrupt current job through its supervisor")
    modes.add_argument("--resume", action="store_true", help="Clear PAUSE and STOP markers; does not launch a supervisor")
    modes.add_argument("--stop", action="store_true", help="Stop supervisor through a marker; no unrelated processes killed")
    args = parser.parse_args(argv)
    if not 1 <= args.threads <= 256 or not 0.1 <= args.poll_seconds <= 60:
        parser.error("threads must be 1–256 and poll-seconds 0.1–60")
    if not math.isfinite(args.clock_offset_seconds) or abs(args.clock_offset_seconds) > 1800:
        parser.error("clock-offset-seconds must be finite and within +/-1800")
    try:
        runner = Supervisor(args.root, args.queue, args.blender, window=NightWindow(args.window), threads=args.threads, shared_lock=args.shared_lock,
                            clock_offset_seconds=args.clock_offset_seconds)
        if args.status:
            print(json.dumps(runner.status(), indent=2))
            return 0
        if args.validate:
            jobs = load_jobs(runner.root, runner.queue)
            print(json.dumps({"valid": True, "jobs": len(jobs), "blender_checked": runner.blender is not None}))
            return 0
        runner.state_dir.mkdir(mode=0o700, exist_ok=True)
        if args.pause or args.stop or args.resume:
            if args.resume:
                for marker in ("PAUSE", "STOP"):
                    confined_path(runner.root, f".night-queue/{marker}").unlink(missing_ok=True)
            else:
                marker = "PAUSE" if args.pause else "STOP"
                confined_path(runner.root, f".night-queue/{marker}").touch(mode=0o600)
            print("Control marker updated. Start/restart the supervisor separately if it is not running.")
            return 0
        def interrupt_supervisor(_signal, _frame):
            raise KeyboardInterrupt

        signal.signal(signal.SIGTERM, interrupt_supervisor)
        with FileLock(confined_path(runner.root, ".night-queue/supervisor.lock")):
            while True:
                result = runner.tick()
                print(json.dumps({"time_ist": runner.now().astimezone(IST).isoformat(), "result": result}), flush=True)
                if args.once or result in {"queue_complete", "queue_exhausted", "stopped"}:
                    return 1 if result in {"failed", "exhausted", "queue_exhausted"} else 0
                runner.sleep(args.poll_seconds)
    except BusyError as exc:
        print(str(exc), file=sys.stderr)
        return 3
    except (QueueError, OSError) as exc:
        print(f"Queue error: {exc}", file=sys.stderr)
        return 2
    except KeyboardInterrupt:
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
