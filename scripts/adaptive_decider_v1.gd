class_name AdaptiveDeciderV1
extends RefCounted

## BRAS GELÉ — copie de scripts/adaptive_decider.gd dans son état du 2026-08-30
## (roadmap_apprentissage_v2.md, Phase 0). Ne pas modifier : ce fichier est le « avant »
## du benchmark avant/après. Les Phases 2 à 4 modifient adaptive_decider.gd et
## l'observation construite par character.gd ; un ancien commit ne serait plus exécutable
## dans le moteur courant, d'où cette duplication assumée et temporaire. Supprimé à la
## clôture de la roadmap (après une éventuelle Phase 6).
##
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
## Phase 2 : à chaque reprise de décision en situation de faim, la cellule
## (situation, action) qui vient d'être tenue est créditée de la variation de faim
## observée sur sa fenêtre d'engagement, normalisée par REWARD_HUNGER_SCALE et bornée
## à [-1, 1], puis mise à jour en moyenne mobile (score += learning_rate * (reward -
## score)). La mort de faim ajoute une pénalité terminale unique sur la dernière cellule
## tenue. Trois événements sont journalisés : apprentissage_decision (à chaque nouvelle
## décision), apprentissage_maj (à chaque mise à jour de score), apprentissage_table
## (dump de la table en fin de vie).

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
# Échelle de normalisation de la variation de faim en récompense. À 5,0 : perdre une
# fenêtre d'engagement complète aux réglages par défaut (~1,2 de faim sur 2,0 s) vaut
# environ -0,24 ; une fenêtre où l'agent a mangé sature à +1,0. Valeur à régler en
# Phase 4 si la pente d'apprentissage plafonne ou oscille.
const REWARD_HUNGER_SCALE := 5.0
const TERMINAL_REWARD := -1.0

var learning_rate := 0.2
var exploration_epsilon := 0.2
var decision_interval_seconds := 2.0
var agent_name := ""

var last_situation := ""
var last_action := ""
var last_explored := false
var decisions_total := 0
var updates_total := 0

var _scores: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _pending: Dictionary = {}
var _engaged_situation := ""
var _engaged_action := ""
var _engagement_timer := 0.0
var _terminal_applied := false

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
		_apply_online_reward(float(observation["hunger"]), float(observation.get("elapsed_seconds", 0.0)))
		_engaged_situation = situation
		_engaged_action = _select_action(situation, actions)
		_engagement_timer = decision_interval_seconds
		decisions_total += 1
		_record_pending(situation, _engaged_action, observation)
		_log_decision(situation, _engaged_action)

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

## Crédite la cellule (situation, action) tenue jusqu'ici de la variation de faim
## observée sur sa fenêtre d'engagement. Sans décision précédente en attente, rien à
## faire (première décision de la vie).
func _apply_online_reward(hunger_now: float, elapsed_now: float) -> void:
	if _pending.is_empty():
		return
	var reward := clampf((hunger_now - float(_pending["hunger"])) / REWARD_HUNGER_SCALE, -1.0, 1.0)
	var window := elapsed_now - float(_pending.get("elapsed_seconds", elapsed_now))
	_commit_reward(String(_pending["situation"]), String(_pending["action"]), reward, window, false)

## Pénalité terminale : appliquée une seule fois, sur la dernière cellule tenue, quand
## l'agent meurt de faim. character.gd::_die() en est l'appelant.
func on_terminal_starvation() -> void:
	if _terminal_applied:
		return
	_terminal_applied = true
	if _pending.is_empty():
		return
	_commit_reward(String(_pending["situation"]), String(_pending["action"]), TERMINAL_REWARD, 0.0, true)

func _commit_reward(situation: String, action: String, reward: float, window_seconds: float, terminal: bool) -> void:
	var old_score := get_score(situation, action)
	var new_score := old_score + learning_rate * (reward - old_score)
	set_score(situation, action, new_score)
	updates_total += 1
	GameLogger.log_event_data("apprentissage_maj", "%s : %s/%s reward %.3f  score %.3f -> %.3f%s" % [agent_name, situation, action, reward, old_score, new_score, "  (terminal)" if terminal else ""], {
		"agent": agent_name,
		"situation": situation,
		"action": action,
		"reward": reward,
		"old_score": old_score,
		"new_score": new_score,
		"window_seconds": window_seconds,
		"terminal": terminal,
	})

func _log_decision(situation: String, action: String) -> void:
	GameLogger.log_event_data("apprentissage_decision", "%s : %s -> %s%s" % [agent_name, situation, action, "  (exploration)" if last_explored else ""], {
		"agent": agent_name,
		"situation": situation,
		"action": action,
		"explored": last_explored,
		"score": get_score(situation, action),
	})

## Dump complet de la table apprise, en fin de vie (mort de faim ou fin de simulation).
func log_table(reason: String) -> void:
	GameLogger.log_event_data("apprentissage_table", "%s : table apprise (%s) — %d décisions, %d mises à jour" % [agent_name, reason, decisions_total, updates_total], {
		"agent": agent_name,
		"reason": reason,
		"table": table_snapshot(),
		"decisions_total": decisions_total,
		"updates_total": updates_total,
	})

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
