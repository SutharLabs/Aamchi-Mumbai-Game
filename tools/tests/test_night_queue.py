import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch

MODULE_PATH = Path(__file__).resolve().parents[1] / "night_queue.py"
spec = importlib.util.spec_from_file_location("night_queue", MODULE_PATH)
nq = importlib.util.module_from_spec(spec)
spec.loader.exec_module(nq)


class QueueTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        (self.root / "tools").mkdir()
        (self.root / "tools/build.py").write_text("# reviewed generator\n")
        (self.root / "jobs").mkdir()
        self.job = {"id": "chawl", "script": "tools/build.py", "args": [],
                    "outputs": ["assets/chawl.glb", "assets/report.json"],
                    "validation_report": "assets/report.json", "timeout_seconds": 60, "max_attempts": 2}
        self.queue = self.root / "jobs/queue.json"
        self.write_queue()
        self.now = datetime(2026, 11, 19, 22, 0, tzinfo=nq.IST)

    def write_queue(self):
        self.queue.write_text(json.dumps({"version": 1, "jobs": [self.job]}), encoding="utf-8")

    def runner(self, **kwargs):
        runner = nq.Supervisor(self.root, "jobs/queue.json", Path(sys.executable), now=lambda: self.now, **kwargs)
        runner.state_dir.mkdir()
        return runner

    def write_outputs(self, status="ok"):
        (self.root / "assets").mkdir(exist_ok=True)
        (self.root / "assets/chawl.glb").write_bytes(b"valid test output")
        (self.root / "assets/report.json").write_text(json.dumps({"status": status}))

    def test_cross_midnight_window_and_exact_cutoff(self):
        window = nq.NightWindow()
        for hour in (22, 23, 0, 7):
            now = datetime(2026, 11, 19, hour, 30, tzinfo=nq.IST)
            cutoff = window.deadline(now)
            self.assertIsNotNone(cutoff)
            self.assertEqual(cutoff.hour, 8)
            self.assertGreater(cutoff, now)
        for hour in (8, 12, 21):
            self.assertIsNone(window.deadline(datetime(2026, 11, 19, hour, 0, tzinfo=nq.IST)))
        utc_equivalent = datetime(2026, 11, 19, 16, 30, tzinfo=timezone.utc)
        self.assertIsNotNone(window.deadline(utc_equivalent))
        self.assertEqual(window.next_start(datetime(2026, 11, 19, 8, tzinfo=nq.IST)).hour, 22)

    def test_offset_enters_correct_window_and_ignores_later_host_clock_jump(self):
        host_timestamp = [datetime(2026, 11, 19, 16, 29, tzinfo=timezone.utc).timestamp()]
        monotonic_time = [100.0]
        clock = nq.AnchoredClock(120, wall_time=lambda: host_timestamp[0], monotonic=lambda: monotonic_time[0])
        self.assertIsNone(nq.NightWindow().deadline(datetime.fromtimestamp(host_timestamp[0], timezone.utc)))
        self.assertIsNotNone(nq.NightWindow().deadline(clock()))
        self.assertEqual(clock().astimezone(nq.IST).strftime("%H:%M"), "22:01")
        host_timestamp[0] -= 600  # Host wall time jumps backwards after anchoring.
        monotonic_time[0] += 60
        self.assertEqual(clock().astimezone(nq.IST).strftime("%H:%M"), "22:02")

    def test_clock_offset_rejects_nan_and_out_of_range_values(self):
        for offset in (float("nan"), float("inf"), -1800.1, 1800.1):
            with self.subTest(offset=offset), self.assertRaises(nq.QueueError):
                nq.AnchoredClock(offset)

    def test_corrected_logical_clock_uses_native_filesystem_freshness(self):
        runner = nq.Supervisor(self.root, "jobs/queue.json", Path(sys.executable), clock_offset_seconds=146)
        runner.state_dir.mkdir()
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = 0
        fake.wait.return_value = 0

        def generate(*args, **kwargs):
            self.write_outputs()
            return fake

        runner.popen = generate
        result = runner.execute(self.job, runner.state["jobs"]["chawl"], runner.now() + timedelta(hours=1))
        self.assertEqual(result, "completed")
        filesystem_timestamp = (self.root / "assets/chawl.glb").stat().st_mtime
        self.assertGreater(runner.now().timestamp() - filesystem_timestamp, 140)
        status = runner.status()
        self.assertEqual(status["clock_offset_seconds"], 146)
        self.assertEqual(status["clock_mode"], "corrected_utc_monotonic_anchor")
        self.assertEqual(runner.state["clock"]["offset_seconds"], 146)

    def test_reject_paths_outside_root_and_state_overwrite(self):
        for path in ("../escape.py", "/etc/passwd", "C:/outside.py", "tools\\build.py", "tools/../build.py"):
            with self.subTest(path=path), self.assertRaises(nq.QueueError):
                nq.confined_path(self.root, path)
        self.job["outputs"] = [".night-queue/state.json"]
        self.write_queue()
        with self.assertRaises(nq.QueueError):
            nq.load_jobs(self.root, "jobs/queue.json")

    def test_reject_symlink_output_parent(self):
        outside = self.root / "outside"
        outside.mkdir()
        try:
            (self.root / "linked").symlink_to(outside, target_is_directory=True)
        except OSError:
            self.skipTest("Symlink creation unavailable in this environment")
        with self.assertRaises(nq.QueueError):
            nq.confined_path(self.root, "linked/output.glb")

    def test_invalid_ids_duplicate_outputs_and_args(self):
        self.job["id"] = "bad/id"
        self.write_queue()
        with self.assertRaises(nq.QueueError):
            nq.load_jobs(self.root, "jobs/queue.json")
        self.job["id"] = "good"
        self.job["args"] = "--not-a-list"
        self.write_queue()
        with self.assertRaises(nq.QueueError):
            nq.load_jobs(self.root, "jobs/queue.json")

    def test_completed_job_invalidates_when_generator_or_artifact_changes(self):
        runner = self.runner()
        runner.reconcile([self.job])
        self.write_outputs()
        record = runner.state["jobs"]["chawl"]
        record.update(status="completed", outputs={relative: {"size": (self.root / relative).stat().st_size,
                      "sha256": nq.digest(self.root / relative)} for relative in self.job["outputs"]})
        runner.reconcile([self.job])
        self.assertEqual(record["status"], "completed")
        (self.root / "assets/chawl.glb").write_bytes(b"changed artifact")
        runner.reconcile([self.job])
        self.assertEqual(record["status"], "pending")
        previous = record["fingerprint"]
        (self.root / "tools/build.py").write_text("# changed generator\n")
        runner.reconcile([self.job])
        self.assertNotEqual(previous, runner.state["jobs"]["chawl"]["fingerprint"])

    def test_stale_output_and_failed_validation_are_not_success(self):
        self.write_outputs()
        before = nq.output_snapshot(self.root, self.job)
        accepted, reason, _ = nq.accepted_outputs(self.root, self.job, before, self.now.timestamp())
        self.assertFalse(accepted)
        self.assertIn("freshly", reason)
        self.write_outputs(status="failed")
        accepted, reason, _ = nq.accepted_outputs(self.root, self.job, {}, 0)
        self.assertFalse(accepted)
        self.assertIn("Validation report", reason)

    def test_interrupted_checkpoint_recovers_without_consuming_attempt(self):
        runner = self.runner()
        runner.reconcile([self.job])
        record = runner.state["jobs"]["chawl"]
        record.update(status="running", attempts=1, pid=99999999, process_token="missing")
        with patch.object(nq, "process_alive", return_value=False):
            runner.reconcile([self.job])
        self.assertEqual(record["status"], "interrupted")
        self.assertEqual(record["attempts"], 0)

    def test_live_prior_worker_is_held_without_duplicate_launch(self):
        runner = self.runner()
        runner.reconcile([self.job])
        runner.state["jobs"]["chawl"].update(status="running", attempts=1, pid=42, process_token="known")
        with patch.object(nq, "process_alive", return_value=True), patch.object(runner, "execute") as execute:
            self.assertEqual(runner.tick(), "waiting_for_prior_worker")
            execute.assert_not_called()

    def test_outside_window_and_pause_do_not_launch(self):
        runner = self.runner()
        self.now = self.now.replace(hour=8)
        with patch.object(runner, "execute") as execute:
            self.assertEqual(runner.tick(), "outside_window")
            self.now = self.now.replace(hour=22)
            (runner.state_dir / "PAUSE").touch()
            self.assertEqual(runner.tick(), "paused")
            execute.assert_not_called()

    def test_shared_lock_nonblocking(self):
        lock = self.root / "worker.lock"
        command = [sys.executable, "-c", "import importlib.util,pathlib,sys; s=importlib.util.spec_from_file_location('nq',sys.argv[1]); m=importlib.util.module_from_spec(s); s.loader.exec_module(m);\ntry:\n with m.FileLock(pathlib.Path(sys.argv[2])): sys.exit(0)\nexcept m.BusyError: sys.exit(3)", str(MODULE_PATH), str(lock)]
        with nq.FileLock(lock):
            result = subprocess.run(command, capture_output=True, check=False)
            self.assertEqual(result.returncode, 3, result.stderr)
        result = subprocess.run(command, capture_output=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_cutoff_terminates_owned_worker_and_remains_retryable(self):
        cutoff = self.now + timedelta(seconds=1)

        def reach_cutoff(_seconds):
            self.now = cutoff

        runner = self.runner(sleep=reach_cutoff)
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = None
        fake.wait.return_value = -15
        runner.popen = lambda *args, **kwargs: fake
        with patch.object(nq, "terminate_worker") as terminate:
            result = runner.execute(self.job, runner.state["jobs"]["chawl"], cutoff)
        self.assertEqual(result, "interrupted")
        self.assertEqual(runner.state["jobs"]["chawl"]["attempts"], 0)
        terminate.assert_called_once_with(fake)

    def test_window_closing_before_launch_is_retryable_on_every_platform(self):
        cutoff = self.now
        runner = self.runner()
        runner.reconcile([self.job])
        fake_popen = unittest.mock.Mock()
        runner.popen = fake_popen
        result = runner.execute(self.job, runner.state["jobs"]["chawl"], cutoff)
        self.assertEqual(result, "interrupted")
        self.assertEqual(runner.state["jobs"]["chawl"]["attempts"], 0)
        fake_popen.assert_not_called()

    def test_failed_attempt_budget_is_bounded(self):
        runner = self.runner()
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = 7
        fake.wait.return_value = 7
        runner.popen = lambda *args, **kwargs: fake
        record = runner.state["jobs"]["chawl"]
        self.assertEqual(runner.execute(self.job, record, self.now + timedelta(hours=10)), "failed")
        self.assertEqual(runner.execute(self.job, record, self.now + timedelta(hours=10)), "exhausted")
        with patch.object(runner, "execute") as execute:
            self.assertEqual(runner.tick(), "queue_exhausted")
            execute.assert_not_called()

    def test_stop_marker_interrupts_active_owned_worker(self):
        runner = self.runner(sleep=lambda _: None)
        runner.reconcile([self.job])
        (runner.state_dir / "STOP").touch()
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = None
        fake.wait.return_value = -15
        runner.popen = lambda *args, **kwargs: fake
        with patch.object(nq, "terminate_worker") as terminate:
            result = runner.execute(self.job, runner.state["jobs"]["chawl"], self.now + timedelta(hours=10))
        self.assertEqual(result, "interrupted")
        self.assertEqual(runner.state["jobs"]["chawl"]["attempts"], 0)
        terminate.assert_called_once_with(fake)

    def test_successful_process_still_requires_fresh_outputs(self):
        runner = self.runner()
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = 0
        fake.wait.return_value = 0

        def generate(*args, **kwargs):
            self.write_outputs()
            return fake

        runner.popen = generate
        # Real filesystem timestamps belong to the actual test clock.
        runner.now = lambda: datetime.now(timezone.utc)
        result = runner.execute(self.job, runner.state["jobs"]["chawl"], runner.now() + timedelta(hours=1))
        self.assertEqual(result, "completed")
        self.assertEqual(len(runner.state["jobs"]["chawl"]["outputs"]), 2)

    def test_output_cannot_overwrite_queue_configuration(self):
        self.job["outputs"] = ["jobs/queue.json"]
        self.job.pop("validation_report")
        self.write_queue()
        with self.assertRaises(nq.QueueError):
            nq.load_jobs(self.root, "jobs/queue.json")

    def test_linux_guard_bounds_child_and_fails_closed_without_timeout(self):
        with patch.object(nq.sys, "platform", "linux"), patch.object(nq.Path, "is_file", return_value=True):
            command = nq.guarded_command(["/opt/blender", "-b"], 60)
        self.assertEqual(command[1], "--signal=KILL")
        self.assertEqual(command[2], "59.750s")
        self.assertEqual(command[3:], ["/opt/blender", "-b"])
        with patch.object(nq.sys, "platform", "linux"), patch.object(nq.Path, "is_file", return_value=False):
            with self.assertRaises(nq.QueueError):
                nq.guarded_command(["/opt/blender"], 60)

    def test_early_gnu_window_timeout_is_retryable_before_0800(self):
        cutoff = datetime(2026, 11, 20, 8, 0, tzinfo=nq.IST)
        self.now = cutoff - timedelta(seconds=10)
        runner = self.runner()
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = 137
        fake.wait.return_value = 137

        def timeout_early(*args, **kwargs):
            self.now = cutoff - timedelta(seconds=0.1)
            return fake

        runner.popen = timeout_early
        result = runner.execute(self.job, runner.state["jobs"]["chawl"], cutoff)
        self.assertEqual(result, "interrupted")
        self.assertEqual(runner.state["jobs"]["chawl"]["attempts"], 0)
        self.assertIn("cutoff", runner.state["jobs"]["chawl"]["reason"])

    def test_job_timeout_near_0800_still_consumes_failure_attempt(self):
        cutoff = datetime(2026, 11, 20, 8, 0, tzinfo=nq.IST)
        self.now = cutoff - timedelta(seconds=10.1)
        self.job["timeout_seconds"] = 10
        runner = self.runner()
        runner.reconcile([self.job])
        fake = unittest.mock.Mock()
        fake.pid = 999999
        fake.poll.return_value = 137
        fake.wait.return_value = 137

        def timeout_early(*args, **kwargs):
            self.now = cutoff - timedelta(seconds=0.1)
            return fake

        runner.popen = timeout_early
        result = runner.execute(self.job, runner.state["jobs"]["chawl"], cutoff)
        self.assertEqual(result, "failed")
        self.assertEqual(runner.state["jobs"]["chawl"]["attempts"], 1)

    def test_status_read_is_not_a_write(self):
        runner = nq.Supervisor(self.root, "jobs/queue.json", None, now=lambda: self.now)
        self.assertFalse(runner.state_dir.exists())
        self.assertTrue(runner.status()["in_window"])
        self.assertFalse(runner.state_dir.exists())


if __name__ == "__main__":
    unittest.main()
