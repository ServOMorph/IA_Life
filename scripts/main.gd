extends Node3D

const MAP_SIZE := 160.0
const WALL_HEIGHT := 3.0
const WALL_THICKNESS := 1.0
const HEADLESS_ENV_VAR := "IA_LIFE_HEADLESS_CONFIG"
const PROJECT_REVISION_ENV_VAR := "IA_LIFE_PROJECT_REVISION"
const DEV_MODE_ENV_VAR := "IA_LIFE_DEV_MODE"
const RL_MODE_ENV_VAR := "IA_LIFE_RL_MODE"
const TERRAIN_RESOLUTION := 80
const TERRAIN_AMPLITUDE := 5.0
const TERRAIN_NOISE_FREQUENCY := 0.045
const DEFAULT_EXPERIMENT_SEED := 1337
const TERRAIN_FLAT_MARGIN := 12.0
const VALLEY_RADIUS := 20.0
const VALLEY_DEPTH := 3.5
const CENTER_FLAT_RADIUS := 45.0
const SPAWN_FLAT_RADIUS := 20.0
const SPAWN_POINTS := [Vector2(-40, -40), Vector2(40, -40), Vector2(-40, 40), Vector2(40, 40)]
const DEV_INTERACTION_RADIUS := 2.4

var _character_defaults: Dictionary = {}
var _character_overrides: Dictionary = {}
var _character_initial_state_defaults: Dictionary = {}
var _character_initial_state_overrides: Dictionary = {}
var _experiment_seed: int = DEFAULT_EXPERIMENT_SEED
var _normalized_experiment_config: Dictionary = {}
var _headless_run: bool = false
var _run_finished: bool = false
var _scheduled_events: Array = []
var _executed_events: Array = []
var _next_event_index: int = 0
var _simulation_clock: float = 0.0
var _quit_on_all_dead: bool = false
var _max_simulation_seconds: float = 0.0
var _characters: Array = []
var _terrain_noise: FastNoiseLite
var _screenshot_path: String = ""
var _screenshot_delay: float = 0.0
var _screenshot_clock: float = 0.0
var _dev_mode: bool = false
var _ronces: Array = []
var _dev_frozen_scale: float = -1.0
var _dev_step_frames: int = 0
var _ui: CanvasLayer
var _camera: Camera3D
var _test_character: CharacterBody3D = null
var _test_control_active: bool = false
var _rl_mode := false
var _rl_bridge: RLBridge
var _rl_agent: CharacterBody3D
var _rl_spawn := Vector3.ZERO
var _rl_simulation_clock := 0.0
var _rl_steps := 0
var _rl_max_steps := 40
var _rl_waiting := true

func _ready() -> void:
	_dev_mode = OS.get_environment(DEV_MODE_ENV_VAR) != ""
	_load_headless_overrides()
	seed(_experiment_seed)
	_init_terrain_noise()
	_build_environment()
	var light := _build_light()
	_build_floor()
	_build_walls()
	_build_decor()
	var camera := _build_camera()
	_camera = camera
	var characters := [
		_spawn_character(-40, -40, Color(0.8, 0.2, 0.2), "Rouge", "top_left"),
		_spawn_character(40, -40, Color(0.2, 0.4, 0.8), "Bleu", "top_right"),
		_spawn_character(-40, 40, Color(0.2, 0.7, 0.3), "Vert", "bottom_left"),
		_spawn_character(40, 40, Color(0.9, 0.7, 0.1), "Jaune", "bottom_right"),
	]
	_spawn_ronces()
	_build_ui(characters, camera, light)
	for c in characters:
		_characters.append(c.node)
	_setup_rl_mode(characters)

	if _dev_mode:
		_test_character = _spawn_test_character()
		_characters.append(_test_character)
		_ui.set_test_character(_test_character)
		_spawn_dev_spawn_ronces()
		GameLogger.log_event("dev", "Mode dev activé (IA_LIFE_DEV_MODE) — Espace: geler/reprendre, N: avancer d'une frame, H: forcer faim basse (déclenche repas), G: forcer faim haute (déclenche cueillette), E: ramasser une mûre proche, K: tuer le personnage de test (teste l'animation Death), F1-F4: téléporter le personnage au centre de la map (caméra suit), Shift+F1-F4: téléporter le personnage au contact de la ronce la plus proche (caméra suit), F5: activer/désactiver le contrôle du personnage de test, T: checklist de tests")

