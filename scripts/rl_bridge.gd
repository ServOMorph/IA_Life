class_name RLBridge
extends Node

## Bridge TCP/JSONL minimal, sans dépendance Godot externe.
## Le protocole est volontairement synchrone : Python envoie une commande, Godot répond
## sur la même connexion. Les durées exprimées par les messages sont toujours simulées.

signal client_connected
signal client_disconnected
signal message_received(message: Dictionary)

@export var port := 11008

var _server := TCPServer.new()
var _peer: StreamPeerTCP
var _receive_buffer := ""

func start() -> Error:
	var error := _server.listen(port, "127.0.0.1")
	if error == OK:
		GameLogger.log_event_data("rl_bridge", "Serveur TCP RL prêt", {"port": port})
	return error

func stop() -> void:
	if _peer != null:
		_peer.disconnect_from_host()
		_peer = null
	_server.stop()

func has_client() -> bool:
	return _peer != null and _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED

func send(message: Dictionary) -> void:
	if not has_client():
		return
	_peer.put_data((JSON.stringify(message) + "\n").to_utf8_buffer())

func _process(_delta: float) -> void:
	if _peer == null and _server.is_connection_available():
		_peer = _server.take_connection()
		_peer.set_no_delay(true)
		client_connected.emit()
		GameLogger.log_event("rl_bridge", "Client Python connecté")
	if _peer == null:
		return
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_peer = null
		_receive_buffer = ""
		client_disconnected.emit()
		GameLogger.log_event("rl_bridge", "Client Python déconnecté")
		return
	var available := _peer.get_available_bytes()
	if available <= 0:
		return
	_receive_buffer += _peer.get_utf8_string(available)
	while _receive_buffer.contains("\n"):
		var newline := _receive_buffer.find("\n")
		var line := _receive_buffer.left(newline)
		_receive_buffer = _receive_buffer.substr(newline + 1)
		var parsed = JSON.parse_string(line)
		if parsed is Dictionary:
			message_received.emit(parsed)
		else:
			send({"type": "error", "message": "JSONL invalide"})
