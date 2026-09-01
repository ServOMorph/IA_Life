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
## Phase 2 (roadmap_apprentissage_v2) : récompense événementielle et amorçage par
## différence temporelle. À chaque reprise de décision en situation de faim, la cellule
## (situation, action) qui vient d'être tenue est créditée d'une récompense immédiate
## r = PICK_REWARD * (cueillettes survenues dans la fenêtre) - survival_cost_rate * durée
## de la fenêtre, bornée à [-1, 1]. La cible d'apprentissage amorce sur l'état suivant :
## target = r + td_discount_gamma * max Q(s', .) ; la table est mise à jour par
## score += learning_rate * (target - score). La mort de faim ajoute une pénalité
## terminale unique (r = TERMINAL_REWARD, sans amorçage) sur la dernière cellule tenue.
## Trois événements sont journalisés : apprentissage_decision (à chaque nouvelle
## décision, avec le nombre d'actions valides offertes), apprentissage_maj (à chaque
## mise à jour de score), apprentissage_table (dump de la table en fin de vie, tagué
## par TABLE_SCHEMA_VERSION).
##
## Phase 3 (roadmap_apprentissage_v2) : l'espace d'action est élargi là où les décisions
## se prennent. S3 (inconnu) passe de 1 à 5 actions — errance, cap_maintenu, demi_tour,
## zone_inconnue, zone_connue ; S2 gagne souvenir_ancien. La discrétisation des
## situations est inchangée. Les directions candidates (zone inconnue/connue, souvenir
## ancien, cap courant) sont fournies par character.gd dans l'observation.

const SITUATION_RONCE_VISIBLE := "S1_ronce_visible"
const SITUATION_MEMOIRE := "S2_memoire"
const SITUATION_INCONNU := "S3_inconnu"

const ACTION_RONCE_VISIBLE := "ronce_visible"
const ACTION_RONCE_MEMORISEE := "ronce_memorisee"
const ACTION_ERRANCE := "errance"
# Phase 3 (roadmap_apprentissage_v2) : actions de navigation explicites, ajoutées là où
# les décisions se prennent réellement (S3, 63 % des décisions de faim, sans choix
# auparavant) et en S2. Elles transforment les modulations diffuses de l'errance
# (curiosity, known_zone_preference) en choix discrets scorés.
const ACTION_CAP_MAINTENU := "cap_maintenu"
const ACTION_DEMI_TOUR := "demi_tour"
const ACTION_ZONE_INCONNUE := "zone_inconnue"
const ACTION_ZONE_CONNUE := "zone_connue"
const ACTION_SOUVENIR_ANCIEN := "souvenir_ancien"

const SITUATIONS := [SITUATION_RONCE_VISIBLE, SITUATION_MEMOIRE, SITUATION_INCONNU]
const ACTIONS_BY_SITUATION := {
	SITUATION_RONCE_VISIBLE: [ACTION_RONCE_VISIBLE, ACTION_RONCE_MEMORISEE, ACTION_ERRANCE],
	SITUATION_MEMOIRE: [ACTION_RONCE_MEMORISEE, ACTION_SOUVENIR_ANCIEN, ACTION_ERRANCE],
	SITUATION_INCONNU: [ACTION_ERRANCE, ACTION_CAP_MAINTENU, ACTION_DEMI_TOUR, ACTION_ZONE_INCONNUE, ACTION_ZONE_CONNUE],
}
const INITIAL_SCORE := 0.0
# Récompense d'une cueillette survenue dans la fenêtre d'engagement, conséquence directe
# de la décision d'approche. Le coût de survie (survival_cost_rate) et le facteur
# d'actualisation (td_discount_gamma) sont réglables par agent, à balayer en Phase 2.
const PICK_REWARD := 1.0
const TERMINAL_REWARD := -1.0
# Tag du format de la table dumpée (apprentissage_table). Toute phase qui change la
# sémantique des scores incrémente ce tag pour qu'une table produite ici ne soit pas
# rechargée silencieusement par un run à sémantique différente (Phase 4).
const TABLE_SCHEMA_VERSION := "phase3-actions-1"