func _physics_process(_delta: float) -> void:
	if _headless_run and not _run_finished:
		var scaled_delta := _delta * GameSpeed.time_scale
		_simulation_clock += scaled_delta
		for character in _characters:
			if is_instance_valid(character):
				character.simulation_elapsed_seconds = _simulation_clock
		_process_scheduled_events()
		if _max_simulation_seconds > 0.0 and _simulation_clock + 0.000001 >= _max_simulation_seconds:
			GameLogger.log_event("headless", "Durée simulée atteinte (%.2fs) — arrêt automatique" % _max_simulation_seconds)
			_finish_headless_run("simulation_duration_reached")
			return
	if _dev_frozen_scale >= 0.0:
		if _dev_step_frames > 0:
			GameSpeed.time_scale = _dev_frozen_scale
			_dev_step_frames -= 1
		else:
			GameSpeed.time_scale = 0.0
	if _test_control_active and _test_character != null and not _test_character.is_dead:
		_update_test_character_movement()

func _update_test_character_movement() -> void:
	var forward: Vector3 = -_camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD

	var right: Vector3 = _camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.001 else Vector3.RIGHT

	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_Z):
		input_dir += forward
	if Input.is_key_pressed(KEY_S):
		input_dir -= forward
	if Input.is_key_pressed(KEY_Q):
		input_dir -= right
	if Input.is_key_pressed(KEY_D):
		input_dir += right
	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
	_test_character.set_manual_direction(input_dir)


