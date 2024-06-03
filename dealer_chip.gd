extends Node2D

const Enums = preload("res://CommonScripts/enums.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_sprite(sprite):
	if sprite == "dealer":
		$AnimatedSprite2D.animation = "dealer"

func set_sprite_suit(suit):
	var suit_str = Enums.TO_STR_SUITS[suit]
	$AnimatedSprite2D.animation = "made_it_" + suit_str
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
