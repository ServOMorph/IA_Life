import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from run_t0_campaign import expected_records, result_key


class T0CampaignPlanTests(unittest.TestCase):
    def test_expected_plan_is_complete_and_unique(self) -> None:
        records = expected_records()
        self.assertEqual(len(records), 1_248)
        self.assertEqual(len({result_key(record) for record in records}), len(records))

    def test_each_trained_lineage_has_all_checkpoints(self) -> None:
        records = expected_records()
        checkpoints = {record["checkpoint"] for record in records if record["arm"] == "trained" and record["initialization_seed"] == 310001001}
        self.assertEqual(checkpoints, {0, 10, 50, 200, 1000})


if __name__ == "__main__":
    unittest.main()
