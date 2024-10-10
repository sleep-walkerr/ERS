extends Sprite2D

enum suits {spade, heart, club, diamond}
var face_up = false
var number = null
var suit = null
var card_front_texture = null
var card_back_texture = load("res://svg_playing_cards/backs/red2.svg")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_texture(card_back_texture)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func show_card():
	self.texture = card_front_texture
	face_up = true
