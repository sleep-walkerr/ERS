extends Node2D
@onready var animation_timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$clubs.card_front_texture = load("res://svg_playing_cards/fronts/clubs_2.svg")
	$clubs.show_card()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func flip_left(): # Flipping card to face down using a left flip animation
	# animation points where texture needs to change
	var final_skew = 1.56904995441437 * 2
	var final_rotation = -final_skew

	# first half of animation
	animation_timer.start(1) # 1 second time, the duration of the first half
	while animation_timer.time_left:
		await get_tree().process_frame # this prevents changes until the last frame has completed
		
		# this is purely for demonstration
		var total_animation_time = 1
		var time_elapsed = total_animation_time - animation_timer.time_left
		var new_animation_progress = time_elapsed / 1
		var new_skew = new_animation_progress * final_skew
		
		# By manipulating skew and rotation, a fake 3D left/right flip animation can be made
		#--Check to see if texture needs to be changed yet
		if new_skew > 1.56904995441437 and $clubs.face_up:
			$clubs.texture = $clubs.card_back_texture
			$clubs.face_up = false
			
		#--Change skew and rotation
		$clubs.skew = new_skew
		$clubs.rotation = -new_skew
		


func _on_button_pressed() -> void:
	flip_left()


func _on_reset_pressed() -> void:
	$clubs.skew = 0
	$clubs.rotation = 0
	$clubs.show_card()
