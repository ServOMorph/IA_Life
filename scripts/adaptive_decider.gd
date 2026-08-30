class_name AdaptiveDecider
extends RefCounted

## Décideur adaptatif : en situation de faim, discrétise l'observation en trois situations
## et choisit l'action de recherche de nourriture par ε-greedy sur une table
## (situation, action) -> score. Hors situation de faim, le comportement est celui de
## BaselineDecider (contrôle manuel, puis social, puis errance).
##
## L'action choisie est tenue pendant decision_interval_seconds de temps simulé : le
## décideur est interrogé à chaque frame physique, mais ne retire une action que lorsque
## son engagement expire, que la situation change ou que l'action devient invalide. Sans
## cet engagement, l'agent change d'avis 60 fois par seconde et la variation de faim entre
## deux décisions consécutives n'est plus qu'un bruit inexploitable comme récompense.
## La direction, elle, est recalculée à chaque frame à partir de l'action tenue : c'est
## l'action qui est figée, pas la trajectoire.
##
## Phase 1 : la table est initialisée neutre et n'est jamais mise à jour. La décision en
## cours est mémorisée (pending) pour que la Phase 2 puisse calculer la récompense sur la
## fenêtre d'engagement.

const SITUATION_RONCE_VISIBLE := "S1_ronce_visible"
const SITUATION_MEMOIRE := "S2_memoire"
const SITUATION_INCONNU := "S3_inconnu"

const ACTION_RONCE_VISIBLE := "ronce_visible"
const ACTION_RONCE_MEMORISEE := "ronce_memorisee"
const ACTION_ERRANCE := "errance"

const SITUATIONS := [SITUATION_RONCE_VISIBLE, SITUATION_MEMOIRE, SITUATION_INCONNU]
const ACTIONS_BY_SITUATION := {
	SITUATION_RONCE_VISIBLE: [ACTION_RONCE_VISIBLE, ACTION_RONCE_MEMORISEE, ACTION_ERRANCE],
	SITUATION_MEMOIRE: [ACTION_RONCE_MEMORISEE, ACTION_ERRANCE],
	SITUATION_INCONNU: [ACTION_ERRANCE],
}
const INITIAL_SCORE := 0.0

var learning_rate := 0.2
var exploration_epsilon := 0.2
var decision_interval_seconds := 2.0
var agent_name := ""

var last_situation := ""
var last_action := ""
var last_explored := false
var decisions_total := 0

var _scores: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _pending: Dictionary = {}
var _engaged_situation := ""
var _engaged_action := ""
var _engagement_timer := 0.0

func _init() -> void:
	reset_table()

func configure(rate: float, epsilon: float, interval_seconds: float, rng_seed: int, name: String = "") -> void:
	learning_rate = rate
	exploration_epsilon = epsilon
	decision_interval_seconds = interval_seconds
	agent_name = name
	_rng.seed = rng_seed

func reset_table() -> void:
	_scores = {}
	for situation in SITUATIONS:
		var row := {}
		for action in ACTIONS_BY_SITUATION[situation]:
			row[action] = INITIAL_SCORE
		_scores[situation] = row

func get_score(situation: String, action: String) -> float:
	if not _scores.has(situation):
		return INITIAL_SCORE
	return float(_scores[situation].get(action, INITIAL_SCORE))

func set_score(situation: String, action: String, value: float) -> void:
	if _scores.has(situation) and _scores[situation].has(action):
		_scores[situation][action] = value

func table_snapshot() -> Dictionary:
	var copy := {}
	for situation in _scores:
		copy[situation] = (_scores[situation] as Dictionary).duplicate()
	return copy

func pending_decision() -> Dictionary:
	return _pending.duplicate()

func engaged_action() -> String:
	return _engaged_action

func engagement_remaining() -> float:
	return _engagement_timer

