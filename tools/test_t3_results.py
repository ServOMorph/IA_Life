import unittest

from t3_results import expected_t3_keys, validate_records


def valid_record():
    return {
        "experiment_id": "t3_world_v2", "arm": "scripted_food",
        "initialization_seed": 400001001, "card_seed": 400000101, "checkpoint": 0,
        "survived": True, "berries_picked": 2, "berries_eaten": 1,
        "terminated": False, "truncated": True, "actions": 80,
        "table_checksum": "scripted",
        "config_fingerprint": "t3_world_v2|agents=1|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01",
    }


class T3ResultsTests(unittest.TestCase):
    def test_expected_size(self):
        self.assertEqual(len(expected_t3_keys()), 1056)

    def test_validates_complete_shape(self):
        errors = validate_records([valid_record()])
        self.assertFalse(any("résultat 0:" in error for error in errors))

    def test_rejects_duplicate(self):
        record = valid_record()
        self.assertTrue(any("doublon" in error for error in validate_records([record, record.copy()])))

    def test_rejects_incoherent_survival(self):
        record = valid_record()
        record["terminated"] = True
        self.assertTrue(any("fin d'épisode" in error or "survie incohérente" in error
                            for error in validate_records([record])))

    def test_rejects_incoherent_food_counts(self):
        record = valid_record()
        record["berries_eaten"] = 3
        self.assertTrue(any("compte alimentaire" in error for error in validate_records([record])))


if __name__ == "__main__":
    unittest.main()