func _dev_test_character_action() -> void:
	if _test_character == null:
		return
	var nearest_ronce: Area3D = null
	var nearest_distance := INF
	for ronce in _ronces:
		if not is_instance_valid(ronce):
			continue
		var distance := _test_character.global_position.distance_to(ronce.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_ronce = ronce
	if nearest_ronce == null or nearest_distance > DEV_INTERACTION_RADIUS:
		GameLogger.log_event("dev", "E : aucune ronce à portée (approchez-vous à moins de %.1f m)" % DEV_INTERACTION_RADIUS)
		return
	if _test_character.try_pick_berry_from_ronce(nearest_ronce, true):
		GameLogger.log_event("dev", "E : mûre ramassée manuellement")
		return
	if _test_character.berries_carried >= GameConfig.max_berries_carried:
		GameLogger.log_event("dev", "E : inventaire de mûres plein")
	else:
		GameLogger.log_event("dev", "E : le roncier ne contient plus de mûres")

func _dev_toggle_test_control() -> void:
	if _test_character == null:
		return
	_test_control_active = not _test_control_active
	_test_character.set("manual_control", _test_control_active)
	if _test_control_active:
		_camera.start_orbit(_test_character)
		GameLogger.log_event("dev", "Contrôle du personnage de test activé")
	else:
		_test_character.set_manual_direction(Vector3.ZERO)
		_camera.stop_orbit()
		GameLogger.log_event("dev", "Contrôle du personnage de test désactivé (comportement autonome repris)")
	_ui.set_test_control_active(_test_control_active)

func _spawn_test_character() -> CharacterBody3D:
	var info := _spawn_character(0.0, 0.0, Color(0.15, 0.15, 0.18), "Test", "", true)
	var node: CharacterBody3D = info.node
	node.set("manual_control", true)
	node.set("immortal", true)
	return node

func _unhandled_key_input(event: InputEvent) -> void:
	if not _dev_mode:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.shift_pressed and event.keycode in [KEY_F1, KEY_F2, KEY_F3, KEY_F4]:
		var shift_index := [KEY_F1, KEY_F2, KEY_F3, KEY_F4].find(event.keycode)
		_dev_teleport_to_nearest_ronce(shift_index)
		return
	match event.keycode:
		KEY_SPACE:
			_dev_toggle_freeze()
		KEY_N:
			_dev_step_frame()
		KEY_H:
			_dev_force_hunger_all(40.0)
		KEY_G:
			_dev_force_hunger_all(95.0)
		KEY_E:
			_dev_test_character_action()
		KEY_K:
			_dev_kill_test_character()
		KEY_F1:
			_dev_teleport_to_ronce(0)
		KEY_F2:
			_dev_teleport_to_ronce(1)
		KEY_F3:
			_dev_teleport_to_ronce(2)
		KEY_F4:
			_dev_teleport_to_ronce(3)
		KEY_T:
			_ui.toggle_dev_checklist()
		KEY_F5:
			_dev_toggle_test_control()

func _dev_toggle_freeze() -> void:
	if _dev_frozen_scale < 0.0:
		_dev_frozen_scale = GameSpeed.time_scale
		GameLogger.log_event("dev", "Simulation gelée (vitesse sauvegardée: %.1f)" % _dev_frozen_scale)
		_ui.set_dev_frozen(true)
	else:
		GameSpeed.time_scale = _dev_frozen_scale
		GameLogger.log_event("dev", "Simulation reprise (vitesse: %.1f)" % GameSpeed.time_scale)
		_dev_frozen_scale = -1.0
		_ui.set_dev_frozen(false)

func _dev_step_frame() -> void:
	if _dev_frozen_scale < 0.0:
		return
	_dev_step_frames = 1
	GameLogger.log_event("dev", "Avance d'une frame (simulation gelée)")

func _dev_kill_test_character() -> void:
	if _test_character == null:
		return
	_test_character.kill()
	GameLogger.log_event("dev", "Personnage de test tué manuellement (K)")

func _dev_force_hunger_all(value: float) -> void:
	for c in _characters:
		if not c.is_dead:
			c.hunger = value
	GameLogger.log_event("dev", "Faim forcée à %.0f pour tous les personnages vivants" % value)

func _dev_teleport_to_ronce(index: int) -> void:
	if index >= _characters.size():
		return
	var character = _characters[index]
	if character.is_dead:
		return
	character.position = Vector3(0.0, _terrain_height(0.0, 0.0), 0.0)
	_camera.follow(character)
	GameLogger.log_event("dev", "%s téléporté au centre de la map (caméra en suivi)" % character.display_name)

func _dev_teleport_to_nearest_ronce(index: int) -> void:
	if index >= _characters.size():
		return
	var character = _characters[index]
	if character.is_dead or _ronces.is_empty():
		return
	var nearest = null
	var nearest_dist := INF
	for r in _ronces:
		if not is_instance_valid(r):
			continue
		var d: float = character.position.distance_squared_to(r.position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = r
	if nearest == null:
		return
	character.position = Vector3(nearest.position.x, character.position.y, nearest.position.z)
	_camera.follow(character)
	GameLogger.log_event("dev", "%s téléporté au contact d'une ronce (caméra en suivi)" % character.display_name)

func _process(delta: float) -> void:
	_process_rl(delta)
	if _screenshot_path != "":
		_screenshot_clock += delta
		if _screenshot_clock >= _screenshot_delay:
			_take_screenshot()
			return
	if _quit_on_all_dead and _characters.size() > 0:
		var all_dead := true
		for c in _characters:
			if not c.get("is_dead"):
				all_dead = false
				break
		if all_dead:
			GameLogger.log_event("headless", "Tous les personnages sont morts — arrêt automatique")
			_finish_headless_run("all_agents_dead")
			return

func _load_headless_overrides() -> void:
	var path := OS.get_environment(HEADLESS_ENV_VAR)
	if path == "":
		return
	if not FileAccess.file_exists(path):
		_fail_headless_config("Fichier de config introuvable: %s" % path)
		return

	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		_fail_headless_config("Config JSON invalide dans %s" % path)
		return

	var experiment := ExperimentConfig.from_raw(parsed)
	if not experiment.is_valid():
		_fail_headless_config("Configuration refusée : %s" % "; ".join(experiment.errors))
		return
	var normalized := experiment.normalized
	normalized["runtime"] = {
		"project_revision": OS.get_environment(PROJECT_REVISION_ENV_VAR),
	}
	_experiment_seed = int(normalized["seed"])
	var environment: Dictionary = normalized["environment"]
	var agents: Dictionary = normalized["agents"]
	var simulation: Dictionary = normalized["simulation"]
	GameConfig.apply_overrides(environment["game_config"])
	GameSpeed.time_scale = float(simulation["game_speed"])
	_character_defaults = agents["defaults"]
	_character_overrides = agents["individual"]
	_character_initial_state_defaults = agents["initial_state"]["defaults"]
	_character_initial_state_overrides = agents["initial_state"]["individual"]
	_normalized_experiment_config = normalized
	_headless_run = true
	_scheduled_events = normalized["events"]
	_quit_on_all_dead = simulation["quit_on_all_dead"]
	_max_simulation_seconds = float(simulation["max_simulation_seconds"])

	if normalized.has("screenshot") and normalized["screenshot"] is Dictionary:
		var shot: Dictionary = normalized["screenshot"]
		_screenshot_path = String(shot.get("path", ""))
		_screenshot_delay = float(shot.get("delay_seconds", 3.0))

	GameLogger.log_event("headless", "Configuration validée depuis %s" % path)
	GameLogger.log_experiment_config(normalized)

func _fail_headless_config(message: String) -> void:
	_headless_run = true
	_run_finished = true
	GameLogger.log_event("headless", message)
	call_deferred("_quit_after_invalid_headless_config")

func _setup_rl_mode(characters: Array) -> void:
	_rl_mode = OS.get_environment(RL_MODE_ENV_VAR) != ""
	if not _rl_mode:
		return
	_rl_agent = characters[0].node
	_rl_agent.rl_controlled = true
	_rl_spawn = _rl_agent.position
	_rl_bridge = RLBridge.new()
	add_child(_rl_bridge)
	_rl_bridge.message_received.connect(_on_rl_message)
	if _rl_bridge.start() != OK:
		push_error("RL bridge: port 11008 indisponible")
		_rl_mode = false
		return
	GameSpeed.time_scale = 0.0
	GameLogger.log_event("rl", "Mode RL TCP actif : Rouge, Discrete(7), pas 0.25 s simulée")

func _on_rl_message(message: Dictionary) -> void:
	if not _rl_mode:
		return
	match String(message.get("type", "")):
		"reset":
			_rl_reset(int(message.get("seed", _experiment_seed)), int(message.get("max_steps", 40)))
		"step":
			if _rl_waiting:
				_rl_agent.set_rl_action(int(message.get("action", 0)))
				_rl_waiting = false
				GameSpeed.time_scale = 1.0
		"close":
			_rl_bridge.send({"type": "closed"})
			get_tree().quit()
		_:
			_rl_bridge.send({"type": "error", "message": "Commande attendue : reset, step ou close"})

func _rl_reset(seed_value: int, max_steps: int) -> void:
	_experiment_seed = max(seed_value, 0)
	seed(_experiment_seed)
	_rl_max_steps = clamp(max_steps, 1, 2400)
	_rl_steps = 0
	_rl_simulation_clock = 0.0
	_rl_waiting = true
	_rl_agent.reset_for_rl(_rl_spawn)
	GameSpeed.time_scale = 0.0
	_rl_bridge.send({"type": "observation", "observation": _rl_observation(), "reward": 0.0, "terminated": false, "truncated": false, "info": _rl_info()})

func _process_rl(delta: float) -> void:
	if not _rl_mode or _rl_waiting or _rl_agent == null:
		return
	_rl_simulation_clock += delta * GameSpeed.time_scale
	if _rl_simulation_clock + 0.000001 < 0.25:
		return
	_rl_simulation_clock = fmod(_rl_simulation_clock, 0.25)
	_rl_steps += 1
	var terminated: bool = _rl_agent.is_dead
	var truncated: bool = _rl_steps >= _rl_max_steps and not terminated
	var reward := 0.005 * 0.25 - 0.001
	if terminated:
		reward -= 2.0
	_rl_waiting = true
	GameSpeed.time_scale = 0.0
	_rl_bridge.send({"type": "observation", "observation": _rl_observation(), "reward": reward, "terminated": terminated, "truncated": truncated, "info": _rl_info()})

func _rl_observation() -> Array:
	var half := MAP_SIZE / 2.0
	return [
		_rl_agent.hunger / 100.0,
		float(_rl_agent.berries_carried) / max(1.0, float(GameConfig.max_berries_carried)),
		_rl_agent.position.x / half, _rl_agent.position.z / half,
		_rl_agent.velocity.x / max(0.1, _rl_agent.move_speed), _rl_agent.velocity.z / max(0.1, _rl_agent.move_speed),
		(half - _rl_agent.position.z) / (2.0 * half), (half + _rl_agent.position.z) / (2.0 * half),
		(half - _rl_agent.position.x) / (2.0 * half), (half + _rl_agent.position.x) / (2.0 * half),
	]

func _rl_info() -> Dictionary:
	return {"agent": _rl_agent.display_name, "step": _rl_steps, "simulated_seconds": _rl_steps * 0.25, "hunger": _rl_agent.hunger, "berries_picked": _rl_agent.berries_picked_total, "berries_eaten": _rl_agent.berries_eaten_total}

func _quit_after_invalid_headless_config() -> void:
	get_tree().quit(1)

func _take_screenshot() -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(_screenshot_path)
	GameLogger.log_event("screenshot", "Capture enregistrée : %s" % _screenshot_path)
	_screenshot_path = ""
	_finish_headless_run("screenshot_complete")

func _finish_headless_run(reason: String) -> void:
	if _run_finished:
		return
	_run_finished = true
	if _headless_run:
		var agents: Array = []
		for character in _characters:
			if not is_instance_valid(character):
				continue
			var parameters := _character_defaults.duplicate(true)
			if _character_overrides.has(character.display_name):
				parameters.merge(_character_overrides[character.display_name], true)
			var lifetime: float = character.death_elapsed_seconds
			if lifetime < 0.0:
				lifetime = _simulation_clock
			agents.append({
				"name": character.display_name,
				"parameters": parameters,
				"alive": not character.is_dead,
				"current_goal": character.current_goal,
				"hunger": character.hunger,
				"berries_picked_total": character.berries_picked_total,
				"berries_eaten_total": character.berries_eaten_total,
				"berries_carried": character.berries_carried,
				"memorized_ronces": character.memorized_ronces_count(),
				"wander_reorientations_total": character.wander_reorientations_total,
				"distance_travelled_total": character.distance_travelled_total,
				"visited_zones_total": character.visited_zones_total,
				"zone_discoveries_total": character.zone_discoveries_total,
				"zone_revisits_total": character.zone_revisits_total,
				"social_encounters_total": character.social_encounters_total,
				"social_contact_seconds": character.social_contact_seconds,
				"current_social_neighbors": character.current_social_neighbors,
				"social_follow_decisions_total": character.social_follow_decisions_total,
				"social_avoid_decisions_total": character.social_avoid_decisions_total,
				"social_shares_total": character.social_shares_total,
				"memories_received_total": character.memories_received_total,
				"food_shared_total": character.food_shared_total,
				"food_received_total": character.food_received_total,
				"aggression_incidents_total": character.aggression_incidents_total,
				"aggression_received_total": character.aggression_received_total,
				"llm_calls_total": character.llm_calls_total,
				"llm_errors_total": character.llm_errors_total,
				"llm_total_latency_ms": character.llm_total_latency_ms,
				"lifetime_seconds": lifetime,
			})
		GameLogger.write_summary({
			"status": "completed",
			"reason": reason,
			"elapsed_seconds": _simulation_clock,
			"experiment": _normalized_experiment_config,
			"executed_events": _executed_events,
			"agents": agents,
		})
	get_tree().quit()

func _process_scheduled_events() -> void:
	while _next_event_index < _scheduled_events.size():
		var event: Dictionary = _scheduled_events[_next_event_index]
		if float(event["at_seconds"]) > _simulation_clock:
			return
		_execute_environment_event(event, _next_event_index)
		_next_event_index += 1

func _execute_environment_event(event: Dictionary, event_index: int) -> void:
	var event_type := String(event["type"])
	var affected := 0
	if event_type == "remove_ronces_fraction":
		var active_ronces := _ronces.filter(func(ronce): return is_instance_valid(ronce))
		var target_count := ceili(active_ronces.size() * float(event["fraction"]))
		var rng := RandomNumberGenerator.new()
		rng.seed = _experiment_seed + event_index + 1000003
		for _i in target_count:
			if active_ronces.is_empty():
				break
			var selected_index := rng.randi_range(0, active_ronces.size() - 1)
			var ronce = active_ronces[selected_index]
			active_ronces.remove_at(selected_index)
			_ronces.erase(ronce)
			ronce.queue_free()
			affected += 1
	elif event_type == "spawn_ronces":
		affected = _spawn_event_ronces(int(event["count"]), event_index)
	var record := event.duplicate(true)
	record["executed_at_simulation_seconds"] = _simulation_clock
	record["affected_ronces"] = affected
	_executed_events.append(record)
	GameLogger.log_event_data("environment_event", "Événement %s exécuté (%d ronciers affectés)" % [event_type, affected], record)

func _spawn_event_ronces(count: int, event_index: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = _experiment_seed + event_index + 2000003
	var half := MAP_SIZE / 2.0 - WALL_THICKNESS - 2.0
	for _i in count:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		_spawn_ronce(Vector3(x, _terrain_height(x, z) + 0.5, z))
	return count

func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.6, 0.9)
	sky_material.sky_horizon_color = Color(0.75, 0.85, 0.95)
	sky_material.ground_bottom_color = Color(0.35, 0.3, 0.22)
	sky_material.ground_horizon_color = Color(0.75, 0.85, 0.95)
	sky_material.sun_angle_max = 50.0

	var sky := Sky.new()
	sky.sky_material = sky_material

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.9
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.ssao_enabled = true
	env.ssr_enabled = true

	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.1

	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 2.0

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	get_viewport().use_taa = true

func _build_light() -> DirectionalLight3D:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -30, 0)
	light.light_color = Color(1.0, 0.96, 0.88)
	light.light_energy = GameConfig.light_energy
	light.shadow_enabled = true
	light.light_angular_distance = 1.5
	light.shadow_bias = 0.1
	light.shadow_normal_bias = 4.0
	add_child(light)
	return light

func _init_terrain_noise() -> void:
	_terrain_noise = FastNoiseLite.new()
	_terrain_noise.seed = _experiment_seed
	_terrain_noise.frequency = TERRAIN_NOISE_FREQUENCY
	_terrain_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

func _terrain_height(x: float, z: float) -> float:
	var half := MAP_SIZE / 2.0
	var edge_dist: float = min(half - abs(x), half - abs(z))
	var falloff: float = clamp(edge_dist / TERRAIN_FLAT_MARGIN, 0.0, 1.0)
	var base := _terrain_noise.get_noise_2d(x, z) * TERRAIN_AMPLITUDE * falloff * _center_flatten_factor(x, z) * _spawn_flatten_factor(x, z)
	return base + _valley_offset(x, z)

func _center_flatten_factor(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var t: float = clamp(d / CENTER_FLAT_RADIUS, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _spawn_flatten_factor(x: float, z: float) -> float:
	var factor := 1.0
	for p in SPAWN_POINTS:
		var d: float = Vector2(x - p.x, z - p.y).length()
		var t: float = clamp(d / SPAWN_FLAT_RADIUS, 0.0, 1.0)
		factor = min(factor, t * t * (3.0 - 2.0 * t))
	return factor

func _valley_offset(x: float, z: float) -> float:
	var offset := 0.0
	for p in SPAWN_POINTS:
		var d: float = Vector2(x - p.x, z - p.y).length()
		var t: float = clamp(1.0 - d / VALLEY_RADIUS, 0.0, 1.0)
		var smooth_t: float = t * t * (3.0 - 2.0 * t)
		offset -= VALLEY_DEPTH * smooth_t
	return offset

func _build_triplanar_material(dir: String, scale: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://scripts/triplanar.gdshader")
	mat.set_shader_parameter("albedo_tex", load("res://assets/textures/%s/diffuse_1k.jpg" % dir))
	mat.set_shader_parameter("normal_tex", load("res://assets/textures/%s/nor_gl_1k.jpg" % dir))
	mat.set_shader_parameter("arm_tex", load("res://assets/textures/%s/arm_1k.jpg" % dir))
	mat.set_shader_parameter("texture_scale", scale)
	return mat

func _build_terrain_mesh() -> ArrayMesh:
	var resolution := TERRAIN_RESOLUTION
	var half := MAP_SIZE / 2.0
	var step := MAP_SIZE / float(resolution)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi in resolution + 1:
		for xi in resolution + 1:
			var x := -half + xi * step
			var z := -half + zi * step
			var y := _terrain_height(x, z)
			st.set_uv(Vector2(float(xi) / resolution, float(zi) / resolution))
			st.add_vertex(Vector3(x, y, z))
	for zi in resolution:
		for xi in resolution:
			var i0 := zi * (resolution + 1) + xi
			var i1 := i0 + 1
			var i2 := i0 + (resolution + 1)
			var i3 := i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()

func _build_terrain_collision_shape() -> HeightMapShape3D:
	var resolution := TERRAIN_RESOLUTION
	var half := MAP_SIZE / 2.0
	var step := MAP_SIZE / float(resolution)
	var width := resolution + 1
	var shape := HeightMapShape3D.new()
	shape.map_width = width
	shape.map_depth = width
	var data := PackedFloat32Array()
	data.resize(width * width)
	for zi in width:
		for xi in width:
			var x := -half + xi * step
			var z := -half + zi * step
			data[zi * width + xi] = _terrain_height(x, z)
	shape.map_data = data
	return shape

func _build_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "Floor"

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_terrain_mesh()
	mesh_instance.material_override = _build_triplanar_material("leafy_grass", 0.25)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	collision.shape = _build_terrain_collision_shape()
	var step := MAP_SIZE / float(TERRAIN_RESOLUTION)
	collision.scale = Vector3(step, 1.0, step)
	body.add_child(collision)

	add_child(body)

func _build_walls() -> void:
	var half := MAP_SIZE / 2.0
	_add_wall(Vector3(0, WALL_HEIGHT / 2.0, -half), Vector3(MAP_SIZE + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(Vector3(0, WALL_HEIGHT / 2.0, half), Vector3(MAP_SIZE + WALL_THICKNESS, WALL_HEIGHT, WALL_THICKNESS))
	_add_wall(Vector3(-half, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, MAP_SIZE + WALL_THICKNESS))
	_add_wall(Vector3(half, WALL_HEIGHT / 2.0, 0), Vector3(WALL_THICKNESS, WALL_HEIGHT, MAP_SIZE + WALL_THICKNESS))

func _add_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Wall"

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _build_triplanar_material("brick_wall_001", 0.5)
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	body.position = pos
	add_child(body)

func _build_decor() -> void:
	var half := MAP_SIZE / 2.0 - WALL_THICKNESS - 3.0
	var rng := RandomNumberGenerator.new()
	rng.seed = _experiment_seed
	for i in 8:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		_add_rock(Vector3(x, _terrain_height(x, z), z), rng.randf_range(0.5, 1.1))
	for i in 6:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		_add_tree(Vector3(x, _terrain_height(x, z), z), rng.randf_range(0.85, 1.3))

func _add_rock(pos: Vector3, scale: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Rock"

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.0, 0.7, 0.9) * scale
	mesh_instance.mesh = mesh
	mesh_instance.rotation_degrees = Vector3(0, randf() * 90.0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.44, 0.42)
	mat.roughness = 0.95
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = mesh.size
	collision.shape = shape
	body.add_child(collision)

	body.position = pos + Vector3(0, mesh.size.y / 2.0, 0)
	add_child(body)

func _add_tree(pos: Vector3, scale: float) -> void:
	var root := Node3D.new()
	root.name = "Tree"

	var trunk_mesh := MeshInstance3D.new()
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.15 * scale
	trunk.bottom_radius = 0.2 * scale
	trunk.height = 2.0 * scale
	trunk_mesh.mesh = trunk
	trunk_mesh.position = Vector3(0, trunk.height / 2.0, 0)
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.24, 0.15)
	trunk_mesh.material_override = trunk_mat
	root.add_child(trunk_mesh)

	var canopy_mesh := MeshInstance3D.new()
	var canopy := SphereMesh.new()
	canopy.radius = 1.1 * scale
	canopy.height = 1.8 * scale
	canopy_mesh.mesh = canopy
	canopy_mesh.position = Vector3(0, trunk.height + canopy.height / 2.5, 0)
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.2, 0.4, 0.18)
	canopy_mesh.material_override = canopy_mat
	root.add_child(canopy_mesh)

	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = trunk.bottom_radius
	shape.height = trunk.height
	collision.shape = shape
	collision.position = Vector3(0, trunk.height / 2.0, 0)
	body.add_child(collision)
	root.add_child(body)

	root.position = pos
	add_child(root)

func _build_camera() -> Camera3D:
	var camera := Camera3D.new()
	camera.set_script(load("res://scripts/free_camera.gd"))
	camera.current = true
	camera.terrain_height_fn = Callable(self, "_terrain_height")
	add_child(camera)
	return camera

func _build_ui(characters: Array, camera: Camera3D, light: DirectionalLight3D) -> void:
	var ui := CanvasLayer.new()
	ui.set_script(load("res://scripts/ui_manager.gd"))
	add_child(ui)
	ui.setup(characters, camera, _dev_mode, light)
	_ui = ui

func _spawn_character(x: float, z: float, color: Color, char_name: String, corner: String, rigged: bool = false) -> Dictionary:
	var character := CharacterBody3D.new()
	character.set_script(load("res://scripts/character.gd"))
	character.position = Vector3(x, _terrain_height(x, z) + 1.0, z)
	character.set("display_name", char_name)
	character.add_to_group("agents")
	var half := MAP_SIZE / 2.0 - WALL_THICKNESS / 2.0 - 0.4
	character.set("map_half_x", half)
	character.set("map_half_z", half)
	for key in _character_defaults:
		character.set(key, _character_defaults[key])
	if _character_overrides.has(char_name):
		for key in _character_overrides[char_name]:
			character.set(key, _character_overrides[char_name][key])
	for key in _character_initial_state_defaults:
		character.set(key, _character_initial_state_defaults[key])
	if _character_initial_state_overrides.has(char_name):
		for key in _character_initial_state_overrides[char_name]:
			character.set(key, _character_initial_state_overrides[char_name][key])

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.4
	collision.shape = shape
	collision.position = Vector3(0, 0.7, 0)
	character.add_child(collision)

	add_child(character)

	if rigged:
		_setup_rigged_visual(character, color)
	else:
		_setup_box_visual(character, color)

	return {
		"node": character,
		"name": char_name,
		"color": color,
		"corner": corner,
	}

func _setup_box_visual(character: CharacterBody3D, color: Color) -> void:
	var body_mesh := MeshInstance3D.new()
	var body_shape_mesh := BoxMesh.new()
	body_shape_mesh.size = Vector3(0.6, 1.0, 0.4)
	body_mesh.mesh = body_shape_mesh
	body_mesh.position = Vector3(0, 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	body_mesh.material_override = mat
	character.add_child(body_mesh)

	var head_mesh := MeshInstance3D.new()
	var head_shape_mesh := BoxMesh.new()
	head_shape_mesh.size = Vector3(0.4, 0.4, 0.4)
	head_mesh.mesh = head_shape_mesh
	head_mesh.position = Vector3(0, 1.2, 0)
	head_mesh.material_override = mat
	character.add_child(head_mesh)

	character.setup_visual(body_mesh, head_mesh)

func _setup_rigged_visual(character: CharacterBody3D, color: Color) -> void:
	var scene: PackedScene = load("res://assets/models/character.glb")
	var model: Node3D = scene.instantiate()
	character.add_child(model)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	for child in model.find_children("*", "MeshInstance3D", true, false):
		child.material_override = mat

	var anim_player: AnimationPlayer = model.find_child("AnimationPlayer", true, false)
	if anim_player != null:
		for anim_name in ["Idle", "Walk"]:
			if anim_player.has_animation(anim_name):
				anim_player.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	character.setup_rigged_visual(anim_player)

func _spawn_ronces() -> void:
	var quadrant_half := MAP_SIZE / 2.0 - WALL_THICKNESS - 2.0
	var quadrants := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	var per_quadrant := GameConfig.ronce_count / 4
	var remainder := GameConfig.ronce_count % 4
	for i in quadrants.size():
		var sign_vec: Vector2 = quadrants[i]
		var count := per_quadrant + (1 if i < remainder else 0)
		for j in count:
			var x := randf_range(0.0, quadrant_half) * sign_vec.x
			var z := randf_range(0.0, quadrant_half) * sign_vec.y
			_spawn_ronce(Vector3(x, _terrain_height(x, z) + 0.5, z))

func _spawn_dev_spawn_ronces() -> void:
	var offsets := [Vector2(6, 0), Vector2(-6, 0), Vector2(0, 6), Vector2(0, -6)]
	for offset in offsets:
		var pos := Vector3(offset.x, _terrain_height(offset.x, offset.y) + 0.5, offset.y)
		_spawn_ronce(pos)

const BUSH_LOBES := [
	{"pos": Vector3(0, 0.4, 0), "radius": 1.0, "height": 1.4},
	{"pos": Vector3(0.7, 0.5, 0.3), "radius": 0.55, "height": 0.75},
	{"pos": Vector3(-0.6, 0.45, -0.4), "radius": 0.6, "height": 0.8},
	{"pos": Vector3(0.1, 0.75, -0.6), "radius": 0.5, "height": 0.7},
	{"pos": Vector3(-0.4, 0.7, 0.6), "radius": 0.45, "height": 0.65},
	{"pos": Vector3(0.5, 0.35, -0.75), "radius": 0.45, "height": 0.6},
	{"pos": Vector3(-0.75, 0.3, 0.25), "radius": 0.4, "height": 0.55},
]

func _build_bush_mesh() -> ArrayMesh:
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for lobe in BUSH_LOBES:
		var sphere := SphereMesh.new()
		sphere.radius = lobe["radius"]
		sphere.height = lobe["height"]
		sphere.radial_segments = 8
		sphere.rings = 5
		var transform := Transform3D(Basis(), lobe["pos"])
		surface_tool.append_from(sphere, 0, transform)
	return surface_tool.commit()

func _bush_berry_positions(count: int) -> Array:
	var positions: Array = []
	for i in count:
		var lobe: Dictionary = BUSH_LOBES[i % BUSH_LOBES.size()]
		var dir := Vector3(randf_range(-1.0, 1.0), randf_range(0.4, 1.0), randf_range(-1.0, 1.0)).normalized()
		var pos: Vector3 = lobe["pos"] + dir * (lobe["radius"] * 0.85)
		positions.append(pos)
	return positions

func _spawn_ronce(pos: Vector3) -> void:
	var ronce := Area3D.new()
	ronce.name = "Ronce"
	ronce.set_script(load("res://scripts/ronce.gd"))
	ronce.berries = GameConfig.berries_per_ronce
	ronce.position = pos

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_bush_mesh()
	var bush_mat := StandardMaterial3D.new()
	bush_mat.albedo_color = Color(0.16, 0.34, 0.12)
	bush_mat.roughness = 0.95
	mesh_instance.material_override = bush_mat
	ronce.add_child(mesh_instance)

	var berry_mat := StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.04, 0.04, 0.05)
	berry_mat.roughness = 0.3
	berry_mat.metallic = 0.05

	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.0
	collision.shape = shape
	ronce.add_child(collision)

	var solid_body := StaticBody3D.new()
	solid_body.name = "RonceCollision"
	var solid_collision := CollisionShape3D.new()
	var solid_shape := CylinderShape3D.new()
	solid_shape.radius = 1.0
	solid_shape.height = 1.4
	solid_collision.shape = solid_shape
	solid_collision.position = Vector3(0, 0.7, 0)
	solid_body.add_child(solid_collision)
	ronce.add_child(solid_body)

	add_child(ronce)
	ronce.setup_visual(_bush_berry_positions(ronce.berries), berry_mat)
	_ronces.append(ronce)
