extends Node

const Enums = preload("res://CommonScripts/enums.gd")

var playerHandRotation = [
	0.0,
	0.0,
	PI/2,
	PI/2
]
var playersHandPositions = [
	[
		[337, 562],
		[432, 562],
		[527, 562],
		[623, 562],
		[717, 562]
	],
	[
		[337, 84],
		[432, 84],
		[527, 84],
		[623, 84],
		[717, 84]
	],
	[
		[92, 165],
		[92, 260],
		[92, 354],
		[92, 448],
		[92, 542]
	],
	[
		[1055, 165],
		[1055, 260],
		[1055, 354],
		[1055, 448],
		[1055, 542]
	]
]
var KittyLocation = Vector2(557, 303)

@export var card_scene: PackedScene

var deck = []
# Called when the node enters the scene tree for the first time.
func _ready():
	# Make array that is a deck of cards
	for i in range(6):
		for suit in range(4):
			var card = card_scene.instantiate()
			card.suit = suit
			card.rank = i
			card.flipUpCard()
			card.visible = false
			deck.append(card)
			add_child(card)
	
	deck.shuffle()
	
	# Positions 0, 5 player 1
	for i in range(0, 5):
		deck[i].position = Vector2(playersHandPositions[0][i][0],
			playersHandPositions[0][i][1])
		deck[i].rotation = playerHandRotation[0]
		deck[i].visible = true
		
	# Positions 5, 10 player 2
	for i in range(0, 5):
		deck[i+5].position = Vector2(playersHandPositions[1][i][0],
			playersHandPositions[1][i][1])
		deck[i+5].rotation = playerHandRotation[1]
		deck[i+5].visible = true
	
	# Positions 10, 15 player 3
	for i in range(0, 5):
		deck[i+10].position = Vector2(playersHandPositions[2][i][0],
			playersHandPositions[2][i][1])
		deck[i+10].rotation = playerHandRotation[2]
		deck[i+10].visible = true
		
	# Positions 15, 20 player 3
	for i in range(0, 5):
		deck[i+15].position = Vector2(playersHandPositions[3][i][0],
			playersHandPositions[3][i][1])
		deck[i+15].rotation = playerHandRotation[3]
		deck[i+15].visible = true
		
	# cards 20,21,22,23 are the kitty 23 is face up on top.
	deck[23].position = KittyLocation
	deck[23].visible = true
	deck[23].flipUpCard()
	
	deck[22].position = KittyLocation
	deck[22].visible = true
	deck[22].flipUpCard()
	
	deck[21].position = KittyLocation
	deck[21].visible = true
	deck[21].flipUpCard()

	deck[20].position = KittyLocation
	deck[20].visible = true
	deck[20].flipUpCard()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
