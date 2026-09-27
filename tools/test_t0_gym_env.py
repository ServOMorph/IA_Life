import json
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

from stable_baselines3.common.env_checker import check_env

from t0_gym_env import ROOT, T0GymEnv


CHECKPOINTS = sorted((ROOT / "experiments" / "t0_v4_checkpoints").glob("trained_*.json"))


class TestT0GymEnv(unittest.TestCase):
    def test_checker_and_reset(self):
        with T0GymEnv() as env:
            check_env(env, warn=True)
            first, info = env.reset(seed=340000101)
            self.assertEqual(first["resource_sector"], 5)
            self.assertEqual(first["previous_action"], 8)
            self.assertEqual(info["action_mask"], [1] * 8)
            for _ in range(5):
                env.step(0)
            repeated, info2 = env.reset(seed=340000101)
            self.assertEqual(first, repeated)
            self.assertNotEqual(info["episode_id"], info2["episode_id"])
            changed, _ = env.reset(seed=340000102)
            self.assertNotEqual(first["resource_sector"], changed["resource_sector"])

    def test_wait_has_no_mutation_and_invalid_steps(self):
        with T0GymEnv() as env:
            obs, info = env.reset(seed=340000101)
            env.connection.sendall((json.dumps({"type": "step", "episode_id": info["episode_id"] + 1,
                                                "step_id": 0, "action": 0}) + "\n").encode())
            self.assertEqual(json.loads(env.reader.readline())["type"], "error")
            time.sleep(0.3)
            env.connection.sendall((json.dumps({"type": "step", "episode_id": info["episode_id"],
                                                "step_id": 1, "action": 0}) + "\n").encode())
            self.assertEqual(json.loads(env.reader.readline())["type"], "error")
            self.assertEqual(env.step_id, 0)
            next_obs, _, _, _, next_info = env.step(0)
            self.assertEqual(next_info["actions"], 1)
            self.assertEqual(next_obs["previous_action"], 0)
            self.assertEqual(next_info["simulated_seconds"], 0.25)

    def test_reset_restores_stock_and_latency_does_not_change_trace(self):
        with T0GymEnv() as first, T0GymEnv() as second:
            first.reset(seed=340000101)
            second.reset(seed=340000101)
            for _ in range(8):
                result_a = first.step(5)
                time.sleep(0.04)
                before = second._request({"type": "inspect"})
                time.sleep(0.04)
                after = second._request({"type": "inspect"})
                self.assertEqual(before, after)
                result_b = second.step(5)
                self.assertEqual(result_a, result_b)
                if result_a[2] or result_a[3]:
                    break
            self.assertTrue(result_a[4]["success"])
            frozen = first._request({"type": "inspect"})
            time.sleep(0.2)
            self.assertEqual(frozen, first._request({"type": "inspect"}))
            first.reset(seed=340000101)
            self.assertEqual(first._request({"type": "inspect"})["info"]["ronce_berries"], 1)
            second.reset(seed=340000102)
            for _ in range(3):
                second.step(0)
            obs, info = second.reset(seed=340000101)
            self.assertEqual(obs["resource_sector"], 5)
            self.assertEqual(info["ronce_berries"], 1)

    def test_horizon_and_restart(self):
        env = T0GymEnv()
        port = env.port
        try:
            env.reset(seed=340000101)
            for index in range(48):
                _, reward, terminated, truncated, info = env.step(0)
                self.assertFalse(terminated)
                self.assertEqual(truncated, index == 47)
                self.assertEqual(reward, 0.0)
            self.assertEqual(info["actions"], 48)
            with self.assertRaises(RuntimeError):
                env.step(0)
        finally:
            env.close()
        with T0GymEnv(port=port) as restarted:
            observation, info = restarted.reset(seed=340000101)
            self.assertEqual(observation["previous_action"], 8)
            self.assertEqual(info["ronce_berries"], 1)

    def test_contact_on_last_tick_is_returned(self):
        with T0GymEnv(diagnostics=True) as env:
            observation, _ = env.reset(seed=101)
            self.assertEqual(env._request({"type": "debug_set_resource_distance", "distance_cm": 322})["type"], "updated")
            for _ in range(3):
                observation, reward, terminated, truncated, info = env.step(observation["resource_sector"])
            self.assertEqual(info["simulated_seconds"], 0.75)
            self.assertEqual(reward, 1.0)
            self.assertTrue(terminated)
            self.assertFalse(truncated)
            self.assertEqual(info["berries_picked"], 1)
            self.assertEqual(info["ronce_berries"], 0)

    def test_reference_policy_and_isolated_workers(self):
        self.assertEqual(len(CHECKPOINTS), 3)
        with T0GymEnv() as first, T0GymEnv() as second:
            self.assertNotEqual(first.port, second.port)
            for checkpoint in CHECKPOINTS:
                with tempfile.TemporaryDirectory() as directory:
                    output = Path(directory) / "reference.json"
                    subprocess.run(["godot", "--headless", "--fixed-fps", "60", "--path", str(ROOT), "--log-file",
                                    str(ROOT / "logs" / "t0_gym_reference.log"),
                                    "--scene", "tools/t0_gym_reference.tscn", "--", str(checkpoint), str(output)],
                                   cwd=ROOT, check=True, capture_output=True)
                    records = json.loads(output.read_text())
                for record in records:
                    obs, _ = first.reset(seed=record["seed"])
                    second.reset(seed=record["seed"])
                    for _ in range(48):
                        action = record["policy"][obs["previous_action"]]
                        obs, reward, terminated, truncated, info = first.step(action)
                        other = second.step(action)
                        self.assertEqual((obs, reward, terminated, truncated, info["berries_picked"]),
                                         (other[0], other[1], other[2], other[3], other[4]["berries_picked"]))
                        if terminated or truncated:
                            break
                    self.assertEqual(info["success"], record["success"], (checkpoint, record, info))
                    self.assertEqual(info["berries_picked"], record["berries_picked"])
                    self.assertEqual(terminated or truncated, True)
                    with self.assertRaises(RuntimeError):
                        first.step(0)


if __name__ == "__main__":
    unittest.main()
