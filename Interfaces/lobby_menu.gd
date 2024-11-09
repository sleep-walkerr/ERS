extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CenterContainer/ReturnButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("MainMenu"))
	#$CenterContainer/Panel/PanelLayout/CenterContainer/ReadyButton.pressed.connect(Callable(get_node("/root/Main"), "SwitchInterface").bind("MainGameplayInterface"))
	
	if multiplayer.is_server():
		get_parent().player_number = 1
		get_parent().players[1] = 1
		$CenterContainer/Panel/PanelLayout/PlayerLabels/Player1Label.visible = true
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_ready_button_toggled(toggled_on: bool) -> void:
	var multiplayer_id = get_parent().multiplayer.get_unique_id()
	# Change the color of your own label
	if toggled_on:
		$CenterContainer/Panel/PanelLayout/PlayerLabels.get_child(get_parent().players[get_parent().multiplayer.get_unique_id()] - 1).label_settings.font_color = Color(0.12, 0.76, 0.2)
	else:
		$CenterContainer/Panel/PanelLayout/PlayerLabels.get_child(get_parent().players[get_parent().multiplayer.get_unique_id()] - 1).label_settings.font_color = Color(0, 0, 0)
	get_parent().UpdatePlayerLobbyStatus.rpc($CenterContainer/Panel/PanelLayout/PlayerLabels.get_child(get_parent().players[multiplayer_id] - 1).get_path(), toggled_on)
