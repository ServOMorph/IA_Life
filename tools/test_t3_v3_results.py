import unittest

from t3_v3_results import expected_t3_keys, validate_records


def valid_record():
    return {
        "experiment_id": "t3_world_v3", "arm": "scripted_food",
        "initialization_seed": 410001001, "card_seed": 410000101, "checkpoint": 0,
        "survived": True, "berries_picked": 2, "berries_eaten": 1,
        "terminated": False, "truncated": True, "actions": 80, "table_checksum": "scripted",
        "config_fingerprint": "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01",
    }


class T3V3ResultsTests(unittest.TestCase):
    def test_expected_size(self):
        self.assertEqual(len(expected_t3_keys()), 1056)

    def test_valid_record_shape(self):
        self.assertFalse(any("résultat 0:" in error for error in validate_records([valid_record()])))

    def test_rejects_v2_seed_and_fingerprint(self):
        record = valid_record()
        record["card_seed"] = 400000101
        record["config_fingerprint"] = record["config_fingerprint"].replace("v3", "v2")
        errors = validate_records([record])
        self.assertTrue(any("seed hors réserve" in error for error in errors))
        self.assertTrue(any("empreinte invalide" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
