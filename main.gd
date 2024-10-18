extends Node2D
var current_interface

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_interface = load("res://Interfaces/MainMenu.tscn").instantiate()
	self.add_child(current_interface)
	#current_interface.get_node("JoinButton").pressed.connect(Callable(SwitchInterface).bind("JoinMenu")) # This needs to be moved to a script for the join interface scene


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func SwitchInterface(next_interface) -> void: # Switch to Another Interface
	# If next interface exists
	if ResourceLoader.exists(str("res://Interfaces/", next_interface, ".tscn")):
		#--Delete previous interface
		current_interface.queue_free()
		#--Load next interface
		current_interface = load(str("res://Interfaces/", next_interface, ".tscn")).instantiate()
		#--Place interface in main scene
		self.add_child(current_interface)
