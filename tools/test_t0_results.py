import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from t0_results import validate_records


def record(card_seed: int) -> dict:
    return {
        "experiment_id": "t0_v1",
        "arm": "trained",
        "initialization_seed": 310001001,
        "card_seed": card_seed,
        "checkpoint": 10,
        "success": True,
        "terminated": True,
        "truncated": False,
        "table_checksum": "abc",
        "config_fingerprint": "t0-contract-v1",
    }


class T0ResultsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.first = record(310000101)
        self.second = record(310000102)
        self.expected = {
            ("t0_v1", "trained", 310001001, 310000101, 10),
            ("t0_v1", "trained", 310001001, 310000102, 10),
        }

    def test_complete_batch_is_accepted(self) -> None:
        self.assertEqual(validate_records([self.first, self.second], self.expected), [])

    def test_missing_run_is_rejected(self) -> None:
        errors = validate_records([self.first], self.expected)
        self.assertTrue(any("résultat manquant" in error for error in errors))

    def test_duplicate_is_rejected(self) -> None:
        errors = validate_records([self.first, self.first, self.second], self.expected)
        self.assertTrue(any("doublon" in error for error in errors))

    def test_seed_crossing_is_rejected(self) -> None:
        crossed = record(310000201)
        errors = validate_records([self.first, crossed], self.expected)
        self.assertTrue(any("identifiant inattendu" in error for error in errors))

    def test_required_identifier_is_preserved(self) -> None:
        incomplete = record(310000102)
        del incomplete["initialization_seed"]
        errors = validate_records([self.first, incomplete], self.expected)
        self.assertTrue(any("champ manquant initialization_seed" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
