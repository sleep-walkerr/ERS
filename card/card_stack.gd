extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_to_bottom(card): # Change later, this is just to demo that cards are working properly
	if self.get_child_count() > 0:
		var new_position = (self.get_child(get_child_count()-1)).position + Vector2(0.5,0)
		card.position = new_position
	else:
		card.position = Vector2(0.5,0)
	add_child(card)
	
func top_card_to_other_stack(destination_cardstack) -> void: # Sends the top card to another cardstack. **animation will be done here later
	var card_to_send = self.get_child(0)
	remove_child(card_to_send)
	destination_cardstack.add_to_bottom(card_to_send)
	


func shuffle() -> void:
	pass