var learning_rate := 0.2
var exploration_epsilon := 0.2
var decision_interval_seconds := 2.0
var survival_cost_rate := 0.05
var td_discount_gamma := 0.9
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
# Cap de l'agent au moment de la décision, figé pour la durée de l'engagement. Les
# actions de navigation cap_maintenu et demi_tour s'y réfèrent : sans ça, demi_tour
# recalculé à chaque frame à partir du cap courant (qu'il vient d'inverser) oscille.
var _engaged_reference_direction := Vector3.ZERO
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
		_flush_pending(observation)
		_release_engagement()
		return _fallback_action(observation)

	var situation := classify(observation)
	var actions := available_actions(situation, observation)
	_engagement_timer -= float(observation.get("delta", 0.0))
	if _must_decide(situation, actions):
		_apply_online_reward(float(observation.get("berries_picked_total", 0.0)), float(observation.get("elapsed_seconds", 0.0)), situation, actions)
		_engaged_situation = situation
		_engaged_action = _select_action(situation, actions)
		_engagement_timer = decision_interval_seconds
		_engaged_reference_direction = Vector3(observation.get("current_direction", Vector3.ZERO))
		decisions_total += 1
		_record_pending(situation, _engaged_action, observation)
		_log_decision(situation, _engaged_action, actions.size())

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
	_engaged_reference_direction = Vector3.ZERO

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
## que si l'agent en possède un, viser une zone connue ou inconnue que si une direction
## exploitable existe. cap_maintenu, demi_tour et errance sont toujours valides : S3
## offre donc toujours au moins trois actions.
func available_actions(situation: String, observation: Dictionary) -> Array:
	var actions: Array = []
	for action in ACTIONS_BY_SITUATION.get(situation, [ACTION_ERRANCE]):
		if (action == ACTION_RONCE_MEMORISEE or action == ACTION_SOUVENIR_ANCIEN) and not bool(observation.get("has_memories", false)):
			continue
		if action == ACTION_ZONE_INCONNUE and Vector3(observation.get("unknown_zone_direction", Vector3.ZERO)).is_zero_approx():
			continue
		if action == ACTION_ZONE_CONNUE and Vector3(observation.get("known_zone_direction", Vector3.ZERO)).is_zero_approx():
			continue
		if action == ACTION_DEMI_TOUR and Vector3(observation.get("current_direction", Vector3.ZERO)).is_zero_approx():
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
		"berries_picked_total": float(observation.get("berries_picked_total", 0.0)),
		"elapsed_seconds": float(observation.get("elapsed_seconds", 0.0)),
	}

## Crédite la cellule (situation, action) tenue jusqu'ici. Récompense immédiate
## événementielle : PICK_REWARD par cueillette survenue dans la fenêtre d'engagement,
## moins survival_cost_rate * durée de la fenêtre, bornée à [-1, 1]. La cible
## d'apprentissage amorce sur l'état suivant : target = r + td_discount_gamma *
## max Q(s', .). Sans décision précédente en attente, rien à faire (première décision
## de la vie).
func _apply_online_reward(picked_now: float, elapsed_now: float, next_situation: String, next_actions: Array) -> void:
	if _pending.is_empty():
		return
	var window := elapsed_now - float(_pending.get("elapsed_seconds", elapsed_now))
	var reward := _window_reward(picked_now, window)
	var bootstrap := _max_score(next_situation, next_actions)
	_commit_reward(String(_pending["situation"]), String(_pending["action"]), reward, bootstrap, window, false)

## Récompense immédiate d'une fenêtre d'engagement : PICK_REWARD par cueillette survenue
## depuis l'ouverture de la fenêtre, moins survival_cost_rate * durée, bornée à [-1, 1].
func _window_reward(picked_now: float, window: float) -> float:
	var picks := picked_now - float(_pending.get("berries_picked_total", picked_now))
	return clampf(picks * PICK_REWARD - survival_cost_rate * window, -1.0, 1.0)

## Quand l'agent quitte la situation de faim exploitable (inventaire plein, faim
## remontée), la fenêtre d'engagement en cours est clôturée sur ses conséquences
## réelles — cueillettes effectuées, coût de survie écoulé — sans amorçage (l'état
## suivant n'est pas une décision de faim). Sans cette clôture, la fenêtre resterait
## en attente et serait créditée bien plus tard, sur une durée gonflée et sans les
## cueillettes qu'elle a produites : la meilleure action serait pénalisée pour avoir
## réussi.
func _flush_pending(observation: Dictionary) -> void:
	if _pending.is_empty():
		return
	var window := float(observation.get("elapsed_seconds", 0.0)) - float(_pending.get("elapsed_seconds", 0.0))
	var reward := _window_reward(float(observation.get("berries_picked_total", 0.0)), window)
	_commit_reward(String(_pending["situation"]), String(_pending["action"]), reward, 0.0, window, false)
	_pending = {}

## Meilleur score de l'état suivant sur ses actions valides — terme d'amorçage TD.
## Un état sans action (jamais en pratique : errance est toujours disponible) ne
## propage aucune valeur.
func _max_score(situation: String, actions: Array) -> float:
	if actions.is_empty():
		return 0.0
	var best := get_score(situation, String(actions[0]))
	for i in range(1, actions.size()):
		best = maxf(best, get_score(situation, String(actions[i])))
	return best

