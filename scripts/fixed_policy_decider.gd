class_name FixedPolicyDecider
extends AdaptiveDecider

## Politique déterministe figée sur l'espace d'action courant. Sert d'oracle en Phase 1
## de roadmap_apprentissage_v2 (énumération des politiques fixes) et de socle aux bras
## politique_fixe_max / politique_fixe_max_v1 du benchmark.
##
## Réutilise toute la machinerie de AdaptiveDecider (classification des situations,
## fenêtre d'engagement, construction de l'action ciblée, repli social puis errance) et
## ne remplace que deux choses : la sélection ε-greedy devient un choix fixe par
## situation, et toute mise à jour de score est neutralisée. La table reste à
## INITIAL_SCORE, aucun événement apprentissage_maj / apprentissage_table n'est émis, le
## comportement est strictement reproductible à seed fixe.
##
## Depuis la Phase 3 de roadmap_apprentissage_v2, S3_inconnu offre 5 actions (errance,
## cap_maintenu, demi_tour, zone_inconnue, zone_connue) et S2_memoire 3 : le choix de
## politique porte sur les trois situations (fixed_action_s1/s2/s3).
## Quand l'action désirée n'est pas applicable dans l'observation courante (viser un
## souvenir sans souvenir utilisable, viser une zone sans direction exploitable), repli
## déterministe sur errance.
##
## Phase 2 (roadmap_environnement_apprenable_v3) : fixed_policy_danger ajoute une
## surcouche de réponse au danger, appliquée après la politique alimentaire ci-dessus et
## sans y toucher. Hors danger physiquement subi ou visible, tous les bras exécutent la
## même politique alimentaire — c'est cette isolation qui permet d'attribuer un écart de
## résultat au danger plutôt qu'à un autre réglage. `ignorer` laisse la politique
## alimentaire inchangée ; `eviter` et `viser` remplacent l'action retenue par une
## direction stable (character.gd::_danger_response_direction), sans consommer d'aléa.
##
## Phase 3 (roadmap_environnement_apprenable_v3) : `aleatoire` tire eviter/viser à parts
## égales, un choix tenu pendant decision_interval_seconds de temps simulé puis retiré —
## même fenêtre de tenue que l'engagement de AdaptiveDecider (`_engagement_timer`), sans
## quoi decide() étant appelé à chaque frame physique (character.gd::_physics_process), un
## nouveau tirage à chaque frame ferait osciller la direction ~60 fois/seconde : la moyenne
## temporelle s'annule et le déplacement net ne diffère plus d'un évitement quasi pur (bug
## constaté à la calibration Phase 3 : le bras aleatoire reproduisait exactement les
## statistiques du bras eviter, exposition et coût de danger nuls sur les 96 runs). Le RNG
## est hérité (`_rng`, seedé depuis `decider_seed + hash(display_name)`, cf.
## character.gd::_build_decider — reproductible à seed d'expérience fixe, distinct entre
## agents et entre seeds). Sert de plancher sans réponse structurée au danger dans le bras
## `aleatoire` du benchmark de calibration.

const DANGER_IGNORER := "ignorer"
const DANGER_EVITER := "eviter"
const DANGER_VISER := "viser"
const DANGER_ALEATOIRE := "aleatoire"

var fixed_action_s1 := ACTION_RONCE_VISIBLE
var fixed_action_s2 := ACTION_RONCE_MEMORISEE
var fixed_action_s3 := ACTION_ERRANCE
var fixed_policy_danger := DANGER_IGNORER
var danger_navigation_mode := "rectiligne"
var _detour = preload("res://scripts/danger_detour.gd").new()

var _danger_aleatoire_timer := 0.0
var _danger_aleatoire_choice := DANGER_EVITER

