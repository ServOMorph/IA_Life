import unittest

from tools.check_danger_calibration import REQUIRED_ARMS, evaluate_point


class CalibrationTest(unittest.TestCase):
    def test_compares_viser_not_ignorer(self):
        arms = {arm: {} for arm in REQUIRED_ARMS}
        for seed in range(12):
            for arm in REQUIRED_ARMS:
                arms[arm][seed] = dict(alive=False, berries=0, lifetime=100, danger_cost=5)
            arms["danger_eviter"][seed].update(alive=seed < 8, berries=2, danger_cost=1)
            arms["danger_ignorer"][seed].update(alive=seed < 8, berries=3, danger_cost=0)
        point = evaluate_point((), arms, 12)
        self.assertTrue(point["gate_passed"])
        self.assertEqual(point["cost_agree"], 12)
        self.assertEqual(point["result_agree_viser"], 12)
        for run in arms["danger_viser"].values():
            run.update(alive=True, berries=5, danger_cost=0)
        point = evaluate_point((), arms, 12)
        self.assertFalse(point["gate_passed"])
        self.assertEqual(point["cost_agree"], 0)
        self.assertEqual(point["result_agree_viser"], 0)

    def test_missing_and_mismatched_seeds_rejected(self):
        self.assertTrue(evaluate_point((), {}, 12)["incomplete"])
        arms = {arm: {s: {} for s in range(12)} for arm in REQUIRED_ARMS}
        arms["aleatoire"][12] = arms["aleatoire"].pop(0)
        self.assertTrue(evaluate_point((), arms, 12)["incomplete"])


if __name__ == "__main__":
    unittest.main()
