extends Node

@export var card_scene: PackedScene
var _playing_scene = load("res://playing_better.tscn")
# Called when the node enters the scene tree for the first time.
func _ready():
	print("Enter _ready")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_play_pressed():
	Global.debugging = false
	get_tree().change_scene_to_file("res://playing_better.tscn")



func _on_play_debug_pressed():
	Global.debugging = true
	get_tree().change_scene_to_file("res://playing_better.tscn")
