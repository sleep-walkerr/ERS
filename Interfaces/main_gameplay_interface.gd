extends Node2D
var original_cards = load("res://card/CardStack.tscn").instantiate()
enum suits {spades, hearts, clubs, diamonds}
var player_count = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create deck and add to scene
	create_cards()
	original_cards.position = self.get_viewport_rect().size / Vector2(2,2)
	self.add_child(original_cards)
	# Create player cardstacks and distribute cards
	prepare_player_cardstacks()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

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
			
func prepare_player_cardstacks() -> void: # try loading once and using that one variable to instantiate all of them, better coding practice
	# Create card stacks for each player
	#--Setting player count to four for example
	player_count = 4
	# Create player cardstacks
	var player1_cardstack = load("res://card/CardStack.tscn").instantiate()
	player1_cardstack.name = "player1_cardstack"
	var player2_cardstack = load("res://card/CardStack.tscn").instantiate()
	var player3_cardstack = load("res://card/CardStack.tscn").instantiate()
	var player4_cardstack = load("res://card/CardStack.tscn").instantiate()
	# Add each cardstack to a list
	var player_stacks = [player1_cardstack, player2_cardstack, player3_cardstack, player4_cardstack] 
	# For each cardstack, add 1 card until all cards from deck are gone
	var current_index = 0 # iterator used to determine which cardstack to send to next
	for card in original_cards.get_children():
		original_cards.top_card_to_other_stack(player_stacks[current_index % 4])
		current_index = current_index + 1
	# Position stacks
	#--For now just quarter screen and add static positions for each player, will change when multiplayer is implemented
	var viewport_x = get_viewport_rect().size.x
	var viewport_y = get_viewport_rect().size.y
	# Clockwise starting from 6 
	player1_cardstack.position = Vector2(viewport_x / 2, (viewport_y - (viewport_y / 4)))
	player2_cardstack.position = Vector2(viewport_x / 4, viewport_y / 2)
	player2_cardstack.rotation_degrees = 90
	player3_cardstack.position = Vector2(viewport_x / 2, viewport_y / 4)
	player4_cardstack.position = Vector2(viewport_x - (viewport_x / 4), viewport_y / 2)
	player4_cardstack.rotation_degrees = -90
	#player3_cardstack.position = Vector2()
	# Add cards to tree
	for cardstack in player_stacks:
		self.add_child(cardstack)