func decide(observation: Dictionary) -> Dictionary:
	if observation["manual_control"]:
		_release_engagement()
		return {"goal": "controle_manuel", "direction": observation["manual_direction"], "renew_wander": false}
	if not _is_hunger_situation(observation):
		_release_engagement()
		return _fallback_action(observation)

	var situation := classify(observation)
	var actions := available_actions(situation, observation)
	_engagement_timer -= float(observation.get("delta", 0.0))
	if _must_decide(situation, actions):
		_engaged_situation = situation
		_engaged_action = _select_action(situation, actions)
		_engagement_timer = decision_interval_seconds
		decisions_total += 1
		_record_pending(situation, _engaged_action, observation)

	var targeted := _build_targeted_action(_engaged_action, observation)
	if not targeted.is_empty():
		return targeted
	return _fallback_action(observation)

## Une décision est reprise quand l'engagement expire, quand la situation discrétisée
## change (le crédit d'une cellule doit couvrir une période où sa situation était réelle)
## ou quand l'action tenue n'est plus applicable.
func _must_decide(situation: String, actions: Array) -> bool:
	if _engaged_action == "":
		return true
	if _engagement_timer <= 0.0:
		return true
	if _engaged_situation != situation:
		return true
	return not actions.has(_engaged_action)

func _release_engagement() -> void:
	_engaged_situation = ""
	_engaged_action = ""
	_engagement_timer = 0.0

## Cibler un roncier n'a de sens que si la cueillette y est effectivement possible
## (character.gd::try_pick_berry_from_ronce) : faim sous le seuil ET inventaire non plein.
func _is_hunger_situation(observation: Dictionary) -> bool:
	if int(observation.get("berries_carried", 0)) >= int(observation.get("max_berries_carried", 1)):
		return false
	return float(observation["hunger"]) <= float(observation["pickup_hunger_threshold"])

func classify(observation: Dictionary) -> String:
	if bool(observation.get("has_visible_ronce", false)):
		return SITUATION_RONCE_VISIBLE
	if bool(observation.get("has_memories", false)):
		return SITUATION_MEMOIRE
	return SITUATION_INCONNU

## Les actions valides dépendent aussi de l'observation : viser un souvenir n'a de sens
## que si l'agent en possède un.
func available_actions(situation: String, observation: Dictionary) -> Array:
	var actions: Array = []
	for action in ACTIONS_BY_SITUATION.get(situation, [ACTION_ERRANCE]):
		if action == ACTION_RONCE_MEMORISEE and not bool(observation.get("has_memories", false)):
			continue
		actions.append(action)
	if actions.is_empty():
		actions.append(ACTION_ERRANCE)
	return actions

func _select_action(situation: String, actions: Array) -> String:
	if actions.size() <= 1:
		last_explored = false
		return String(actions[0])
	if _rng.randf() < exploration_epsilon:
		last_explored = true
		return String(actions[_rng.randi_range(0, actions.size() - 1)])
	last_explored = false
	var best: String = String(actions[0])
	var best_score := get_score(situation, best)
	for i in range(1, actions.size()):
		var candidate: String = String(actions[i])
		var candidate_score := get_score(situation, candidate)
		if candidate_score > best_score:
			best = candidate
			best_score = candidate_score
	return best

func _record_pending(situation: String, action: String, observation: Dictionary) -> void:
	last_situation = situation
	last_action = action
	_pending = {
		"situation": situation,
		"action": action,
		"explored": last_explored,
		"hunger": float(observation["hunger"]),
		"elapsed_seconds": float(observation.get("elapsed_seconds", 0.0)),
	}

## Renvoie un dictionnaire vide quand l'action tenue n'impose pas de cible : le flux
## retombe alors sur le comportement de repli (social puis errance), identique à
## BaselineDecider.
func _build_targeted_action(action: String, observation: Dictionary) -> Dictionary:
	if action == ACTION_RONCE_VISIBLE:
		return {"goal": ACTION_RONCE_VISIBLE, "direction": observation["visible_ronce_direction"], "renew_wander": false}
	if action == ACTION_RONCE_MEMORISEE:
		return {"goal": ACTION_RONCE_MEMORISEE, "direction": observation["memory_direction"], "renew_wander": false}
	return {}

func _fallback_action(observation: Dictionary) -> Dictionary:
	if observation["social_goal"] != "":
		return {"goal": observation["social_goal"], "direction": observation["social_direction"], "renew_wander": false}
	return {
		"goal": ACTION_ERRANCE,
		"direction": observation["current_direction"],
		"renew_wander": observation["wander_timer"] - observation["delta"] <= 0.0,
	}
