import json
import os
import subprocess
import unittest
from pathlib import Path

import numpy as np
from stable_baselines3.common.env_checker import check_env

from t3_gym_env import T3GymEnv


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GODOT = "D:/Godot/godot_console.exe"
GODOT = os.environ.get("IA_LIFE_GODOT", DEFAULT_GODOT)
ACTIONS = tuple(range(8)) * 2


class TestT3GymEnv(unittest.TestCase):
    def test_checker_and_contract(self):
        with T3GymEnv(godot=GODOT) as env:
            check_env(env, warn=True)
            observation, info = env.reset(seed=400000001)
            self.assertTrue(env.observation_space.contains(observation))
            self.assertEqual(observation["previous_action"], 8)
            self.assertEqual(info["actions"], 0)
            self.assertEqual(info["action_mask"], [1] * 8)
            for _ in range(80):
                observation, _, terminated, truncated, info = env.step(0)
                if terminated or truncated:
                    break
            self.assertTrue(terminated or truncated)
            self.assertLessEqual(info["actions"], 80)
            if truncated:
                self.assertTrue(info["survived"])
                self.assertEqual(info["actions"], 80)

    def test_direct_and_bridge_trajectories_are_identical(self):
        for seed in (400000001, 400000008):
            direct = self._direct_trace(seed)
            with T3GymEnv(godot=GODOT) as env:
                observation, info = env.reset(seed=seed)
                bridge = [(observation, 0.0, False, False, info)]
                for action in ACTIONS:
                    step = env.step(action)
                    bridge.append(step)
                    if step[2] or step[3]:
                        break
            self.assertEqual(len(direct), len(bridge))
            for direct_step, bridge_step in zip(direct, bridge):
                direct_observation = T3GymEnv._observation({"observation": direct_step["observation"]})
                bridge_observation, reward, terminated, truncated, info = bridge_step
                self.assertEqual(set(direct_observation), set(bridge_observation))
                for key in direct_observation:
                    np.testing.assert_allclose(direct_observation[key], bridge_observation[key], rtol=0, atol=1e-6)
                self.assertAlmostEqual(direct_step["reward"], reward, places=6)
                self.assertEqual(direct_step["terminated"], terminated)
                self.assertEqual(direct_step["truncated"], truncated)
                for key in ("actions", "berries_picked", "berries_eaten", "survived", "simulated_seconds", "action_mask"):
                    self.assertEqual(direct_step["info"][key], info[key])

    @staticmethod
    def _direct_trace(seed):
        command = [GODOT, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
                   "--log-file", str(ROOT / "logs" / f"t3_direct_trace_{seed}.log"),
                   "--scene", "tools/t3_direct_trace.tscn", "--", "--seed", str(seed),
                   "--actions", ",".join(map(str, ACTIONS))]
        completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=30, check=True)
        return [json.loads(line.removeprefix("T3_TRACE ")) for line in completed.stdout.splitlines()
                if line.startswith("T3_TRACE ")]


if __name__ == "__main__":
    unittest.main()
