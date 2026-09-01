class_name VariableRegistry
extends RefCounted

## Source de vérité des variables expérimentales disponibles dans le prototype.
## Chaque définition : identifiant (clé), libellé, description, portée, catégorie,
## type, bornes, valeur par défaut, caractère dynamique (change pendant un run sans
## intervention utilisateur) et modification live autorisée (slider UI existant).
const GAME_CONFIG: Dictionary = {
	"max_berries_carried": {"label": "Mûres max portées", "description": "Nombre maximal de mûres qu'un agent peut porter avant de devoir les consommer.", "scope": "globale", "category": "alimentation", "type": "int", "min": 1, "max": 20, "default": 3, "dynamic": false, "live_editable": true},
	"pickup_hunger_threshold": {"label": "Seuil cueillette (faim)", "description": "Niveau de faim en dessous duquel un agent cherche à cueillir des mûres.", "scope": "globale", "category": "alimentation", "type": "float", "min": 0.0, "max": 100.0, "default": 90.0, "dynamic": false, "live_editable": true},
	"eat_hunger_threshold": {"label": "Seuil consommation (faim)", "description": "Niveau de faim en dessous duquel un agent consomme une mûre portée.", "scope": "globale", "category": "alimentation", "type": "float", "min": 0.0, "max": 100.0, "default": 50.0, "dynamic": false, "live_editable": true},
	"full_life_berries": {"label": "Mûres pour vie complète", "description": "Nombre de mûres nécessaires pour restaurer la faim de 0 à 100.", "scope": "globale", "category": "alimentation", "type": "float", "min": 0.1, "max": 100.0, "default": 6.0, "dynamic": false, "live_editable": true},
	"ronce_count": {"label": "Nombre de ronces", "description": "Nombre de ronciers générés sur la map, répartis par quadrant.", "scope": "globale", "category": "environnement", "type": "int", "min": 0, "max": 500, "default": 24, "dynamic": false, "live_editable": true},
	"berries_per_ronce": {"label": "Mûres par ronce", "description": "Nombre de mûres portées par chaque roncier généré.", "scope": "globale", "category": "environnement", "type": "int", "min": 0, "max": 100, "default": 3, "dynamic": false, "live_editable": true},
	"light_energy": {"label": "Intensité lumineuse", "description": "Énergie de la lumière directionnelle de la scène.", "scope": "globale", "category": "rendu", "type": "float", "min": 0.0, "max": 20.0, "default": 3.0, "dynamic": false, "live_editable": true},
}

