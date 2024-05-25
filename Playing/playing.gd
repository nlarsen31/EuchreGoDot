extends Node

@export var card_scene: PackedScene
const Enums = preload("res://CommonScripts/enums.gd")
const KITTY_IDX = 23
# Various parameters for hand positions for each player
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

var deck = [] # Deck of all cards in game detailed positons in _build_deal

# Game State Objects.
var game_state = Enums.GameState.FaceUpPickTrump
var playerOrder = [ # List of players starting with right of dealer
	Enums.Players.Right, # Right of dealer
	Enums.Players.Partner, # Second to make trump
	Enums.Players.Left, # third to make trump
	Enums.Players.Player] # Dealer
#var playerOrder = [ # List of players starting with right of dealer
	#Enums.Players.Partner, # Right of dealer
	#Enums.Players.Left, # Second to make trump
	#Enums.Players.Player, # third to make trump
	#Enums.Players.Right] # Dealer

var callingPlayer = -1
var Trump = Enums.Suits.SPADES

# Called when the node enters the scene tree for the first time.
func _ready():
	_build_deal()
	
	_simulate_to_player()
func _deal_player_cards():
	# Set Dealer icon
	$MakeTrumpPhase1.set_dealer(playerOrder[3])
	
	# Positions 0, 5 player
	for i in range(0, 5):
		deck[i].position = Vector2(playersHandPositions[0][i][0],
			playersHandPositions[0][i][1])
		deck[i].rotation = playerHandRotation[0]
		deck[i].visible = true
		
	# Positions 5, 10 partner
	for i in range(0, 5):
		deck[i+5].position = Vector2(playersHandPositions[1][i][0],
			playersHandPositions[1][i][1])
		deck[i+5].rotation = playerHandRotation[1]
		deck[i+5].visible = true
	
	# Positions 10, 15 left
	for i in range(0, 5):
		deck[i+10].position = Vector2(playersHandPositions[2][i][0],
			playersHandPositions[2][i][1])
		deck[i+10].rotation = playerHandRotation[2]
		deck[i+10].visible = true
		
	# Positions 15, 20 right
	for i in range(0, 5):
		deck[i+15].position = Vector2(playersHandPositions[3][i][0],
			playersHandPositions[3][i][1])
		deck[i+15].rotation = playerHandRotation[3]
		deck[i+15].visible = true
func _build_deal():
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
	_deal_player_cards()
	# cards 20,21,22,23 are the kitty 23 is face up on top.
	deck[23].position = KittyLocation
	deck[23].visible = true
	deck[23].flipUpCard()
	deck[23].printCard()
	deck[22].position = Vector2(1000,1000)
	deck[22].visible = true
	deck[22].flipUpCard()
	
	deck[21].position = Vector2(1000,1000)
	deck[21].visible = true
	deck[21].flipUpCard()

	deck[20].position = Vector2(1000,1000)
	deck[20].visible = true
	deck[20].flipUpCard()

func _pick_random_choice():
	var options = []
	if game_state == Enums.GameState.FaceUpPickTrump:
		options = ["pass", "pickItUp"] # TODO Change to Enum
	
	options.shuffle()
	#return options[0]
	return "pass"
	#return "pickItUp"
# Simulate play until the players turn.
func _simulate_to_player():
	if game_state == Enums.GameState.FaceUpPickTrump:
		for i in range(4):
			# End when we get to player
			if playerOrder[i] == Enums.Players.Player:
				callingPlayer = playerOrder[i]
				return
			# Otherwise pick something random
			var choice = _pick_random_choice()
			if choice == "pickItUp":
				game_state = Enums.GameState.Discard
				callingPlayer =  playerOrder[i]
				_order_up_signal()
				return

	if game_state == Enums.GameState.FaceDownPickTrump:
		print("simulate to player, or all past dealer.")
	if game_state == Enums.GameState.Playing:
		print("simulate to player")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _swap_deck_cards(i, j):
	var tmp = deck[i]
	deck[i] = deck[j]
	deck[j] = tmp

func _order_up_signal():
	Trump = deck[KITTY_IDX].suit
	$MakeTrumpPhase1.visible = false
	var dealer = playerOrder[3]
	if dealer == Enums.Players.Player:
		# Connect players cards for discard signal
		for i in range(5): # Players hand
			#deck[i].connect("discard", deck[i], _discard_signal)
			var card : StaticBody2D = deck[i]
			card.connect("discard", _discard_signal)
	else:
		var randy = randi() % 5
		var hand_low = 0
		if dealer == Enums.Players.Right:
			hand_low = 16
		elif dealer == Enums.Players.Left:
			hand_low = 11
		elif dealer == Enums.Players.Partner:
			hand_low = 6
		randy += hand_low
		# Swap postions of the top kitty card and the random card
		deck[randy].position = Vector2(1000,1000)
		_swap_deck_cards(randy, KITTY_IDX)
		_deal_player_cards()
		$HintLabel.text = "Your Lead!"
	
	
	$HintLabel.visible = true

func _pass_signal():
	print("_pass_siganl")

func _discard_signal(card):
	# disconnect signals to players cards
	for i in range(5): # Players hand
		#deck[i].connect("discard", deck[i], _discard_signal)
		var player_card : StaticBody2D = deck[i]
		player_card.disconnect("discard", _discard_signal)
	# find card in players hand
	var found = -1
	for i in range(0, 5):
		if deck[i].toString() == card.toString():
			found = i
	deck[found].position = Vector2(1000,1000)
	_swap_deck_cards(found, KITTY_IDX)
	_deal_player_cards()

