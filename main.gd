extends Control
var current_interface
var player_number
var players = {} # key is player id, value is player number



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_interface = load("res://Interfaces/MainMenu.tscn").instantiate()
	self.add_child(current_interface)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func SwitchInterface(next_interface) -> void: # Switch to Another Interface
	# If next interface exists
	if ResourceLoader.exists(str("res://Interfaces/", next_interface, ".tscn")):
		#--Delete previous interface
		remove_child(current_interface)
		current_interface.queue_free()
		#--Load next interface
		current_interface = load(str("res://Interfaces/", next_interface, ".tscn")).instantiate()
		#Position Interface in center of window
		#current_interface.position = get_window().size / Vector2i(2,2)
		#--Place interface in main scene
		self.add_child(current_interface)
	else:
		print("Interface ",next_interface," does not exist.")

func ConnectedToLobby(): # only called on clients
	SwitchInterface("LobbyMenu")
	print("Connection Succeeded!")
	print(multiplayer.get_peers())
	
	
func ServerHasDisconnected(): # only called on clients
	print("Server has disconnected...")
	SwitchInterface("MainMenu")
	
func ClientConnectedToServer(id): # only called on server when clients connect
	# find out how to prevent new connections after lobby interface is closed
	print(id, " connected")
	# Add new player to players dictionary
	if players.size() < 4:
		multiplayer.multiplayer_peer.refuse_new_connections = false
		for i in range(4):
			if !players.has(i):
				players[i] = id
				# Add new player to lobby dictionary 
				var new_player_label = current_interface.find_child("PlayerLabels").get_child(i).get_path()
				current_interface.player_ready_status[id] = {"ready" : false, "path_to_label" : new_player_label}
				UpdateLobbyPlayerList.rpc(current_interface.player_ready_status) # send updated player list to clients and update their view
				UpdatePlayersDictionary.rpc(players)
				break
	elif players.size() >= 4:
		multiplayer.multiplayer_peer.refuse_new_connections = true
		multiplayer.multiplayer_peer.disconnect_peer(id)
		print("Refusing new connections...")
	
func ClientDisconnectedFromServer(id): # server signal for when clients disconnect
	# needs updating for changes to players
	print(id, " has disconnected...")
	for player in players:
		if players[player] == id:
			players.erase(player)
	RemovePlayerFromLobbyList.rpc(id)
	UpdatePlayersDictionary.rpc(players)
	
@rpc
func UpdatePlayersDictionary(new_players_dict):
	print("Updating Dictionary...")
	players = new_players_dict
	
	
@rpc("any_peer", "call_local", "reliable", 0)
func UpdateLobbyPlayerList(player_list): # used for adding players and updating their ready status
	# for all pieces of information given for each player in the list, update everything accordingly (i.e. ready up status)
	current_interface.player_ready_status = player_list
	for player in player_list: # for each player, make sure their label is visible and the text color reflects their ready status
		# make sure label is visible
		if !get_node(player_list[player]["path_to_label"]).visible:
			get_node(player_list[player]["path_to_label"]).visible = true
		# Change text color to indicate if readied up or not
		if player_list[player]["ready"]:
			get_node(player_list[player]["path_to_label"]).label_settings.font_color = Color(0.12, 0.76, 0.2)
		else:
			get_node(player_list[player]["path_to_label"]).label_settings.font_color = Color(0, 0, 0)
	# if all players are ready, enter the game
	if multiplayer.is_server():
		var all_ready = false
		for player in player_list:
			if player_list[player]["ready"]:
				all_ready = true
			else:
				all_ready = false
				break
		if all_ready:
			EnterGame.rpc()
	
	
@rpc("any_peer", "call_local", "reliable", 0)
func RemovePlayerFromLobbyList(id):
	if current_interface.name == "LobbyMenu":
		get_node(current_interface.player_ready_status[id]["path_to_label"]).visible = false
		current_interface.player_ready_status.erase(id)
		
@rpc("authority", "call_local", "reliable", 0)
func EnterGame():
	print("Entering game")
	SwitchInterface("MainGameplayInterface")
