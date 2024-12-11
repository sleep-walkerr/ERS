extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ReturnButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("MainMenu"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_join_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client($IDEntry.text, 9999)
	get_parent().multiplayer.multiplayer_peer = peer
	# Connect signals
	get_parent().multiplayer.connected_to_server.connect(get_parent().ConnectedToLobby) # If connection succeeds
	get_parent().multiplayer.connection_failed.connect(ConnectionAttemptFailed) # If connection fails
	get_parent().multiplayer.server_disconnected.connect(get_parent().ServerHasDisconnected) # If the connection is disconnected
	
	
func ConnectionAttemptFailed() -> void:
	get_parent().multiplayer.multiplayer_peer = null
	print("Connection failed...")
