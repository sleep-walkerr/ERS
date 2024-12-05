extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_to_top(card): # Change later, this is just to demo that cards are working properly
	add_child(card)
	position_cards()
	
func add_to_bottom(card):
	add_child(card)
	move_child(card,0)
	position_cards()
	
func position_cards() -> void:
	var spacer = Vector2(0,0)
	for each_card in get_children():
		each_card.position = spacer + size / 2
		spacer = spacer + Vector2(0.2,0)
	
func top_card_to_other_stack(destination_cardstack) -> void: # Sends the top card to another cardstack. **animation will be done here later
	var card_to_send = self.get_child(0)
	remove_child(card_to_send)
	destination_cardstack.add_to_top(card_to_send)
	
func send_card_for_penalty(destination_cardstack) -> void:
	var card_to_send = self.get_child(0)
	card_to_send.face_down()
	remove_child(card_to_send)
	destination_cardstack.add_to_bottom(card_to_send)
	
func flip_card_at_top() -> void:
	get_child(get_child_count() -1).show_card()


func shuffle() -> void:
	var cards = [] # shuffle function only exists for arrays/lists
	for card in self.get_children(): # for each card in stack, add card to array, then remove it from self
		cards.append(card)
		self.remove_child(card)
	# randomize the order of the cards using builtin shuffle fxn
	cards.shuffle()
	for card in cards:
		self.add_child(card)
		
	
