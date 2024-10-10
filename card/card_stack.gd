extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func add_to_bottom(card): # Change later, this is just to demo that cards are working properly
	if self.get_child_count() > 0:
		var new_position = (self.get_child(get_child_count()-1)).position + Vector2(30,0)
		card.position = new_position
	else:
		card.position = Vector2(30,0)
	add_child(card)
	#remove me
	print(card.suit," ", card.number)
	await card.ready
	card.show_card()
