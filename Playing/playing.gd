extends Node

@export var card_scene: PackedScene
const Enums = preload("res://CommonScripts/enums.gd")
const PlayerPositions = preload("res://CommonScripts/PlayerPositions.gd")
const TrumpRankings = preload("res://CommonScripts/TrumpRanking.gd")

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
var game_state = Enums.PHASES.BID_UP
var dealer_idx = 1
var leading_player_idx = (dealer_idx + 1)%4
var callingPlayer = -1
var Trump = Enums.Suits.SPADES
var cardsPlayed = [null, null, null, null] # array of cards played array of cards played
var tricksTaken = 0
var activePlayer_idx = -1
var _yourTricks = 0
var _theirTricks = 0

# Debugging methods
func _printDeck():
	print("Players Hand:")
	var format = "%s %s %s %s %s"
	var formatK = "%s %s %s %s"
	var i = 0
	print(format % [deck[i+0].toString(), deck[i+1].toString(), 
		deck[i+2].toString(), deck[i+3].toString(), deck[i+4].toString()])
	print("Players Partner:")
	i = 5
	print(format % [deck[i+0].toString(), deck[i+1].toString(), 
		deck[i+2].toString(), deck[i+3].toString(), deck[i+4].toString()])
	print("Players Left:")
	i = 10
	print(format % [deck[i+0].toString(), deck[i+1].toString(), 
		deck[i+2].toString(), deck[i+3].toString(), deck[i+4].toString()])
	print("Players Right:")
	i = 15
	print(format % [deck[i+0].toString(), deck[i+1].toString(), 
		deck[i+2].toString(), deck[i+3].toString(), deck[i+4].toString()])
	print("Kitty Cards:")
	i = 20
	print(formatK % [deck[i+0].toString(), deck[i+1].toString(), 
		deck[i+2].toString(), deck[i+3].toString()])

# Called when the node enters the scene tree for the first time.
func _ready():
	_build_deal()
	
	var start_idx = (dealer_idx + 1) % 4
	_simulate_to_player(start_idx)
func _deal_player_cards():
	# Set Dealer icon
	$MakeTrumpPhase1.set_dealer(dealer_idx)
	
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

func _pick_random_choice(force = false):
	var options = []
	var isDealer = callingPlayer == dealer_idx
	if game_state == Enums.PHASES.BID_UP:
		options = ["pass", "pickItUp"] # TODO Change to Enum
	if game_state == Enums.PHASES.BID_DOWN:
		options = ["spades", "hearts", "clubs", "diamonds"]
		if not isDealer:
			options.append_array(["pass","pass","pass","pass","pass","pass","pass","pass"])
	
	options.shuffle()
	if force and (not isDealer):
		options[0] = "pass"
	print(Enums.Players_toString[activePlayer_idx] + " chose " + options[0])
	return options[0]
# Simulate play until the players turn.
func _simulate_to_player(start_idx):
	if game_state == Enums.PHASES.BID_UP:
		var idx = start_idx
		while true:
			# End when we get to player
			if idx == Enums.Players.Player:
				callingPlayer = idx
				return
			# Otherwise pick something random
			var choice = _pick_random_choice(true)
			if choice == "pickItUp":
				game_state = Enums.PHASES.Discard
				callingPlayer =  idx
				_order_up_signal()
				return
			if idx == dealer_idx: # dealer has chose to pass
				print("dealer passed")
				_start_face_down_bidding()
				return
			idx = (idx + 1) % 4
	elif game_state == Enums.PHASES.BID_DOWN:
		var i = start_idx
		while true:
			# End when we get to player
			callingPlayer = i
			if i == Enums.Players.Player:
				return
			var choice = _pick_random_choice(true)
			if choice == "spades":
				$HintLabel.text = Enums.Players_toString[callingPlayer] +  " chose spades"
				_start_playing()
				return
			elif choice == "clubs":
				$HintLabel.text = Enums.Players_toString[callingPlayer] +  " chose clubs"
				_start_playing()
				return
			elif choice == "hearts":
				$HintLabel.text = Enums.Players_toString[callingPlayer] +  " chose hearts"
				_start_playing()
				return
			elif choice == "diamonds":
				$HintLabel.text = Enums.Players_toString[callingPlayer] +  " chose diamonds"
				_start_playing()
				return
			i = (i + 1)%4
	elif game_state == Enums.PHASES.PLAYING:
		var leading = cardsPlayed[0] == null and cardsPlayed[1] == null and cardsPlayed[2] == null and cardsPlayed[3] == null 
		if leading and activePlayer_idx == Enums.Players.Player:
			print("Players turn to lead")
		while activePlayer_idx != Enums.Players.Player and !_hand_finished():
			_pick_cpu_card(activePlayer_idx)
		_connect_player_hand_play()

