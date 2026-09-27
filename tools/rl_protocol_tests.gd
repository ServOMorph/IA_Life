extends Node

const RLProtocol = preload("res://scripts/rl_protocol.gd")

var _failures: Array[String] = []

func _ready() -> void:
	var protocol := RLProtocol.new()
	_expect(not protocol.accept_step(1, 0), "Un pas avant reset doit être refusé.")
	_expect(protocol.reset() == 1, "Le premier épisode doit avoir l'identifiant 1.")
	_expect(not protocol.accept_step(2, 0), "Un épisode périmé doit être refusé.")
	_expect(not protocol.accept_step(1, 1), "Un pas hors séquence doit être refusé.")
	_expect(protocol.accept_step(1, 0), "Le premier pas doit être accepté.")
	_expect(not protocol.accept_step(1, 0), "Un pas dupliqué doit être refusé.")
	protocol.finish()
	_expect(not protocol.accept_step(1, 1), "Un pas après fin doit être refusé.")
	_expect(protocol.reset() == 2 and protocol.accept_step(2, 0), "Un reset doit ouvrir un nouvel épisode.")
	if _failures.is_empty():
		print("SUCCÈS : protocole RL validé.")
		get_tree().quit(0)
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