## Pénalité terminale : appliquée une seule fois, sur la dernière cellule tenue, quand
## l'agent meurt de faim. character.gd::_die() en est l'appelant. Aucun amorçage : un
## état terminal n'a pas de suite.
func on_terminal_starvation() -> void:
	if _terminal_applied:
		return
	_terminal_applied = true
	if _pending.is_empty():
		return
	_commit_reward(String(_pending["situation"]), String(_pending["action"]), TERMINAL_REWARD, 0.0, 0.0, true)

func _commit_reward(situation: String, action: String, reward: float, bootstrap: float, window_seconds: float, terminal: bool) -> void:
	var old_score := get_score(situation, action)
	var target := reward if terminal else reward + td_discount_gamma * bootstrap
	var new_score := old_score + learning_rate * (target - old_score)
	set_score(situation, action, new_score)
	updates_total += 1
	GameLogger.log_event_data("apprentissage_maj", "%s : %s/%s reward %.3f  cible %.3f  score %.3f -> %.3f%s" % [agent_name, situation, action, reward, target, old_score, new_score, "  (terminal)" if terminal else ""], {
		"agent": agent_name,
		"situation": situation,
		"action": action,
		"reward": reward,
		"bootstrap": bootstrap,
		"gamma": td_discount_gamma,
		"target": target,
		"old_score": old_score,
		"new_score": new_score,
		"window_seconds": window_seconds,
		"terminal": terminal,
	})

func _log_decision(situation: String, action: String, available_count: int) -> void:
	GameLogger.log_event_data("apprentissage_decision", "%s : %s -> %s%s" % [agent_name, situation, action, "  (exploration)" if last_explored else ""], {
		"agent": agent_name,
		"situation": situation,
		"action": action,
		"explored": last_explored,
		"score": get_score(situation, action),
		"available_count": available_count,
	})

## Dump complet de la table apprise, en fin de vie (mort de faim ou fin de simulation).
func log_table(reason: String) -> void:
	GameLogger.log_event_data("apprentissage_table", "%s : table apprise (%s, schéma %s) — %d décisions, %d mises à jour" % [agent_name, reason, TABLE_SCHEMA_VERSION, decisions_total, updates_total], {
		"agent": agent_name,
		"reason": reason,
		"schema_version": TABLE_SCHEMA_VERSION,
		"table": table_snapshot(),
		"decisions_total": decisions_total,
		"updates_total": updates_total,
	})

## Renvoie un dictionnaire vide quand l'action tenue n'impose pas de cible : le flux
## retombe alors sur le comportement de repli (social puis errance), identique à
## BaselineDecider. errance est le seul cas où ce repli est le comportement voulu ;
## les autres actions de navigation (Phase 3) portent une direction explicite et ne
## retombent sur le repli que si leur direction est devenue indisponible.
func _build_targeted_action(action: String, observation: Dictionary) -> Dictionary:
	if action == ACTION_RONCE_VISIBLE:
		return {"goal": ACTION_RONCE_VISIBLE, "direction": observation["visible_ronce_direction"], "renew_wander": false}
	if action == ACTION_RONCE_MEMORISEE:
		return {"goal": ACTION_RONCE_MEMORISEE, "direction": observation["memory_direction"], "renew_wander": false}
	if action == ACTION_SOUVENIR_ANCIEN:
		return _directed_action_or_empty(action, Vector3(observation.get("old_memory_direction", Vector3.ZERO)))
	if action == ACTION_ZONE_INCONNUE:
		return _directed_action_or_empty(action, Vector3(observation.get("unknown_zone_direction", Vector3.ZERO)))
	if action == ACTION_ZONE_CONNUE:
		return _directed_action_or_empty(action, Vector3(observation.get("known_zone_direction", Vector3.ZERO)))
	if action == ACTION_CAP_MAINTENU:
		var kept := _engaged_reference_direction if not _engaged_reference_direction.is_zero_approx() else Vector3(observation.get("current_direction", Vector3.ZERO))
		return _directed_action_or_empty(action, kept)
	if action == ACTION_DEMI_TOUR:
		var base := _engaged_reference_direction if not _engaged_reference_direction.is_zero_approx() else Vector3(observation.get("current_direction", Vector3.ZERO))
		return _directed_action_or_empty(action, -base)
	return {}

func _directed_action_or_empty(goal: String, direction: Vector3) -> Dictionary:
	if direction.is_zero_approx():
		return {}
	return {"goal": goal, "direction": direction.normalized(), "renew_wander": false}

func _fallback_action(observation: Dictionary) -> Dictionary:
	if observation["social_goal"] != "":
		return {"goal": observation["social_goal"], "direction": observation["social_direction"], "renew_wander": false}
	return {
		"goal": ACTION_ERRANCE,
		"direction": observation["current_direction"],
		"renew_wander": observation["wander_timer"] - observation["delta"] <= 0.0,
	}