func _hand_finished():
	return cardsPlayed[0] != null and cardsPlayed[1] != null and cardsPlayed[2] != null and cardsPlayed[3] != null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _swap_deck_cards(i, j):
	var tmp = deck[i]
	deck[i] = deck[j]
	deck[j] = tmp
func _start_face_down_bidding():
	game_state = Enums.PHASES.BID_UP
	var kitty_trump = deck[KITTY_IDX].suit
	$MakeTrumpPhase2.disable_suit(kitty_trump)
	deck[KITTY_IDX].flipDownCard()
	deck[KITTY_IDX].position = Vector2(1000,1000)
	$MakeTrumpPhase2.set_dealer(dealer_idx)
	activePlayer_idx = (dealer_idx + 1) % 4
	_simulate_to_player(activePlayer_idx)
	if game_state == Enums.PHASES.BID_UP:
		$MakeTrumpPhase1.visible = false
		$MakeTrumpPhase2.visible = true
		var isPlayerDealer = dealer_idx == Enums.Players.Player
		if isPlayerDealer:
			$MakeTrumpPhase2/Pass.disabled = true
func _get_player_hand_start_idx(player):
	var hand_low = 0
	if player == Enums.Players.Right:
		hand_low = 15
	elif player == Enums.Players.Left:
		hand_low = 10
	elif player == Enums.Players.Partner:
		hand_low = 5
	return hand_low
	

# Phase 1 signals
func _order_up_signal():
	Trump = deck[KITTY_IDX].suit
	$MakeTrumpPhase1.visible = false
	if dealer_idx == Enums.Players.Player:
		# Connect players cards for discard signal
		for i in range(5): # Players hand
			#deck[i].connect("discard", deck[i], _discard_signal)
			var card : StaticBody2D = deck[i]
			card.connect("discard", _discard_signal)
	else:
		var randy = randi() % 5
		var hand_low = _get_player_hand_start_idx(dealer_idx)
		randy += hand_low
		$HintLabel.text = Enums.Players_toString[callingPlayer] + " Ordered up " + deck[KITTY_IDX].toString()
		# Swap postions of the top kitty card and the random card
		deck[randy].position = Vector2(1000,1000)
		_swap_deck_cards(randy, KITTY_IDX)
		_deal_player_cards()
	
	
	$HintLabel.visible = true
func _pick_suit(suit):
	Trump = suit
	_simulate_to_player(0)
func _pass_signal():
	print("_pass_siganl")
	# get player index
	if Enums.Players.Player == dealer_idx: # player was dealer
		_start_face_down_bidding()
	else:
		activePlayer_idx = (activePlayer_idx + 1) % 4
		_simulate_to_player(activePlayer_idx)

# phase 2 signals
func phase2_make_trump(suit):
	Trump = suit
	game_state = Enums.PHASES.PLAYING
	$HintLabel.text = "Player made " + Enums.TO_STR_SUITS[suit]
	$HintLabel.visible = true
	$MakeTrumpPhase2.visible = false
	_start_playing()
func _spades_signal():
	phase2_make_trump(Enums.Suits.SPADES)
func _hearts_signal():
	phase2_make_trump(Enums.Suits.HEARTS)
func _diamonds_signal():
	phase2_make_trump(Enums.Suits.DIAMONDS)
func _clubs_signal():
	phase2_make_trump(Enums.Suits.CLUBS)
func _pass2_signal():
	_simulate_to_player((callingPlayer + 1) % 4)
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
	Trump = deck[KITTY_IDX].suit
	_swap_deck_cards(found, KITTY_IDX)
	_deal_player_cards()
	_start_playing()

# Playing signals
func _haveAllPlayed():
	for i in range(4):
		if cardsPlayed[i] == null:
			return false
	return true
func _start_playing():
	$HintLabel.visible = true
	game_state = Enums.PHASES.PLAYING
	$MakeTrumpPhase1.visible = false
	$MakeTrumpPhase2.visible = false
	_connect_player_hand_play()
	activePlayer_idx = (dealer_idx + 1) % 4
	_simulate_to_player(activePlayer_idx)

func _connect_player_hand_play(connect = true):
	for i in range(5):
		var player_card : StaticBody2D = deck[i]
		if connect:
			player_card.connect("play", _play_signal)
		else:
			player_card.disconnect("play", _play_signal)
