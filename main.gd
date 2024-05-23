extends Node

@export var card_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Enter _ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	get_tree().change_scene_to_file("res://Playing/playing.tscn")

