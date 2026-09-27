import unittest

from t1_results import EXPERIMENT_ID, FINGERPRINT, FINGERPRINT_V3, FINGERPRINT_V4, expected_t1_keys, result_key, validate_records


class T1ResultsTests(unittest.TestCase):
    def setUp(self):
        self.record = {
            "experiment_id": EXPERIMENT_ID,
            "arm": "trained",
            "initialization_seed": 320001001,
            "card_seed": 320000101,
            "checkpoint": 0,
            "consumed": True,
            "first_selected_available": True,
            "berries_picked": 1,
            "berries_eaten": 1,
            "terminated": True,
            "truncated": False,
            "actions": 10,
            "table_checksum": "test",
            "config_fingerprint": FINGERPRINT,
        }
        self.expected = {result_key(self.record)}

    def test_valid_record_and_full_manifest_size(self):
        self.assertEqual(validate_records([self.record], self.expected), [])
        self.assertEqual(len(expected_t1_keys()), 1248)

    def test_missing_duplicate_and_wrong_seed(self):
        self.assertIn("manquant", " ".join(validate_records([], self.expected)))
        self.assertIn("doublon", " ".join(validate_records([self.record, self.record], self.expected)))
        invalid = dict(self.record, card_seed=320000201)
        self.assertIn("hors réserve", " ".join(validate_records([invalid], self.expected)))

    def test_causal_field_and_boolean(self):
        missing = dict(self.record)
        del missing["first_selected_available"]
        self.assertIn("champ manquant", " ".join(validate_records([missing], self.expected)))
        invalid = dict(self.record, first_selected_available=1)
        self.assertIn("champ invalide", " ".join(validate_records([invalid], self.expected)))

    def test_fingerprint_and_outcome(self):
        invalid = dict(self.record, config_fingerprint="other", consumed=False)
        errors = " ".join(validate_records([invalid], self.expected))
        self.assertIn("empreinte invalide", errors)
        self.assertIn("consommation incohérente", errors)

    def test_v3_reserve_and_fingerprint(self):
        record = dict(self.record, experiment_id="t1_choice_v3", config_fingerprint=FINGERPRINT_V3,
                      card_seed=350000101, initialization_seed=350001001)
        self.assertEqual(validate_records([record], {result_key(record)}, "v3"), [])
        self.assertEqual(len(expected_t1_keys("v3")), 1248)
        invalid = dict(record, card_seed=320000101)
        self.assertIn("seed hors réserve", " ".join(validate_records([invalid], {result_key(record)}, "v3")))

    def test_v4_reserve_and_fingerprint(self):
        record = dict(self.record, experiment_id="t1_choice_v4", config_fingerprint=FINGERPRINT_V4,
                      card_seed=360000101, initialization_seed=360001001)
        self.assertEqual(validate_records([record], {result_key(record)}, "v4"), [])
        self.assertEqual(len(expected_t1_keys("v4")), 1248)
        invalid = dict(record, card_seed=350000101)
        self.assertIn("seed hors réserve", " ".join(validate_records([invalid], {result_key(record)}, "v4")))


if __name__ == "__main__":
    unittest.main()