func _play_signal(card):
	print("Play Recieved")
	var player = activePlayer_idx
	card.position = Vector2(
		PlayerPositions.PLAYED_CARD_POSITIONS[player][0],
		PlayerPositions.PLAYED_CARD_POSITIONS[player][1])
	card.rotation = PlayerPositions.PLAYED_CARD_POSITIONS[player][2]
	_connect_player_hand_play(false)
	cardsPlayed[activePlayer_idx] = card
	# Swap played card with the last card in that players hand.
	var start_idx = _get_player_hand_start_idx(player)
	var idx = deck.find(card)
	_swap_deck_cards(idx, start_idx+4) # 4 is the last card in players hand.
	if _haveAllPlayed():
		_eval_hand()
	if activePlayer_idx == Enums.Players.Player:
		activePlayer_idx = (activePlayer_idx + 1) % 4
		_simulate_to_player(activePlayer_idx)
	
func _pick_cpu_card(player):
	# Depends on the following variables to be set
	# * Trump leadCard dealerIdx cardsPlayed
	# TODO change from completely random to picked out of real options
	var randy = randi() % (5 - tricksTaken)
	var hand_idx = _get_player_hand_start_idx(player)
	hand_idx += randy
	var card = deck[hand_idx]
	print(Enums.Players_toString[player] + " chose " + card.toString())
	_play_signal(card)
	activePlayer_idx = (activePlayer_idx + 1) % 4
	
func _eval_hand():
	if cardsPlayed[0] == null:
		print("Error in _eval_hand")
		return
	if cardsPlayed[1] == null:
		print("Error in _eval_hand")
		return
	if cardsPlayed[2] == null:
		print("Error in _eval_hand")
		return
	if cardsPlayed[3] == null:
		print("Error in _eval_hand")
		return

	var card = cardsPlayed[0]
	var winningIdx = 0
	for i in range(1, 4):
		if(!_compare_two_cards(card, cardsPlayed[i])):
			card = cardsPlayed[i]
			winningIdx = i
			
	
	print("Winning card: " + card.toString())
	
	if(winningIdx == Enums.Players.Player or winningIdx == Enums.Players.Partner):
		_yourTricks += 1
		$YourTricks.text = ("Your Tricks: %d" % _yourTricks)
	else:
		_theirTricks += 1
		$TheirTricks.text = ("Theri Tricks: %d" % _theirTricks)
	
	leading_player_idx = winningIdx
	activePlayer_idx = winningIdx
	$FiveSecondTimer.start()

# return true if card1 wins, false if card2 wins
func _compare_two_cards(card1, card2):
	var leadingPlayer = leading_player_idx
	var leading_suit = cardsPlayed[leadingPlayer].suit
	print("comparing " + card1.toString() + " " + card2.toString())
	print("Trump: " + Enums.TO_STR_SUITS[Trump] + 
		" Leading Player: " + Enums.Players_toString[leadingPlayer] +
		" Leading Suit: " + Enums.TO_STR_SUITS[leading_suit])
	if _get_suit(Trump, card1) == Trump and _get_suit(Trump, card2) != Trump:
		return true
	elif  _get_suit(Trump, card1) != Trump and _get_suit(Trump, card2) == Trump:
		return false
	elif _get_suit(Trump, card1) == Trump and _get_suit(Trump, card2) == Trump:
		var idx1 = TrumpRankings.ALL_RANKINGS[Trump].find(card1.toString())
		var idx2 = TrumpRankings.ALL_RANKINGS[Trump].find(card2.toString())
		if idx1 > idx2:
			return true
		return false
	elif _get_suit(Trump, card1) != Trump and _get_suit(Trump, card2) != Trump:
		if card1.rank > card2.rank:
			return true
		return false
	return
	
# _get_suit takes into account jacks changing.
func _get_suit(CurrentTrump, card):
	if card.rank != Enums.Ranks.JACK:
		return card.suit
	elif Trump == Enums.Suits.SPADES and card.suit == Enums.Suits.CLUBS:
		return Enums.Suits.SPADES
	elif Trump == Enums.Suits.CLUBS and card.suit == Enums.Suits.SPADES:
		return Enums.Suits.CLUBS
	elif Trump == Enums.Suits.HEARTS and card.suit == Enums.Suits.DIAMONDS:
		return Enums.Suits.HEARTS
	elif Trump == Enums.Suits.DIAMONDS and card.suit == Enums.Suits.HEARTS:
		return Enums.Suits.DIAMONDS
	else:
		return card.suit

func remove_trick():
	for i in range(cardsPlayed.size()):
		cardsPlayed[i].position = Vector2(1000,1000)
		cardsPlayed[i] = null


func _on_five_second_timer_timeout():
	print("clean up hand and stuff")
	remove_trick()
	
	if (activePlayer_idx == Enums.Players.Player):
		$HintLabel.text = "Players Lead, choose any card"
		_connect_player_hand_play()
	else:
		$HintLabel.text = "%s won the trick and lead" %  [Enums.Players_toString[activePlayer_idx]]
		leading_player_idx = activePlayer_idx
		_simulate_to_player(activePlayer_idx)
	
