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

var fixed_action_s1 := ACTION_RONCE_VISIBLE
var fixed_action_s2 := ACTION_RONCE_MEMORISEE
var fixed_action_s3 := ACTION_ERRANCE

func configure_fixed(action_s1: String, action_s2: String, action_s3: String, interval_seconds: float, name: String = "") -> void:
	configure(0.0, 0.0, interval_seconds, 0, name)
	fixed_action_s1 = action_s1
	fixed_action_s2 = action_s2
	fixed_action_s3 = action_s3

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
