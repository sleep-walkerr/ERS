extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HostButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("LobbyMenu"))
	$JoinButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("JoinMenu"))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(9999, 4)
	get_parent().multiplayer.multiplayer_peer = peer
	get_parent().multiplayer.peer_connected.connect(get_parent().ClientConnectedToServer)
	