func configure_fixed(action_s1: String, action_s2: String, action_s3: String, danger_action: String, interval_seconds: float, name: String = "", rng_seed: int = 0) -> void:
	configure(0.0, 0.0, interval_seconds, rng_seed, name)
	fixed_action_s1 = action_s1
	fixed_action_s2 = action_s2
	fixed_action_s3 = action_s3
	fixed_policy_danger = danger_action

func decide(observation: Dictionary) -> Dictionary:
	var action: Dictionary = super.decide(observation)
	if fixed_policy_danger == DANGER_IGNORER or bool(observation.get("manual_control", false)):
		_detour.reset()
		return action
	var toward_danger := Vector3(observation.get("danger_response_direction", Vector3.ZERO))
	var sensed_center: bool = danger_navigation_mode == "contournement" and not (observation.get("navigation_dangers", []) as Array).is_empty()
	if toward_danger.is_zero_approx() and _detour.target.is_empty() and not sensed_center:
		return action
	var resolved_policy := fixed_policy_danger
	if resolved_policy == DANGER_ALEATOIRE:
		_danger_aleatoire_timer -= float(observation.get("delta", 0.0))
		if _danger_aleatoire_timer <= 0.0:
			_danger_aleatoire_choice = DANGER_VISER if _rng.randf() < 0.5 else DANGER_EVITER
			_danger_aleatoire_timer = decision_interval_seconds
		resolved_policy = _danger_aleatoire_choice
	if danger_navigation_mode == "contournement":
		if resolved_policy == DANGER_EVITER and _is_hunger_situation(observation):
			var previous_phase: String = _detour.phase
			var direction: Vector3 = _detour.steer(
				Vector3(observation.get("position", Vector3.ZERO)),
				observation.get("navigation_targets", {}).get(action["goal"], {}),
				observation.get("navigation_dangers", []), float(observation.get("delta", 0.0)),
				observation.get("invalid_target_ids", []))
			if previous_phase != _detour.phase or _detour.reason != "":
				var target_position: Vector3 = _detour.target.get("position", Vector3.ZERO)
				var obstacle_position: Vector3 = _detour.obstacle.get("position", Vector3.ZERO)
				GameLogger.log_event_data("danger_navigation", "%s : %s" % [agent_name, _detour.phase], {
					"agent": agent_name, "phase": _detour.phase, "reason": _detour.reason,
					"target_id": _detour.target.get("id", ""), "side": _detour.side,
					"target_position": [target_position.x, target_position.y, target_position.z],
					"obstacle_position": [obstacle_position.x, obstacle_position.y, obstacle_position.z],
					"obstacle_radius": _detour.obstacle.get("radius", 0.0),
				})
			if not direction.is_zero_approx():
				return {"goal": "danger_%s" % _detour.phase, "direction": direction, "renew_wander": false}
			# Sans cible alimentaire, le repli historique permet de sortir d'une zone subie.
			if not bool(observation.get("in_danger", false)):
				return action
		else:
			_detour.reset()
	var oriented := toward_danger if resolved_policy == DANGER_VISER else -toward_danger
	return {"goal": "danger_%s" % resolved_policy, "direction": oriented.normalized(), "renew_wander": false}

func _select_action(situation: String, actions: Array) -> String:
	last_explored = false
	var desired := ""
	if situation == SITUATION_RONCE_VISIBLE:
		desired = fixed_action_s1
	elif situation == SITUATION_MEMOIRE:
		desired = fixed_action_s2
	elif situation == SITUATION_INCONNU:
		desired = fixed_action_s3
	if desired != "" and actions.has(desired):
		return desired
	return ACTION_ERRANCE

func _apply_online_reward(_picked_now: float, _elapsed_now: float, _next_situation: String, _next_actions: Array) -> void:
	pass

func _flush_pending(_observation: Dictionary) -> void:
	pass

func on_terminal_starvation() -> void:
	pass

func _commit_reward(_situation: String, _action: String, _reward: float, _bootstrap: float, _window_seconds: float, _terminal: bool) -> void:
	pass

func log_table(_reason: String) -> void:
	pass
