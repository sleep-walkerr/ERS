extends Node2D
var original_cards = load("res://card/CardStack.tscn").instantiate()
enum suits {spades, hearts, clubs, diamonds}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	create_cards()
	original_cards.position = Vector2(300,300)
	self.add_child(original_cards)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func create_cards() -> void: #test function for creating a sample deck to show off features so far
	for suit in suits:
		for card_number in range(2,15):
			var next_card = load("res://card/Card.tscn").instantiate() #create next card to add
			#assign number, suit, and front texture
			next_card.number = card_number
			next_card.suit = suit
			next_card.card_front_texture = load("res://svg_playing_cards/fronts/"+str(suit)+"_"+str(card_number)+".svg")
			#add to original deck var
			original_cards.add_to_bottom(next_card)
