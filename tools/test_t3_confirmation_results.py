import unittest

from t3_confirmation_results import (
    CARDS, FINGERPRINT, INITIALIZATIONS, expected_keys, validate_records,
)


def record(arm="scripted_food", seed=410001101, card=410000201, checkpoint=0):
    return {
        "experiment_id": "t3_confirmation_v1", "arm": arm,
        "initialization_seed": seed, "card_seed": card, "checkpoint": checkpoint,
        "survived": True, "berries_picked": 2, "berries_eaten": 1,
        "terminated": False, "truncated": True, "actions": 80, "table_checksum": "x",
        "config_fingerprint": FINGERPRINT,
    }


def full_set(mode):
    rows = []
    for (_, arm, seed, card, checkpoint) in sorted(expected_keys(mode)):
        rows.append(record(arm, seed, card, checkpoint))
    return rows


class T3ConfirmationResultsTests(unittest.TestCase):
    def test_expected_sizes(self):
        self.assertEqual(len(INITIALIZATIONS), 5)
        self.assertEqual(len(CARDS["final"]), 64)
        self.assertEqual(len(expected_keys("final")), 5 * 64 * 5)
        self.assertEqual(len(expected_keys("validation")), 5 * 32 * 5)

    def test_final_cards_are_disjoint_from_validation(self):
        self.assertFalse(CARDS["final"] & CARDS["validation"])

    def test_complete_set_is_valid(self):
        self.assertEqual(validate_records(full_set("final"), "final"), [])

    def test_missing_result_is_reported(self):
        errors = validate_records(full_set("final")[1:], "final")
        self.assertTrue(any("résultat manquant" in error for error in errors))

    def test_duplicate_is_reported(self):
        rows = full_set("final")
        rows.append(rows[0])
        self.assertTrue(any("doublon" in error for error in validate_records(rows, "final")))

    def test_validation_cards_rejected_in_final_mode(self):
        rows = full_set("final")
        rows[0] = record(card=410000101)
        errors = validate_records(rows, "final")
        self.assertTrue(any("seed hors réserve" in error for error in errors))

    def test_trained_arm_requires_checkpoint_200(self):
        errors = validate_records([record("trained", checkpoint=50)], "final")
        self.assertTrue(any("checkpoint invalide" in error for error in errors))

    def test_development_seeds_rejected(self):
        errors = validate_records([record(seed=410001001)], "final")
        self.assertTrue(any("seed hors réserve" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
