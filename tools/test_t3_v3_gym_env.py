import json
import os
import subprocess
import unittest
from pathlib import Path

import numpy as np

from t3_v3_gym_env import T3V3GymEnv


ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("IA_LIFE_GODOT", "D:/Godot/godot_console.exe")
ACTIONS = tuple(range(8)) * 2


class TestT3V3GymEnv(unittest.TestCase):
    def test_direct_and_bridge_trajectories_are_identical(self):
        seed = 410000001
        direct = self._direct_trace(seed)
        with T3V3GymEnv(godot=GODOT) as env:
            observation, info = env.reset(seed=seed)
            bridge = [(observation, 0.0, False, False, info)]
            for action in ACTIONS:
                step = env.step(action)
                bridge.append(step)
                if step[2] or step[3]:
                    break
        self.assertEqual(len(direct), len(bridge))
        for direct_step, bridge_step in zip(direct, bridge):
            direct_observation = T3V3GymEnv._observation({"observation": direct_step["observation"]})
            bridge_observation, reward, terminated, truncated, info = bridge_step
            for key in direct_observation:
                np.testing.assert_allclose(direct_observation[key], bridge_observation[key], rtol=0, atol=1e-6)
            self.assertAlmostEqual(direct_step["reward"], reward, places=6)
            self.assertEqual((direct_step["terminated"], direct_step["truncated"]), (terminated, truncated))
            for key in ("actions", "berries_picked", "berries_eaten", "survived", "simulated_seconds", "action_mask"):
                self.assertEqual(direct_step["info"][key], info[key])

    @staticmethod
    def _direct_trace(seed):
        command = [GODOT, "--headless", "--fixed-fps", "60", "--path", str(ROOT),
                   "--log-file", str(ROOT / "logs" / f"t3_v3_direct_trace_{seed}.log"),
                   "--scene", "tools/t3_direct_trace.tscn", "--", "--seed", str(seed),
                   "--actions", ",".join(map(str, ACTIONS)), "--competitors", "1"]
        completed = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=60, check=True)
        return [json.loads(line.removeprefix("T3_TRACE ")) for line in completed.stdout.splitlines()
                if line.startswith("T3_TRACE ")]


if __name__ == "__main__":
    unittest.main()
