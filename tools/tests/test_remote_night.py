"""Focused local security/transport tests; no SSH, worker, Blender, or sleeps."""
import base64
import ast
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, MagicMock

SPEC = importlib.util.spec_from_file_location("remote_night", Path(__file__).parents[1] / "remote_night.py")
remote = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = remote
SPEC.loader.exec_module(remote)


class RemoteNightTests(unittest.TestCase):
    def test_config_rejects_shell_and_path_injection(self):
        cases = ({"host": "host;touch-bad"}, {"user": "root -oProxyCommand=bad"},
                 {"host": "-bad"}, {"remote_root": "/root/motion/../other/mumbai-gully-heat"},
                 {"remote_root": "/root/motion"}, {"remote_root": "/tmp/mumbai-gully-heat"},
                 {"blender": "/usr/bin/python"}, {"shared_lock": "/tmp/lock"},
                 {"threads": True}, {"port": 0})
        for kwargs in cases:
            with self.subTest(kwargs=kwargs), self.assertRaises(remote.RemoteError):
                remote.RemoteConfig(**kwargs)

    def test_ssh_is_fixed_noninteractive_and_host_verified(self):
        command = remote.ssh_command(remote.RemoteConfig())
        self.assertIn("BatchMode=yes", command)
        self.assertIn("StrictHostKeyChecking=yes", command)
        self.assertEqual(command[-3:], ["root@10.64.100.159", "python3", "-"])
        self.assertNotIn("sh", command)

    def test_rpc_passes_data_over_stdin_without_a_shell(self):
        execute = Mock(return_value=subprocess.CompletedProcess([], 0, b'{"ok":true,"result":{"running":false}}', b""))
        result = remote.rpc(remote.RemoteConfig(), "status", run=execute)
        self.assertFalse(result["running"])
        kwargs = execute.call_args.kwargs
        self.assertNotIn("shell", kwargs)
        self.assertEqual(kwargs["timeout"], 60)
        self.assertIn(b"PAYLOAD = json.loads(", kwargs["input"])
        self.assertEqual(execute.call_args.args[0][-2:], ["python3", "-"])

    def test_allowlist_excludes_credentials_references_and_tests(self):
        for path in ("tools/night_queue.py", "tools/modeling/__init__.py", "tools/modeling/chawl.py",
                     "jobs/specs/smoke.json", "docs/OVERNIGHT_MODELING.md"):
            self.assertTrue(remote.allowed_deploy(path), path)
        for path in ("jobs/remote.json", ".ssh/id_rsa", "assets/references/photo.jpg", "tools/tests/test_x.py",
                     "tools/modeling/../night_queue.py", "tools/modeling/nested/x.py", "/root/key", "jobs/specs/a.json.exe"):
            self.assertFalse(remote.allowed_deploy(path), path)

    def test_deployment_contains_only_allowlisted_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative in remote.EXACT_DEPLOY | {"tools/modeling/core.py", "jobs/specs/example.json", "jobs/remote.json", ".env"}:
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("{}", encoding="utf-8")
            files = remote.deployment_files(root)
            paths = {item["path"] for item in files}
            self.assertIn("tools/modeling/core.py", paths)
            self.assertNotIn("jobs/remote.json", paths)
            self.assertNotIn(".env", paths)
            for item in files:
                self.assertEqual(hashlib.sha256(base64.b64decode(item["base64"])).hexdigest(), item["sha256"])

    def test_local_symlink_escape_is_refused(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "outside").mkdir()
            try:
                (root / "alias").symlink_to(root / "outside", target_is_directory=True)
            except OSError:
                self.skipTest("This Windows user cannot create test symlinks")
            with self.assertRaises(remote.RemoteError):
                remote.confined(root, "alias/output.glb")

    def test_collection_diagnostics_cannot_replace_operational_state(self):
        self.assertEqual(remote.collection_target(".night-queue/state.json", "epyc24"), "reports/remote/epyc24/state.json")
        for path in ("tools/night_queue.py", "jobs/remote.json", "assets/generated/../key", ".night-queue/../key"):
            with self.subTest(path=path), self.assertRaises(remote.RemoteError):
                remote.collection_target(path, "epyc24")

    def test_collection_checks_declared_paths_and_hashes(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "jobs").mkdir()
            (root / "jobs/night-queue.json").write_text(json.dumps({"version": 1, "jobs": [{"outputs": ["assets/generated/one/model.glb"]}]}))
            data = b"glTF-test"
            def fake_rpc(_config, action, *, extra):
                if action == "collect-list":
                    return {"files": [{"path": "assets/generated/one/model.glb", "size": len(data)}, {"path": ".night-queue/state.json", "size": len(data)}]}
                return {"path": extra["path"], "size": len(data), "sha256": hashlib.sha256(data).hexdigest(), "base64": base64.b64encode(data).decode()}
            result = remote.collect(root, remote.RemoteConfig(), call=fake_rpc)
            self.assertEqual(result["files"], 2)
            self.assertEqual((root / "assets/generated/one/model.glb").read_bytes(), data)
            self.assertFalse((root / ".night-queue/state.json").exists())
            self.assertEqual((root / "reports/remote/epyc24/state.json").read_bytes(), data)

    def test_collection_rejects_undeclared_output(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "jobs").mkdir()
            (root / "jobs/night-queue.json").write_text('{"version":1,"jobs":[]}')
            fake_rpc = Mock(return_value={"files": [{"path": "assets/generated/unknown/model.glb", "size": 1}]})
            with self.assertRaises(remote.RemoteError):
                remote.collect(root, remote.RemoteConfig(), call=fake_rpc)
            self.assertEqual(fake_rpc.call_count, 1)

    def test_remote_program_compiles_without_executing(self):
        compile(remote.REMOTE_PROGRAM, "<fixed-remote-program>", "exec")

    def test_clock_calibration_uses_local_midpoint_and_preserves_uncertainty(self):
        clock = Mock(return_value={"utc_unix_seconds": 855.0})
        result = remote.calibrate_clock(remote.RemoteConfig(), call=clock,
                                      wall_time=Mock(side_effect=[1000.0, 1002.0]),
                                      monotonic=Mock(side_effect=[20.0, 22.0]))
        self.assertEqual(result["clock_offset_seconds"], 146.0)
        self.assertEqual(result["clock_calibration"]["round_trip_seconds"], 2.0)
        self.assertEqual(result["clock_calibration"]["uncertainty_seconds"], 1.0)
        clock.assert_called_once_with(remote.RemoteConfig(), "clock")

    def test_clock_calibration_refuses_delay_drift_invalid_remote_and_local_jump(self):
        cases = [([1000.0, 1011.0], [0.0, 11.0], 1005.0),
                 ([1000.0, 1000.0], [0.0, 0.0], -801.0),
                 ([1000.0, 1001.0], [0.0, 1.0], float("nan")),
                 ([1000.0, 1001.0], [0.0, 1.0], True),
                 ([1000.0, 1010.0], [0.0, 1.0], 1000.0)]
        for wall, monotonic, stamp in cases:
            with self.subTest(stamp=stamp, wall=wall), self.assertRaises(remote.RemoteError):
                remote.calibrate_clock(remote.RemoteConfig(),
                    call=Mock(return_value={"utc_unix_seconds": stamp}),
                    wall_time=Mock(side_effect=wall), monotonic=Mock(side_effect=monotonic))

    def test_start_and_resume_pass_calibration_but_status_does_not_sample(self):
        config = remote.RemoteConfig()
        calibration = {"clock_offset_seconds": 146.0, "clock_calibration": {"offset_seconds": 146.0}}
        for action in ("start", "resume"):
            rpc = Mock(return_value={"started": True})
            sample = Mock(return_value=calibration)
            remote.control(config, action, call=rpc, calibrate=sample)
            sample.assert_called_once_with(config)
            rpc.assert_called_once_with(config, action, extra=calibration)
        sample, rpc = Mock(), Mock(return_value={})
        remote.control(config, "status", call=rpc, calibrate=sample)
        sample.assert_not_called()
        rpc.assert_called_once_with(config, "status")

    def test_fixed_remote_start_passes_offset_to_worker_and_records_receipt(self):
        # Execute only the fixed start function with local fake dependencies.
        # No remote program dispatch, SSH, worker, Blender, or sleep occurs.
        parsed = ast.parse(remote.REMOTE_PROGRAM)
        function = next(n for n in parsed.body if isinstance(n, ast.FunctionDef) and n.name == "start")
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            for relative in ("tools/night_queue.py", "jobs/night-queue.json"):
                target = root / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text("{}")
            (root / ".night-queue").mkdir()
            blender = MagicMock()
            blender.name = "blender"
            blender.is_file.return_value = True
            blender.is_relative_to.return_value = True
            shared, nice = MagicMock(), MagicMock()
            shared.parent.is_dir.return_value = True
            nice.is_file.return_value = True
            process = Mock()
            process.pid = 123
            subprocess_stub = Mock()
            subprocess_stub.run.return_value = subprocess.CompletedProcess([], 0, b"", b"")
            subprocess_stub.Popen.return_value = process
            writer = Mock()
            payload = {"blender": remote.RemoteConfig().blender, "shared_lock": remote.RemoteConfig().shared_lock,
                       "threads": 8, "clock_offset_seconds": 146.0,
                       "clock_calibration": {"offset_seconds": 146.0}}
            scope = {"identity": lambda: None, "inside": lambda rel: root / rel,
                     "guard_absolute": lambda value: blender if value == payload["blender"] else shared,
                     "PAYLOAD": payload, "ROOT": root, "Path": lambda _: nice,
                     "sys": sys, "os": remote.os, "math": remote.math, "json": json,
                     "subprocess": subprocess_stub, "proc_token": lambda _: "test-token",
                     "atomic_write": writer, "status": lambda: {"running": True}}
            exec(compile(ast.Module(body=[function], type_ignores=[]), "<isolated-start>", "exec"), scope)
            self.assertTrue(scope["start"]()["started"])
            command = subprocess_stub.Popen.call_args.args[0]
            index = command.index("--clock-offset-seconds")
            self.assertEqual(command[index + 1], "146.0")
            self.assertIn("--clock-offset-seconds", subprocess_stub.run.call_args.args[0])
            receipt = json.loads(writer.call_args.args[1])
            self.assertEqual(receipt["clock_offset_seconds"], 146.0)
            self.assertEqual(receipt["clock_calibration"], payload["clock_calibration"])


if __name__ == "__main__":
    unittest.main()
