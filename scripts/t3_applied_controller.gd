class_name T3AppliedController
extends Node

## Pilote un personnage avec une table T3 v3 figée, dans le jeu réel. Reproduit la cadence
## du scénario d'évaluation : une décision au début d'une frame physique puis quinze frames
## d'exécution. Ne met jamais la table à jour. Hors conditions de validité du modèle, le
## personnage retombe sur son décideur automate et chaque cycle en repli est compté.

const T3QTableScript = preload("res://scripts/t3_q_table.gd")
const ACTION_TICKS := 15
const INITIAL_PREVIOUS_ACTION := 8
const SCHEMA := "t3_q_table_v3"
const FINGERPRINT := "t3_world_v3|agents=4|fixed_competitors=3|ronces=24|berries=3|danger=0|hunger=50|depletion=4.0|vision=40|memory=5|actions=8|ticks=15|horizon=80|alpha=0.20|gamma=0.90|epsilon=0.20|progress=0.25|time_cost=0.01"
const REASON_MODEL := "modele_indisponible"
const REASON_SPEED := "vitesse_jeu"
const REASON_WORLD := "parametres_monde"
const REASON_OBSERVATION := "observation_invalide"

var checkpoint_path := ""
var table = null
var loaded_checksum := ""
var driving := false
var fallback_reason := ""
var decisions_total := 0
var fallback_cycles_total := 0
var manual_cycles_total := 0
var action_trace: Array = []

var _character = null
var _previous_action := INITIAL_PREVIOUS_ACTION
var _frame := 0
var _last_state := "model"

func configure(character, path: String) -> void:
	_character = character
	checkpoint_path = path

func _ready() -> void:
	_load_model()
	get_tree().physics_frame.connect(_on_physics_frame)

func is_driving() -> bool:
	return driving

func _load_model() -> void:
	if checkpoint_path.is_empty():
		fallback_reason = REASON_MODEL
		_log_load_failure("aucun chemin de modèle")
		return
	table = T3QTableScript.load_checkpoint(checkpoint_path, FINGERPRINT, SCHEMA)
	if table == null:
		fallback_reason = REASON_MODEL
		_log_load_failure("checkpoint absent, illisible, ou schéma/empreinte incompatibles")
		return
	loaded_checksum = table.checksum()
	GameLogger.log_event_data("modele_charge", "%s : modèle appliqué chargé" % _character.display_name, {
		"agent": _character.display_name,
		"checkpoint": checkpoint_path,
		"schema": SCHEMA,
		"fingerprint": FINGERPRINT,
		"episode_count": table.episode_count,
		"checksum_length": loaded_checksum.length(),
		"checksum_hash": loaded_checksum.md5_text(),
	})

func _log_load_failure(detail: String) -> void:
	GameLogger.log_event_data("modele_repli", "%s : modèle indisponible, repli automate (%s)" % [_character.display_name, detail], {
		"agent": _character.display_name,
		"reason": REASON_MODEL,
		"checkpoint": checkpoint_path,
	})
	_last_state = "fallback:" + REASON_MODEL

func _on_physics_frame() -> void:
	if _character == null or not is_instance_valid(_character) or _character.is_dead:
		driving = false
		return
	if is_zero_approx(GameSpeed.time_scale):
		return
	if _frame % ACTION_TICKS == 0:
		_decide()
	_frame += 1

func _decide() -> void:
	if _character.manual_control:
		driving = false
		manual_cycles_total += 1
		_note_state("manual")
		return
	var reason := _unavailable_reason()
	if reason != "":
		driving = false
		fallback_cycles_total += 1
		_note_state("fallback:" + reason, reason)
		return
	var state: String = table.state_key(_character.training_food_observation(_previous_action, false, 0.0))
	if state.is_empty():
		driving = false
		fallback_cycles_total += 1
		_note_state("fallback:" + REASON_OBSERVATION, REASON_OBSERVATION)
		return
	var action: int = table.select_greedy(state)
	_character.set_t0_action(action)
	_previous_action = action
	action_trace.append(action)
	decisions_total += 1
	driving = true
	_note_state("model")

func _unavailable_reason() -> String:
	if table == null:
		return REASON_MODEL
	if not is_equal_approx(GameSpeed.time_scale, 1.0):
		return REASON_SPEED
	if not _world_matches_contract():
		return REASON_WORLD
	return ""

func _world_matches_contract() -> bool:
	return (is_equal_approx(_character.vision_range, 40.0)
		and is_equal_approx(_character.vision_angle_degrees, 360.0)
		and _character.memory_capacity == 5
		and is_equal_approx(_character.hunger_depletion_rate, 4.0)
		and GameConfig.max_berries_carried == 3
		and is_equal_approx(GameConfig.pickup_hunger_threshold, 90.0)
		and is_equal_approx(GameConfig.eat_hunger_threshold, 50.0)
		and is_equal_approx(GameConfig.full_life_berries, 6.0)
		and GameConfig.danger_zone_count == 0)

func _note_state(state: String, reason: String = "") -> void:
	if state == _last_state:
		return
	_last_state = state
	if state.begins_with("fallback:"):
		GameLogger.log_event_data("modele_repli", "%s : repli automate (%s)" % [_character.display_name, reason], {
			"agent": _character.display_name,
			"reason": reason,
		})
	elif state == "manual":
		GameLogger.log_event_data("modele_repli", "%s : contrôle manuel prioritaire" % _character.display_name, {
			"agent": _character.display_name,
			"reason": "controle_manuel",
		})
	else:
		GameLogger.log_event_data("modele_reprise", "%s : modèle de nouveau actif" % _character.display_name, {
			"agent": _character.display_name,
		})

func table_unchanged() -> bool:
	return table != null and table.checksum() == loaded_checksum

func summary(reason: String) -> Dictionary:
	return {
		"agent": _character.display_name,
		"reason": reason,
		"checkpoint": checkpoint_path,
		"model_loaded": table != null,
		"decisions_total": decisions_total,
		"fallback_cycles_total": fallback_cycles_total,
		"manual_cycles_total": manual_cycles_total,
		"table_unchanged": table_unchanged() if table != null else true,
	}

func log_summary(reason: String) -> void:
	GameLogger.log_event_data("modele_bilan", "%s : bilan du modèle appliqué" % _character.display_name, summary(reason))
