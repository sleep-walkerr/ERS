extends Control
var original_cards
enum suits {spades, hearts, clubs, diamonds}
var player_cards_struct = {}
var players_turn = null # indicates which player's turn it is
var turn = -1 # the total number of turns, used to determine which player's turn it is
var cards_owed = -1 # number of cards that must be played if the player before has played a face card, -1 means no face card played
var cards_owed_to = null
var face_card_victim = null
signal original_deck_shuffled # emitted when original cards are created and ready to be shuffled

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# populate other player identifier struct
	for player in get_parent().players:
		get_parent().players_by_id[get_parent().players[player]] = player
	original_cards = $CenterContainer/original_cards
	# Create deck and add to scene
	create_cards()
	# Create player cardstacks and distribute cards
	if !multiplayer.is_server():
		await original_deck_shuffled
	prepare_player_cardstacks()
	# Give server the first turn
	if multiplayer.is_server():
		NextTurn.rpc(0) # will always be same value at start, this is just for demonstration
	# update card amounts
	SetCardCountIndicators()
	# change playerlabel to reflect which player you are
	$HBoxContainer/PlayerLabel.text = str("Player ",get_parent().players_by_id[multiplayer.get_unique_id()]+1)
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void: # fix this later
	for player in player_cards_struct:
		player_cards_struct[player].position_cards()
		if player != players_turn: # if it isn't the players turn, change the color of their deck
			player_cards_struct[player].modulate = Color(0.0, 1.0, 1.0)
		else: player_cards_struct[player].modulate = Color(1.0, 1.0, 1.0)
	original_cards.position_cards()
	if original_cards.get_child_count() < 1:
		$HBoxContainer/HBoxContainer/SlapButton.visible = false
	else: $HBoxContainer/HBoxContainer/SlapButton.visible = true
	if players_turn != multiplayer.get_unique_id():
		$HBoxContainer/HBoxContainer/PlayButton.visible = false
	else: $HBoxContainer/HBoxContainer/PlayButton.visible = true


func _input(event: InputEvent) -> void: # use switch/match statement here, match on event is action pressed
	if(players_turn == multiplayer.get_unique_id() and event.is_action_pressed("click")):
		if cards_owed_to == null:
			PlayerPlayedCard.rpc()	
		elif cards_owed_to != null:
			PlayedCardDuringCardDebt.rpc() # run separate function for when a player is paying their card debt
	if(event.is_action_pressed("space") and not original_cards.get_child_count() < 1):
		var card_slapped_on = [original_cards.get_child(original_cards.get_child_count()-1).number,original_cards.get_child(original_cards.get_child_count()-1).suit]
		PlayerSlapped.rpc(card_slapped_on)
	#if event.is_action_pressed("Escape"):
		#PlayerLeft.rpc(1,multiplayer.get_unique_id())
		#
		#get_parent().multiplayer.multiplayer_peer = null
		#get_parent().SwitchInterface("MainMenu") 
		
@rpc("any_peer", "call_local", "reliable", 0)
func PlayerLeft(player_id):
	player_cards_struct.erase(multiplayer.get_unique_id())
	UpdatePlayerCardsStruct.rpc(player_cards_struct)
	
@rpc("authority","call_local","reliable",0)
func UpdatePlayerCardsStruct(new_struct):
	player_cards_struct = new_struct

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
			original_cards.add_to_top(next_card)
			
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
	for x in range(get_parent().players.size()):
		player_cards_struct[get_parent().players[x]] = $PlayerCardStacksContainer.get_child(x).get_child(0)
		$PlayerCardStacksContainer.get_child(x).visible = true

	# For each cardstack, add 1 card until all cards from deck are gone
	var current_index = 0 # iterator used to determine which cardstack to send to next
	for card in original_cards.get_children():
		original_cards.top_card_to_other_stack(player_cards_struct[get_parent().players[current_index % player_cards_struct.size()]])
		current_index = current_index + 1
	
