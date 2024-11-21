extends Node2D
var original_cards = load("res://card/CardStack.tscn").instantiate()
enum suits {spades, hearts, clubs, diamonds}
var player_cards_struct = {}
var players_turn = null # indicates which player's turn it is
var turn = -1 # the total number of turns, used to determine which player's turn it is
var cards_owed = 0 # number of cards that must be played if the player before has played a face card
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
	# Give server the first turn
	if multiplayer.is_server():
		NextTurn.rpc(0) # will always be same value at start, this is just for demonstration

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event: InputEvent) -> void: # use switch/match statement here, match on event is action pressed
	if(players_turn == multiplayer.get_unique_id() and event.is_action_pressed("click")):
		PlayerPlayedCard.rpc()
		if cards_owed == 0:
			NextTurn.rpc(turn+1)
	if(event.is_action_pressed("space")):
		var card_slapped_on = [original_cards.get_child(original_cards.get_child_count()-1).number,original_cards.get_child(original_cards.get_child_count()-1).suit]
		PlayerSlapped.rpc(card_slapped_on)

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

func CheckForSlapRules(card_slapped_on): # checks to see if player has a valid slap, if so they get the cards
	var check_stack = [] # temporary copy of the stack used to check if slap rules are matched
	var card_object
	var won_stack = false
	# this needs to happen in case another player plays a card and latency prevents a proper update
	# get index of card
	for card in original_cards.get_children():
		if card.number == card_slapped_on[0] and card.suit == card_slapped_on[1]:
			card_object = card
	# set check stack to a list of cards from index 0 to the index of the card object
	for x in range(original_cards.get_node(card_object.get_path()).get_index() + 1):
		check_stack.append(original_cards.get_child(x))
	if check_stack.size() > 1:
		#check for double
		if check_stack[check_stack.size()-1].number == check_stack[check_stack.size()-2].number: # check top two cards to see if they are the same number
			return true
	return false
			
@rpc("authority", "call_local","reliable")
func PlayerWonCards(player_collecting, card_slapped_on): # generates the list of cards to send a player from the main cardstack, sends on all players ends
	var won_stack = [] # stack that player will receive
	var card_object
	for card in original_cards.get_children():
		if card.number == card_slapped_on[0] and card.suit == card_slapped_on[1]:
			card_object = card
	# get the stack excluding any cards put down on top after player has slapped
	for x in range(original_cards.get_node(card_object.get_path()).get_index() + 1):
		won_stack.append(original_cards.get_child(x))
	print(player_collecting," has won the cards:", won_stack)
	# add cards to bottom of player stack and remove them from the central stack
	for card in won_stack:
		card.get_parent().remove_child(card) # remove from main stack
		# flip card back over
		card.face_down()
		# add to player stack
		player_cards_struct[player_collecting].add_to_bottom(card)
		
@rpc("any_peer", "call_local", "reliable", 0)
func PlayerSlapped(card_slapped_on):
	var called_by_player = multiplayer.get_remote_sender_id()
	print(called_by_player, " slapped on ", card_slapped_on)
	if multiplayer.is_server(): #if this is the server, check for slap rule matches
		# if a rule is matched, the player who slapped gets the cards
		if CheckForSlapRules(card_slapped_on):
			print("Valid Slap")
			PlayerWonCards.rpc(called_by_player,card_slapped_on)
		else:
			print("Invalid Slap")




@rpc("any_peer", "call_local", "reliable", 0)
func PlayerPlayedCard():
	var called_by_player = multiplayer.get_remote_sender_id()
	player_cards_struct[called_by_player].top_card_to_other_stack(original_cards)
	original_cards.flip_card_at_top()
	if cards_owed > 0:
		cards_owed = cards_owed - 1
	

	
	
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
	
	
@rpc("any_peer", "call_local", "reliable", 0)
func NextTurn(next_turn):
	turn = next_turn
	players_turn = get_parent().players[turn % player_cards_struct.size()]
	print("It is now ",players_turn,"'s turn")
	
		# if this is the server
	if multiplayer.is_server():
		var top_card = original_cards.get_child(original_cards.get_child_count() - 1)
		# check to see if last card played was a face card
		if top_card != null and top_card.number > 10:
			print("last card played: ", top_card)
			# call rpc on next player changing their card owed value
			match top_card.number:
				11:
					print("jack played")
					SetCardsOwed.rpc(1)
				12:
					print("queen played")
					SetCardsOwed.rpc(2)
				13:
					print("king played")
					SetCardsOwed.rpc(3)
				14:
					print("ace played")
					SetCardsOwed.rpc(4)

@rpc("authority", "call_local", "reliable")
func SetCardsOwed(number_owed):
	if players_turn == multiplayer.get_unique_id(): # if its your turn, set the cards owed value
		cards_owed = number_owed
