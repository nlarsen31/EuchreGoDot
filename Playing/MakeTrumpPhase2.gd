extends Control

signal spades_signal
signal clubs_signal
signal diamonds_signal
signal hearts_signal
signal pass_signal

const Enums = preload("res://CommonScripts/enums.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func disable_suit(suit):
	if suit == Enums.Suits.SPADES:
		$Spades.disabled = true
	if suit == Enums.Suits.HEARTS:
		$Hearts.disabled = true
	if suit == Enums.Suits.DIAMONDS:
		$Diamonds.disabled = true
	if suit == Enums.Suits.CLUBS:
		$Clubs.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_spades_pressed():
	spades_signal.emit()

func _on_hearts_pressed():
	hearts_signal.emit()

func _on_diamonds_pressed():
	diamonds_signal.emit()

func _on_clubs_pressed():
	clubs_signal.emit()

func _on_pass_pressed():
	pass_signal.emit()