func SetCardCountIndicators() -> void:
	$PlayerCardStacksContainer/VBoxContainer/HBoxContainer/CardCount.text = str($PlayerCardStacksContainer/VBoxContainer/Player1.get_child_count())
	$PlayerCardStacksContainer/VBoxContainer2/HBoxContainer/CardCount.text = str($PlayerCardStacksContainer/VBoxContainer2/Player2.get_child_count())
	$PlayerCardStacksContainer/VBoxContainer3/HBoxContainer/CardCount.text = str($PlayerCardStacksContainer/VBoxContainer3/Player3.get_child_count())
	$PlayerCardStacksContainer/VBoxContainer4/HBoxContainer/CardCount.text = str($PlayerCardStacksContainer/VBoxContainer4/Player4.get_child_count())
	
		
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
			print("slap rule: double matched")
			return true
		#check for sandwhich
		elif check_stack[check_stack.size()-1].number == check_stack[check_stack.size()-3].number and check_stack[check_stack.size()-1].suit != check_stack[check_stack.size()-3].suit: # godot handles negative indicies by replacing them with 0
			print(check_stack[check_stack.size()-1],check_stack[check_stack.size()-3])
			print("slap rule: sandwhich matched")
			return true
		# check for top bottom rule
		elif check_stack[0].number == check_stack[check_stack.size()-1].number:
			print("slap rule: top bottom matched")
			return true
		# tens rule, ace will not work properly here for now
		elif check_stack[check_stack.size()-1].number + check_stack[check_stack.size()-2].number == 10 or check_stack[check_stack.size()-1].number + check_stack[check_stack.size()-3].number == 10 and check_stack[check_stack.size()-2].number > 10:
			print("slap rule: tens matched")
			return true
		# four in a row
		elif check_stack[check_stack.size()-4].number == check_stack[check_stack.size()-1].number - 3 and check_stack[check_stack.size()-3].number == check_stack[check_stack.size()-1].number - 2 and check_stack[check_stack.size()-2].number == check_stack[check_stack.size()-1].number - 1:
			print("slap rule: four in a ROW matched")
			return true
		# four in a row descending
		elif check_stack[check_stack.size()-4].number == check_stack[check_stack.size()-1].number + 3 and check_stack[check_stack.size()-3].number == check_stack[check_stack.size()-1].number + 2 and check_stack[check_stack.size()-2].number == check_stack[check_stack.size()-1].number + 1:
			print("slap rule: four in a ROW matched")
			return true
		# marriage
		elif check_stack[check_stack.size()-1].number == 12 and check_stack[check_stack.size()-2].number == 13 or check_stack[check_stack.size()-1].number == 13 and check_stack[check_stack.size()-2].number == 12:
			print("slap rule: marriage matched")
			return true
	return false
			
@rpc("any_peer", "call_local","reliable")
func PlayerWonCards(player_collecting, card_slapped_on): # generates the list of cards to send a player from the main cardstack, sends on all players ends
	var won_stack = [] # stack that player will receive
	var card_object
	while card_object == null: # this is a bandaid fix, get confirmation that all players have received the change in the future
		for card in original_cards.get_children():
			if card.number == card_slapped_on[0] and card.suit == card_slapped_on[1]:
				card_object = card
	# get the stack excluding any cards put down on top after player has slapped
	for x in range(original_cards.get_node(card_object.get_path()).get_index() + 1):
		won_stack.append(original_cards.get_child(x))
	print(player_collecting," has won the cards:", won_stack)
	# add cards to bottom of player stack and remove them from the central stack
	#await get_tree().create_timer(1).timeout
	for card in won_stack:
		card.get_parent().remove_child(card) # remove from main stack
		# flip card back over
		card.face_down()
		# add to player stack
		player_cards_struct[player_collecting].add_to_top(card)
	SetCardCountIndicators()
		
@rpc("any_peer", "call_local", "reliable", 0)
func PlayerSlapped(card_slapped_on):
	var called_by_player = multiplayer.get_remote_sender_id()
	print(called_by_player, " slapped on ", card_slapped_on)
	if multiplayer.is_server(): #if this is the server, check for slap rule matches
		# if a rule is matched, the player who slapped gets the cards
		if CheckForSlapRules(card_slapped_on):
			print("Valid Slap")
			PlayerWonCards.rpc(called_by_player,card_slapped_on)
			ExitFaceCardDebtPhase.rpc()
		else:
			print("Invalid Slap")
			# penalize the player here
			InvalidSlapOccurred.rpc(called_by_player)
			# check for a winner
			CheckForWinner()
			
@rpc("authority", "call_local", "reliable")
func InvalidSlapOccurred(player_who_slapped):
	player_cards_struct[player_who_slapped].send_card_for_penalty(original_cards)
	SetCardCountIndicators()
	
	

func CheckForWinner():
	var still_alive_count = 0
	var last_player_still_alive = null
	# check if only one player has the cards
	for player in player_cards_struct:
		if player_cards_struct[player].get_child_count() > 0:
			still_alive_count = still_alive_count + 1
			last_player_still_alive = player
	print(still_alive_count, last_player_still_alive)
	if still_alive_count == 1 and last_player_still_alive != null:
		PlayerWon.rpc(last_player_still_alive)
	
