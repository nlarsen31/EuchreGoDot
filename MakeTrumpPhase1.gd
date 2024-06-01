extends Control

signal OrderUp
signal Pass

const Enums = preload("res://CommonScripts/enums.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_dealer(dealer):
	$DealerIndicator.set_dealer(dealer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_order_up_pressed():
	OrderUp.emit()

func _on_pass_pressed():
	Pass.emit()
