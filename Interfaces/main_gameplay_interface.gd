extends Node2D
var original_cards = load("res://card/CardStack.tscn").instantiate()
enum suits {spades, hearts, clubs, diamonds}
var player_cards_struct = {}
signal original_deck_shuffled # emitted when original cards are created and ready to be shuffled


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create deck and add to scene
	create_cards()
	original_cards.position = self.get_viewport_rect().size / Vector2(2,2)
	self.add_child(original_cards)
	# Create player cardstacks and distribute cards
	if !multiplayer.is_server():
		await original_deck_shuffled
	prepare_player_cardstacks()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void: # use switch/match statement here, match on event is action pressed
	if(event.is_action_pressed("click")):
		PlayerPlayedCard.rpc()
	if(event.is_action_pressed("space")):
		PlayerSlapped.rpc()

func create_cards() -> void: #function to create deck, no joker for now
	for suit in suits:
		for card_number in range(2,15):
			var next_card = load("res://card/Card.tscn").instantiate() #create next card to add
			#assign number, suit, and front texture
			next_card.number = card_number
			next_card.suit = suit
			next_card.card_front_texture = load("res://svg_playing_cards/fronts/"+str(suit)+"_"+str(card_number)+".svg")
			next_card.name = str(suit,card_number)
			#add to original deck var
			original_cards.add_to_bottom(next_card)
			
	# if we are the server, shuffle the cards and send the order to other players
	if multiplayer.is_server():
		# run shuffle on original_cards
		original_cards.shuffle()
		# send order to other players
		var shuffled_order = []
		for card in original_cards.get_children():
			shuffled_order.append([card.number, card.suit])
		SyncShuffle.rpc(shuffled_order)

			
func prepare_player_cardstacks() -> void: # try loading once and using that one variable to instantiate all of them, better coding practice
	

	# Create card stacks for each player
	for player in get_parent().players:
		var player_cardstack = load("res://card/CardStack.tscn").instantiate()
		player_cards_struct[get_parent().players[player]] = player_cardstack # Assign player card stack to id in dictionary
	# For each cardstack, add 1 card until all cards from deck are gone
	var current_index = 0 # iterator used to determine which cardstack to send to next
	for card in original_cards.get_children():
		original_cards.top_card_to_other_stack(player_cards_struct[get_parent().players[current_index % player_cards_struct.size()]])
		current_index = current_index + 1
		

	
	# Position Stacks
	#--For now just quarter screen and add static positions for each player, will change when multiplayer is implemented
	var viewport_x = get_viewport_rect().size.x
	var viewport_y = get_viewport_rect().size.y
	
	#--Position Self Cardstack
	player_cards_struct[multiplayer.get_unique_id()].position = Vector2(viewport_x / 2, (viewport_y - (viewport_y / 4)))
	# Rename Self Cardstack
	player_cards_struct[multiplayer.get_unique_id()].name = str(multiplayer.get_unique_id(),"_CardStack")
	# Actually add cardstack to scene
	add_child(player_cards_struct[multiplayer.get_unique_id()])
	
	#Position Other Players' Cardstacks
	#--Set up other players horizontal positions along a line
	var horizontal_player_alignment = Line2D.new()
	var increment =  viewport_x / player_cards_struct.size() # find even spacing for players along the horizontal line
	# Add cardstack horizontal positions
	for x in range(1,player_cards_struct.size()):
		horizontal_player_alignment.add_point(Vector2(increment*x,viewport_y / 8))
	# Add line to scene tree
	add_child(horizontal_player_alignment)
	
	 # For each player that isn't you, place their stack at one of the points
	var not_me = []
	# get ids of all other players
	for player in player_cards_struct:
		if player != multiplayer.get_unique_id():
			not_me.append(player)
	
	for x in range(not_me.size()): # for as many points aka other players, position each one and add to scene
		player_cards_struct[not_me[x]].position = horizontal_player_alignment.get_point_position(x)
		# add other player card stacks to scene
		add_child(player_cards_struct[not_me[x]])
		
@rpc("any_peer", "call_local", "reliable", 0)
func PlayerSlapped():
	var called_by_player = multiplayer.get_remote_sender_id()


@rpc("any_peer", "call_local", "reliable", 0)
func PlayerPlayedCard():
	var called_by_player = multiplayer.get_remote_sender_id()
	player_cards_struct[called_by_player].top_card_to_other_stack(original_cards)
	original_cards.flip_card_at_top()
	
	
@rpc() # should only be called on clients from server
func SyncShuffle(order): # Server shuffles deck, this function is to send the new order of the deck to all clients
	#await ready
	var cards = []
	for card_info in order:
		for card in original_cards.get_children():
			if card.number == card_info[0] and card.suit == card_info[1]:
				cards.append(card)
				original_cards.remove_child(card)
				break
	# once the cards have been properly reordered, add them back into original_cards, aka the center cardstack
	for card in cards:
		original_cards.add_child(card)
	original_deck_shuffled.emit()