@rpc("authority", "call_local", "reliable")
func PlayerWon(winning_player):
	for child in get_children():
		child.visible = false
		$WinIndicator.text = str(get_parent().players_by_id[winning_player], " has Won!")
	$WinIndicator.visible = true
	print("Player ",winning_player," has won!")
	await get_tree().create_timer(10).timeout
	get_parent().multiplayer.multiplayer_peer = null
	get_parent().SwitchInterface("MainMenu")  
	

@rpc("any_peer", "call_local", "reliable", 0)
func PlayerPlayedCard():
	var called_by_player = multiplayer.get_remote_sender_id()
	player_cards_struct[called_by_player].top_card_to_other_stack(original_cards)
	original_cards.flip_card_at_top()
	SetCardCountIndicators()
	if multiplayer.is_server():
		if cards_owed_to == null and !CheckForFaceCard(called_by_player): # regular non-face card turn
			NextTurn.rpc(turn+1)
			CheckForWinner()
			
@rpc("any_peer","call_local","reliable",0) # this needs to be changed to only be called on the server via rpc multiplayer id
func PlayedCardDuringCardDebt(): # version of player played card for when a player is playing their cards owed for a face card
	var called_by_player = multiplayer.get_remote_sender_id()
	if multiplayer.is_server():
		UpdateClientsCardStacks.rpc()

	
	if multiplayer.is_server(): # if you are the server
		if CheckForFaceCard(called_by_player): # if player plays a face card during face card debt phase, should exit and displace phase to next player
			CheckForWinner()
			return
		elif cards_owed == 0: 
			# player who played face card wins cards
			var top_card = [original_cards.get_child(original_cards.get_child_count()-1).number,original_cards.get_child(original_cards.get_child_count()-1).suit]
			#--this is necessary in case another player plays a card before the cards are collected, ensures that winner only gets the cards they are supposed to
			await get_tree().create_timer(2).timeout
			PlayerWonCards.rpc(cards_owed_to,top_card)
			ExitFaceCardDebtPhase.rpc()
			NextTurn.rpc(turn+1)
			CheckForWinner()
			
@rpc("authority", "call_local", "reliable")
func UpdateClientsCardStacks(): # this is for face card turns, seperates card stack updating to use await to prevent race condition
	print("In a card debt turn...") # race condition is a symptom of a missing synchronization system, for next implementation
	var called_by_player = multiplayer.get_remote_sender_id()
	player_cards_struct[face_card_victim].top_card_to_other_stack(original_cards)
	original_cards.flip_card_at_top()
	SetCardCountIndicators()
	cards_owed = cards_owed - 1
	
	
func CheckForFaceCard(called_by_player):
	var top_card = original_cards.get_child(original_cards.get_child_count() - 1)
	# check to see if last card played was a face card
	if top_card != null and top_card.number > 10:
		print("last card played: ", top_card)
		# call next turn and then use the new player value to assign owed cards
		match top_card.number:
			11:
				print("jack played")
				ExitFaceCardDebtPhase.rpc()
				cards_owed_to = players_turn
				NextTurn.rpc(turn+1)
				SetCardsOwed.rpc(1, cards_owed_to)
				return true
			12:
				print("queen played")
				ExitFaceCardDebtPhase.rpc()
				cards_owed_to = players_turn
				NextTurn.rpc(turn+1)
				SetCardsOwed.rpc(2, cards_owed_to)
				return true
			13:
				print("king played")
				ExitFaceCardDebtPhase.rpc()
				cards_owed_to = players_turn
				NextTurn.rpc(turn+1)
				SetCardsOwed.rpc(3, cards_owed_to)
				return true
			14:
				print("ace played")
				ExitFaceCardDebtPhase.rpc()
				cards_owed_to = players_turn
				NextTurn.rpc(turn+1)
				SetCardsOwed.rpc(4, cards_owed_to)	
				return true
	return false

	
	
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
func NextTurn(next_turn): # moves to the next turn for all players, unless only one player has the cards
	turn = next_turn
	players_turn = get_parent().players[turn % player_cards_struct.size()]
	print("It is now ",players_turn,"'s turn")
	

@rpc("authority", "call_local", "reliable")
func SetCardsOwed(number_owed, owed_to):
	cards_owed_to = owed_to
	cards_owed = number_owed
	face_card_victim = players_turn

	
@rpc("authority", "call_local", "reliable")
func ExitFaceCardDebtPhase():
	cards_owed_to = null
	cards_owed = -1
	face_card_victim = null
