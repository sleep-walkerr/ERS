extends Control

var player_ready_status = {} # key: player_id, value: [bool ready, path_to_label]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CenterContainer/ReturnButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("MainMenu"))
	#$CenterContainer/Panel/PanelLayout/CenterContainer/ReadyButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("MainGameplayInterface"))
	
	if multiplayer.is_server():
		get_parent().player_number = 1
		get_parent().players[1] = 1
		player_ready_status[multiplayer.get_unique_id()] = {"ready" : false, "path_to_label" : $CenterContainer/Panel/PanelLayout/PlayerLabels/Player1Label.get_path()}
		$CenterContainer/Panel/PanelLayout/PlayerLabels/Player1Label.visible = true
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ready_button_toggled(toggled_on: bool) -> void:
	var multiplayer_id = get_parent().multiplayer.get_unique_id()
	# Change the color of your own label
	if toggled_on:
		player_ready_status[multiplayer.get_unique_id()]["ready"] = true
	else:
		player_ready_status[multiplayer.get_unique_id()]["ready"] = false
	get_parent().UpdateLobbyPlayerList.rpc(player_ready_status)
