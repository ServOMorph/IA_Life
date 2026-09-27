import time
import unittest

import numpy as np
from stable_baselines3.common.env_checker import check_env

from world_gym_env import WorldGymEnv


DIRECTIONS = np.asarray([[0, -1], [1, -1], [1, 0], [1, 1],
                         [0, 1], [-1, 1], [-1, 0], [-1, -1]], dtype=np.float32)
DIRECTIONS /= np.linalg.norm(DIRECTIONS, axis=1)[:, None]


class TestWorldGymEnv(unittest.TestCase):
    def test_checker_observation_and_no_hidden_map(self):
        with WorldGymEnv() as env:
            check_env(env, warn=True)
            observation, info = env.reset(seed=7)
            self.assertTrue(env.observation_space.contains(observation))
            self.assertEqual(observation["previous_action"], 8)
            self.assertEqual(info["action_mask"], [1] * 8)
            self.assertEqual(set(observation), {"hunger", "inventory", "targets", "memories",
                                                 "collision", "progress", "previous_action"})
            targets = observation["targets"].reshape(3, 5)
            self.assertGreater(targets[:, 0].sum(), 0)
            self.assertTrue(np.all(targets[targets[:, 0] == 0] == 0))
            with self.assertRaises(RuntimeError):
                env._request({"type": "debug_snapshot"})

    def test_world_reset_agents_resources_and_latency(self):
        with WorldGymEnv(diagnostics=True) as first, WorldGymEnv(diagnostics=True) as second:
            initial, _ = first.reset(seed=123)
            second.reset(seed=123)
            snapshot = first._request({"type": "debug_snapshot"})["state"]
            self.assertEqual(snapshot, second._request({"type": "debug_snapshot"})["state"])
            self.assertEqual(len(snapshot["agents"]), 4)
            self.assertEqual(len(snapshot["resources"]), 24)
            for action in (0, 2, 4, 6):
                result_a = first.step(action)
                time.sleep(0.03)
                frozen = second._request({"type": "debug_snapshot"})["state"]
                time.sleep(0.03)
                self.assertEqual(frozen, second._request({"type": "debug_snapshot"})["state"])
                result_b = second.step(action)
                self.assertEqual(result_a[1:4], result_b[1:4])
                self.assertEqual(result_a[4], result_b[4])
                for name in initial:
                    np.testing.assert_array_equal(result_a[0][name], result_b[0][name])
            moved = first._request({"type": "debug_snapshot"})["state"]
            self.assertNotEqual(snapshot["agents"], moved["agents"])
            second.step(3)
            self.assertNotEqual(moved["agents"], second._request({"type": "debug_snapshot"})["state"]["agents"])
            reset, _ = first.reset(seed=123)
            self.assertEqual(snapshot, first._request({"type": "debug_snapshot"})["state"])
            for name in initial:
                np.testing.assert_array_equal(initial[name], reset[name])
            first.reset(seed=124)
            changed = first._request({"type": "debug_snapshot"})["state"]
            self.assertNotEqual(snapshot["resources"], changed["resources"])
            second.reset(seed=123)
            self.assertEqual(snapshot, second._request({"type": "debug_snapshot"})["state"])

    def test_pickup_and_reset_stock(self):
        with WorldGymEnv(diagnostics=True) as env:
            observation, _ = env.reset(seed=1)
            initial = env._request({"type": "debug_snapshot"})["state"]
            for index in range(100):
                target = observation["targets"].reshape(3, 5)[0]
                action = int(np.argmax(DIRECTIONS @ target[1:3])) if target[0] else 0
                observation, _, terminated, truncated, info = env.step(action)
                if index == 0 and target[0]:
                    self.assertGreater(observation["progress"][0], 0.0)
                if info["berries_picked"] > 0 or terminated or truncated:
                    break
            self.assertGreater(info["berries_picked"], 0)
            self.assertGreater(observation["memories"].reshape(3, 5)[:, 0].sum(), 0)
            consumed = env._request({"type": "debug_snapshot"})["state"]
            self.assertNotEqual(initial["resources"], consumed["resources"])
            time.sleep(0.2)
            self.assertEqual(consumed, env._request({"type": "debug_snapshot"})["state"])
            changed_index = next(index for index, (before, after) in enumerate(zip(initial["resources"], consumed["resources"]))
                                 if before[3] != after[3])
            env._request({"type": "debug_place_at_west_wall"})
            distant = env._request({"type": "debug_snapshot"})["state"]
            actor = distant["agents"][0]
            resource = distant["resources"][changed_index]
            self.assertGreater(np.hypot(actor[1] - resource[0], actor[3] - resource[2]), 25.0)
            hidden_before = env._request({"type": "inspect"})["observation"]
            env._request({"type": "debug_set_resource_stock", "index": changed_index, "stock": 0})
            hidden_after = env._request({"type": "inspect"})["observation"]
            self.assertEqual(hidden_before, hidden_after)
            env.reset(seed=1)
            self.assertEqual(initial, env._request({"type": "debug_snapshot"})["state"])

    def test_horizon_and_restart(self):
        env = WorldGymEnv()
        port = env.port
        try:
            env.reset(seed=123)
            for _ in range(120):
                _, _, terminated, truncated, info = env.step(0)
                if terminated or truncated:
                    break
            self.assertTrue(terminated or truncated)
            self.assertEqual(info["actions"], env.step_id)
            with self.assertRaises(RuntimeError):
                env.step(0)
        finally:
            env.close()
        with WorldGymEnv(port=port) as restarted:
            observation, info = restarted.reset(seed=123)
            self.assertEqual(observation["previous_action"], 8)
            self.assertEqual(info["actions"], 0)

    def test_restart_after_process_interruption(self):
        env = WorldGymEnv()
        port = env.port
        try:
            env.reset(seed=123)
            env.step(0)
            env.process.terminate()
            env.process.wait(timeout=5)
        finally:
            env.close()
        with WorldGymEnv(port=port) as restarted:
            observation, info = restarted.reset(seed=123)
            self.assertEqual(observation["previous_action"], 8)
            self.assertEqual(info["actions"], 0)

    def test_boundary_collision_is_observed(self):
        with WorldGymEnv(diagnostics=True) as env:
            env.reset(seed=123)
            self.assertEqual(env._request({"type": "debug_place_at_west_wall"})["type"], "updated")
            observation, _, _, _, _ = env.step(6)
            self.assertEqual(observation["collision"], 1)


if __name__ == "__main__":
    unittest.main()
