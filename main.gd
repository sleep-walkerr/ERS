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

func ConnectedToLobby(): # only called on clients
	SwitchInterface("LobbyMenu")
	print("Connection Succeeded!")
	print(multiplayer.get_peers())
	
	
func ServerHasDisconnected(): # only called on clients
	print("Server has disconnected...")
	SwitchInterface("MainMenu")
	
func ClientConnectedToServer(id): # only called on server when clients connect
	# find out how to prevent new connections after lobby interface is closed
	print("Someone connected: ", id)
	# Add new player to players dictionary
	players[id] = multiplayer.get_peers().size() + 1 # id of player is matched to player number
	# Make their label visible for all players
	var new_player_label = current_interface.find_child("PlayerLabels").get_child(players[id]-1) # in list of player labels, get index based on player number - 1
	new_player_label.visible = true # set it to visible locally
	UpdateLobbyPlayerList.rpc(new_player_label.get_path()) # set it to visible remote
	# set hosts label to visible 
	UpdateLobbyPlayerList.rpc_id(id, current_interface.find_child("PlayerLabels").get_child(players[get_parent().multiplayer.get_unique_id()]-1).get_path())
	#Update the players dictionary for everyone
	UpdatePlayersDictionary.rpc(players)
	
func ClientDisconnectedFromServer(id): # server signal for when clients disconnect
	print(id, " has disconnected...")
	players.erase(id) # remove client from players list
	UpdatePlayersDictionary.rpc(players)
	

@rpc
func UpdatePlayersDictionary(new_players_dict):
	print("Updating Dictionary...")
	players = new_players_dict
	
	
@rpc("any_peer")
func UpdatePlayerLobbyStatus(path, ready):
	if current_interface.name == "LobbyInterface":
		print("updating...")
		if ready:
			get_node(path).label_settings.font_color = Color(0.12, 0.76, 0.2)
		else:
			get_node(path).label_settings.font_color = Color(0, 0, 0)

	
@rpc
func UpdateLobbyPlayerList(path): # used to make player labels visible for all players in lobby according to players present
	get_node(path).visible = true # sets player label to visible indicating they have joined the lobby
