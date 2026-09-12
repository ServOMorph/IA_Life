extends Node

const T0QTable = preload("res://scripts/t0_q_table.gd")
const CHECKPOINT := "res://logs/t0_transition_test.json"

var _failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_tie_breaking()
	_test_terminal_and_truncation()
	_test_reward_counted_once()
	_test_frozen_evaluation()
	_test_frozen_selection_after_training()
	_test_save_reload_and_rng()
	_test_incompatible_checkpoint_rejected()
	_test_incompatible_schema_rejected()
	_test_lineages_are_isolated()
	if FileAccess.file_exists(CHECKPOINT):
		DirAccess.remove_absolute(CHECKPOINT)
	if _failures.is_empty():
		print("SUCCÈS : transitions et persistance T0 validées.")
		get_tree().quit(0)
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _table() -> T0QTable:
	var table := T0QTable.new()
	table.configure("t0-contract-v1", 310001001)
	table.begin_episode()
	return table

func _test_tie_breaking() -> void:
	var table := _table()
	var state := table.state_key(2, true, T0QTable.START_ACTION)
	_expect(table.select_greedy(state) == 0, "Les ex æquo T0 doivent choisir l'action 0.")

func _test_terminal_and_truncation() -> void:
	var terminal := _table()
	var state := terminal.state_key(0, true, T0QTable.START_ACTION)
	var next_state := terminal.state_key(1, true, 0)
	terminal.apply_transition(0, next_state, 0, 10.0, next_state, false, false)
	terminal.apply_transition(1, state, 0, 1.0, next_state, true, false)
	_expect(is_equal_approx(terminal._state_values(state)[0], 0.2), "Une fin terminale ne doit pas bootstrapper.")
	var truncated := _table()
	truncated.apply_transition(0, next_state, 0, 10.0, next_state, false, false)
	truncated.apply_transition(1, state, 0, 1.0, next_state, false, true)
	_expect(is_equal_approx(truncated._state_values(state)[0], 0.56), "Une troncature T0 doit bootstrapper l'état final.")

func _test_reward_counted_once() -> void:
	var table := _table()
	var state := table.state_key(0, true, T0QTable.START_ACTION)
	_expect(table.apply_transition(0, state, 0, 1.0, state, true, false), "La transition finale doit être acceptée.")
	var checksum := table.checksum()
	_expect(not table.apply_transition(0, state, 0, 1.0, state, true, false), "Une transition finale dupliquée doit être refusée.")
	_expect(table.checksum() == checksum, "Une transition finale dupliquée ne doit pas modifier la table.")

func _test_frozen_evaluation() -> void:
	var table := _table()
	var state := table.state_key(3, true, T0QTable.START_ACTION)
	var checksum := table.checksum()
	_expect(not table.apply_transition(0, state, 3, 1.0, state, true, false, false), "Une évaluation figée ne doit pas mettre à jour la table.")
	_expect(table.checksum() == checksum, "Le checksum doit rester invariant pendant l'évaluation.")

func _test_frozen_selection_after_training() -> void:
	var table := _table()
	var state := table.state_key(3, true, T0QTable.START_ACTION)
	var training_rng := RandomNumberGenerator.new()
	training_rng.state = table.training_rng_state
	table.select_epsilon_greedy(state, 1.0, training_rng)
	var checksum := table.checksum()
	var evaluation_rng := RandomNumberGenerator.new()
	evaluation_rng.state = table.training_rng_state
	table.select_epsilon_greedy(state, 0.0, evaluation_rng)
	_expect(table.checksum() == checksum, "Une sélection figée après entraînement ne doit pas modifier le RNG de la table.")

func _test_save_reload_and_rng() -> void:
	var table := _table()
	var state := table.state_key(4, true, T0QTable.START_ACTION)
	var rng := RandomNumberGenerator.new()
	rng.seed = 310001001
	table.select_epsilon_greedy(state, 1.0, rng)
	table.apply_transition(0, state, 4, 1.0, state, true, false)
	table.finish_training_episode()
	_expect(table.save_checkpoint(CHECKPOINT) == OK, "La sauvegarde T0 doit réussir.")
	var loaded := T0QTable.load_checkpoint(CHECKPOINT, "t0-contract-v1")
	_expect(loaded != null and loaded.checksum() == table.checksum(), "La recharge T0 doit restaurer exactement la table.")
	var original_rng := RandomNumberGenerator.new()
	original_rng.state = table.training_rng_state
	var loaded_rng := RandomNumberGenerator.new()
	loaded_rng.state = loaded.training_rng_state
	_expect(table.select_epsilon_greedy(state, 1.0, original_rng) == loaded.select_epsilon_greedy(state, 1.0, loaded_rng), "La recharge doit reproduire la suite du RNG d'entraînement.")

func _test_incompatible_checkpoint_rejected() -> void:
	_expect(T0QTable.load_checkpoint(CHECKPOINT, "empreinte-incompatible") == null, "Une empreinte incompatible doit être rejetée.")

func _test_incompatible_schema_rejected() -> void:
	var read_file := FileAccess.open(CHECKPOINT, FileAccess.READ)
	var payload = JSON.parse_string(read_file.get_as_text())
	read_file.close()
	payload["schema_version"] = "schema-incompatible"
	var write_file := FileAccess.open(CHECKPOINT, FileAccess.WRITE)
	write_file.store_string(JSON.stringify(payload))
	write_file.close()
	_expect(T0QTable.load_checkpoint(CHECKPOINT, "t0-contract-v1") == null, "Un schéma incompatible doit être rejeté.")

func _test_lineages_are_isolated() -> void:
	var left := _table()
	var right := _table()
	var state := left.state_key(5, true, T0QTable.START_ACTION)
	left.apply_transition(0, state, 5, 1.0, state, true, false)
	_expect(left.checksum() != right.checksum(), "Deux lignées doivent conserver des paramètres indépendants.")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