const CHARACTER: Dictionary = {
	"move_speed": {"label": "Vitesse de déplacement", "description": "Vitesse de déplacement horizontale de l'agent.", "scope": "individuelle", "category": "déplacement", "type": "float", "min": 0.0, "max": 20.0, "default": 2.5, "dynamic": false, "live_editable": true},
	"hunger": {"label": "Faim initiale", "description": "Niveau de faim de l'agent au démarrage (0 = mort, 100 = rassasié).", "scope": "individuelle", "category": "alimentation", "type": "float", "min": 0.0, "max": 100.0, "default": 100.0, "dynamic": true, "live_editable": false},
	"hunger_depletion_rate": {"label": "Taux de déplétion de la faim", "description": "Vitesse à laquelle la faim diminue au fil du temps.", "scope": "individuelle", "category": "alimentation", "type": "float", "min": 0.0, "max": 20.0, "default": 0.6, "dynamic": false, "live_editable": false},
	"aging_factor": {"label": "Facteur de vieillissement", "description": "Multiplicateur de la vitesse de vieillissement de l'agent.", "scope": "individuelle", "category": "vieillissement", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0, "dynamic": false, "live_editable": true},
	"feeding_capacity": {"label": "Capacité à se nourrir", "description": "Multiplicateur de la restauration de faim par mûre consommée.", "scope": "individuelle", "category": "alimentation", "type": "float", "min": 0.0, "max": 10.0, "default": 1.0, "dynamic": false, "live_editable": true},
	"memory_capacity": {"label": "Capacité de mémoire", "description": "Nombre maximal de ronciers mémorisés simultanément.", "scope": "individuelle", "category": "mémoire", "type": "int", "min": 0, "max": 100, "default": 5, "dynamic": false, "live_editable": true},
	"memory_decay_rate": {"label": "Taux de décroissance de la mémoire", "description": "Vitesse à laquelle un souvenir de roncier perd en force avant d'être oublié.", "scope": "individuelle", "category": "mémoire", "type": "float", "min": 0.0, "max": 10.0, "default": 0.15, "dynamic": false, "live_editable": false},
	"exploration_tendency": {"label": "Tendance à l'exploration", "description": "0,5 est neutre ; une valeur élevée raccourcit les phases d'errance et augmente la fréquence des changements de direction.", "scope": "individuelle", "category": "comportement", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "dynamic": false, "live_editable": false},
	"goal_persistence": {"label": "Persistance d'objectif", "description": "0,5 est neutre ; une valeur élevée prolonge localement l'errance dans la direction actuelle avant une réorientation.", "scope": "individuelle", "category": "comportement", "type": "float", "min": 0.0, "max": 1.0, "default": 0.5, "dynamic": false, "live_editable": false},
	"known_zone_preference": {"label": "Préférence zones connues", "description": "Attire l'errance vers le centre de la zone déjà visitée la plus proche. 0 n'applique aucun biais ; 1 applique le biais maximal.", "scope": "individuelle", "category": "comportement", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"curiosity": {"label": "Curiosité", "description": "Favorise localement, lors d'une réorientation, une direction candidate menant vers une zone encore inconnue.", "scope": "individuelle", "category": "comportement", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"vision_range": {"label": "Portée de vision", "description": "Distance à laquelle un agent perçoit une entité perceptible (ronciers, futurs types d'entités). 0 désactive la vision.", "scope": "individuelle", "category": "perception", "type": "float", "min": 0.0, "max": 250.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"vision_angle_degrees": {"label": "Angle de vision", "description": "Champ de vision angulaire, relatif à l'orientation visuelle de l'agent. 360 = omnidirectionnel.", "scope": "individuelle", "category": "perception", "type": "float", "min": 0.0, "max": 360.0, "default": 360.0, "dynamic": false, "live_editable": false},
	"vision_blocked_by_terrain": {"label": "Vision bloquée par le terrain", "description": "Si activé, une entité masquée par le terrain ou un obstacle n'est pas perçue même dans la portée et l'angle de vision.", "scope": "individuelle", "category": "perception", "type": "bool", "default": false, "dynamic": false, "live_editable": false},
	"social_radius": {"label": "Rayon social", "description": "Distance à laquelle un agent perçoit un autre agent.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 250.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"follow_probability": {"label": "Probabilité de suivi", "description": "Probabilité qu'un agent suive un autre agent perçu dans son rayon social.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"avoid_probability": {"label": "Probabilité d'évitement", "description": "Probabilité qu'un agent évite un autre agent perçu dans son rayon social.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"communication_probability": {"label": "Probabilité de communication", "description": "Probabilité qu'un agent partage une position de roncier mémorisée avec un autre agent rencontré qui ne la connaît pas encore.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"cooperation_probability": {"label": "Probabilité de coopération", "description": "Probabilité qu'un agent cède une mûre portée à un agent rencontré dont la faim est sous le seuil de consommation.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"aggression_probability": {"label": "Probabilité d'agressivité", "description": "Probabilité qu'un agent force un agent rencontré à s'éloigner, indépendamment du choix de ce dernier.", "scope": "individuelle", "category": "social", "type": "float", "min": 0.0, "max": 1.0, "default": 0.0, "dynamic": false, "live_editable": false},
	"decider_type": {"label": "Type de décideur", "description": "Système qui décide des actions de l'agent : automate déterministe, décideur adaptatif qui apprend pendant sa vie, décideur adaptatif gelé (bras 'avant' du benchmark, roadmap_apprentissage_v2), politique déterministe figée sur l'espace d'action courant (oracle Phase 1 / bras politique_fixe_*), LLM local via Ollama, ou LLM simulé sans appel réseau (test).", "scope": "individuelle", "category": "décision", "type": "enum", "options": ["automate", "adaptatif", "adaptatif_v1", "politique_fixe", "llm", "llm_mock"], "default": "automate", "dynamic": false, "live_editable": false},
	"fixed_policy_s1": {"label": "Politique fixe S1 (roncier visible)", "description": "Action tenue par le décideur politique_fixe quand un roncier avec mûres est visible : viser ce roncier, viser un roncier mémorisé, ou errer. Ignoré par les autres décideurs.", "scope": "individuelle", "category": "décision", "type": "enum", "options": ["ronce_visible", "ronce_memorisee", "errance"], "default": "ronce_visible", "dynamic": false, "live_editable": false},
	"fixed_policy_s2": {"label": "Politique fixe S2 (souvenir)", "description": "Action tenue par le décideur politique_fixe quand aucun roncier n'est visible mais qu'un souvenir de roncier est utilisable : viser ce souvenir ou errer. Ignoré par les autres décideurs.", "scope": "individuelle", "category": "décision", "type": "enum", "options": ["ronce_memorisee", "errance"], "default": "ronce_memorisee", "dynamic": false, "live_editable": false},
	"learning_rate": {"label": "Taux d'apprentissage", "description": "Pas de la moyenne mobile qui met à jour le score d'une action du décideur adaptatif. 0 fige la table apprise.", "scope": "individuelle", "category": "décision", "type": "float", "min": 0.0, "max": 1.0, "default": 0.2, "dynamic": false, "live_editable": false},
	"exploration_epsilon": {"label": "Taux d'exploration", "description": "Probabilité que le décideur adaptatif tire une action valide au hasard plutôt que celle au meilleur score. 0 rend la sélection purement gloutonne.", "scope": "individuelle", "category": "décision", "type": "float", "min": 0.0, "max": 1.0, "default": 0.2, "dynamic": false, "live_editable": false},
	"adaptive_decision_interval_seconds": {"label": "Intervalle de décision adaptatif", "description": "Durée simulée pendant laquelle le décideur adaptatif tient l'action choisie avant d'en retirer une nouvelle. Détermine aussi la fenêtre sur laquelle la récompense est mesurée.", "scope": "individuelle", "category": "décision", "type": "float", "min": 0.1, "max": 60.0, "default": 2.0, "dynamic": false, "live_editable": false},
	"llm_model": {"label": "Modèle LLM", "description": "Nom du modèle Ollama interrogé quand decider_type vaut 'llm'.", "scope": "individuelle", "category": "décision", "type": "string", "default": "gemma3:1b", "dynamic": false, "live_editable": false},
	"llm_decision_interval_seconds": {"label": "Intervalle de décision LLM", "description": "Durée simulée minimale entre deux appels au LLM ; l'action précédente est conservée entre-temps.", "scope": "individuelle", "category": "décision", "type": "float", "min": 0.5, "max": 60.0, "default": 3.0, "dynamic": false, "live_editable": false},
	"llm_timeout_seconds": {"label": "Timeout LLM", "description": "Délai maximal d'attente d'une réponse Ollama avant repli sur l'automate.", "scope": "individuelle", "category": "décision", "type": "float", "min": 0.5, "max": 60.0, "default": 8.0, "dynamic": false, "live_editable": false},
}

static func default_value(definition: Dictionary):
	if definition["type"] == "int":
		return int(definition["default"])
	if definition["type"] == "enum" or definition["type"] == "string":
		return String(definition["default"])
	if definition["type"] == "bool":
		return bool(definition["default"])
	return float(definition["default"])

static func validate_values(values: Dictionary, definitions: Dictionary, scope: String) -> PackedStringArray:
	var errors := PackedStringArray()
	for key_variant in values:
		var key := String(key_variant)
		if not definitions.has(key):
			errors.append("%s : variable inconnue '%s'" % [scope, key])
			continue
		var value = values[key_variant]
		var definition: Dictionary = definitions[key]
		var expected_type: String = definition["type"]
		if expected_type == "enum":
			var options: Array = definition.get("options", [])
			if typeof(value) != TYPE_STRING or not options.has(String(value)):
				errors.append("%s.%s : valeur '%s' hors énumération %s" % [scope, key, value, options])
			continue
		if expected_type == "string":
			if typeof(value) != TYPE_STRING:
				errors.append("%s.%s : type string attendu" % [scope, key])
			continue
		if expected_type == "bool":
			if typeof(value) != TYPE_BOOL:
				errors.append("%s.%s : type bool attendu" % [scope, key])
			continue
		var is_number := typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
		var valid_type := (expected_type == "int" and is_number and is_equal_approx(float(value), roundf(float(value)))) or (expected_type == "float" and is_number)
		if not valid_type:
			errors.append("%s.%s : type %s attendu" % [scope, key, expected_type])
			continue
		var numeric_value := float(value)
		if numeric_value < float(definition["min"]) or numeric_value > float(definition["max"]):
			errors.append("%s.%s : valeur %s hors bornes [%s, %s]" % [scope, key, value, definition["min"], definition["max"]])
	return errors

static func validate_fixed_values(values: Dictionary, definitions: Dictionary, scope: String) -> PackedStringArray:
	var errors := validate_values(values, definitions, scope)
	for key_variant in values:
		var key := String(key_variant)
		if definitions.has(key) and bool(definitions[key].get("dynamic", false)):
			errors.append("%s.%s : état dynamique attendu dans agents.initial_state" % [scope, key])
	return errors

static func validate_initial_state_values(values: Dictionary, definitions: Dictionary, scope: String) -> PackedStringArray:
	var errors := validate_values(values, definitions, scope)
	for key_variant in values:
		var key := String(key_variant)
		if definitions.has(key) and not bool(definitions[key].get("dynamic", false)):
			errors.append("%s.%s : seule une variable dynamique peut appartenir à l'état initial" % [scope, key])
	return errors
