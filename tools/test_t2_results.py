import unittest

from t2_results import expected_t2_keys, validate_records


def valid_record():
    return {
        "experiment_id": "t2_memory_v1", "arm": "scripted_memory",
        "initialization_seed": 380001001, "card_seed": 380000101, "checkpoint": 0,
        "consumed": True, "selected_remembered_sector": True, "berries_picked": 1,
        "berries_eaten": 1, "terminated": True, "truncated": False, "actions": 3,
        "policy_decisions": 1, "table_checksum": "scripted",
        "config_fingerprint": "t2_memory_v1|target=1|distances=3,6,9|sectors=8|fov=90|turn=180|actions=8|ticks=15|horizon=24|alpha=0.20|progress=0.50|explore=min_count|execution=hold_first",
    }


class T2ResultsTests(unittest.TestCase):
    def test_expected_size(self):
        self.assertEqual(len(expected_t2_keys()), 1728)

    def test_validates_complete_shape(self):
        record = valid_record()
        errors = validate_records([record])
        self.assertFalse(any("résultat 0:" in error for error in errors))

    def test_rejects_duplicate(self):
        record = valid_record()
        self.assertTrue(any("doublon" in error for error in validate_records([record, record.copy()])))

    def test_rejects_bad_decision_count(self):
        record = valid_record()
        record["policy_decisions"] = 2
        self.assertTrue(any("nombre de décisions" in error for error in validate_records([record])))

    def test_rejects_incoherent_consumption(self):
        record = valid_record()
        record["berries_eaten"] = 0
        self.assertTrue(any("consommation incohérente" in error for error in validate_records([record])))


if __name__ == "__main__":
    unittest.main()
