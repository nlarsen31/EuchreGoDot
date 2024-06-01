extends Node2D

# External Scripts
const Enums = preload("res://CommonScripts/enums.gd")
const PlayerPositions = preload("res://CommonScripts/PlayerPositions.gd")
const TrumpRankings = preload("res://CommonScripts/TrumpRanking.gd")
@export var card_scene: PackedScene

# State Properties
var _active_player = -1
var _player_called = -1
var _dealer = Enums.PLAYERS.Left
var _lead_player = -1
var _played_cards = [null, null, null, null]
var _played_card_count = 0
var _game_phase = Enums.PHASES.BID_UP
var _dealt = false
var _deck = []
var _players_hands = [
	[null, null, null, null, null],
	[null, null, null, null, null],
	[null, null, null, null, null],
	[null, null, null, null, null]
]
var _trump = -1

# Common Util functions
func _hand_eval():
	print("hand_eval")

func _next_player(player):
	return (player + 1) % 4
	
func _connect_player_hand_play(connect_str, play_or_discard, connect = true):
	for i in range(5):
		var player_card : StaticBody2D = _players_hands[Enums.PLAYERS.Player][i]
		if connect:
			player_card.connect(connect_str, play_or_discard)
		else:
			player_card.disconnect(connect_str, play_or_discard)

func _remove_bid_ui():
	$MakeTrumpPhase1.visible = false
	$MakeTrumpPhase2.visible = false

# Called when the node enters the scene tree for the first time.
func _ready():
	_active_player = _dealer
	$MakeTrumpPhase1/Pass.visible = false
	$"MakeTrumpPhase1/Order UP".visible = false
	
	_play_turn()

func _build_deck():
	for i in range(6):
		for suit in range(4):
			var card = card_scene.instantiate()
			card.suit = suit
			card.rank = i
			card.flipUpCard()
			card.visible = false
			_deck.append(card)
			add_child(card)

func _play_turn():
	if not _dealt:
		deal()
	elif _active_player != Enums.PLAYERS.Player:
		_cpu_turn()
	elif _active_player == Enums.PLAYERS.Player:
		_player_turn()

func deal():
	_build_deck()
	_deck.shuffle()
	# Positions 0, 5 Right
	for i in range(0, 5):
		_deck[i].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[0][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[0][i][1])
		_deck[i].rotation = PlayerPositions.PLAYER_HAND_ROTATION[0]
		_deck[i].visible = true
		_players_hands[Enums.PLAYERS.Right][i] = _deck[i]
		
	# Positions 5, 10 Partner
	for i in range(0, 5):
		_deck[i+5].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[1][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[1][i][1])
		_deck[i+5].rotation = PlayerPositions.PLAYER_HAND_ROTATION[1]
		_deck[i+5].visible = true
		_players_hands[Enums.PLAYERS.Partner][i] = _deck[i+5]
	
	# Positions 10, 15 Left
	for i in range(0, 5):
		_deck[i+10].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[2][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[2][i][1])
		_deck[i+10].rotation = PlayerPositions.PLAYER_HAND_ROTATION[2]
		_deck[i+10].visible = true
		_players_hands[Enums.PLAYERS.Left][i] = _deck[i+10]
		
	# Positions 15, 20 player
	for i in range(0, 5):
		_deck[i+15].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[3][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[3][i][1])
		_deck[i+15].rotation = PlayerPositions.PLAYER_HAND_ROTATION[3]
		_deck[i+15].visible = true
		_players_hands[Enums.PLAYERS.Player][i] = _deck[i+15]

	# cards 20,21,22,23 are the kitty 23 is face up on top.
	_deck[23].position = PlayerPositions.KittyLocation
	_deck[23].visible = true
	_deck[23].flipUpCard()
	_deck[23].printCard()
	_deck[22].position = Vector2(1000,1000)
	_deck[22].visible = true
	_deck[22].flipUpCard()
	
	_deck[21].position = Vector2(1000,1000)
	_deck[21].visible = true
	_deck[21].flipUpCard()

	_deck[20].position = Vector2(1000,1000)
	_deck[20].visible = true
	_deck[20].flipUpCard()
	
	# Set States
	$HintLabel.text = str(_deck[23]) + " was turned up"
	_active_player = _next_player(_dealer)
	_dealt = true
	_game_phase = Enums.PHASES.BID_UP
	if _active_player != Enums.PLAYERS.Player:
		$MakeTrumpPhase1/Pass.visible = false
		$"MakeTrumpPhase1/Order UP".visible = false
	$MakeTrumpPhase1.set_dealer(_dealer)
	$MakeTrumpPhase2.set_dealer(_dealer)
	$Timer.start()

func _player_pass():
	$HintLabel.text = Enums.Players_toString[_active_player] + " passed"
	if _game_phase == Enums.PHASES.BID_UP:
		$MakeTrumpPhase1/Pass.visible = false
		$"MakeTrumpPhase1/Order UP".visible = false
		if _active_player == _dealer:
			_game_phase = Enums.PHASES.BID_DOWN
			$MakeTrumpPhase1.visible = false
			$MakeTrumpPhase2.visible = true
			$MakeTrumpPhase2/Clubs.visible = false
			$MakeTrumpPhase2/Hearts.visible = false
			$MakeTrumpPhase2/Diamonds.visible = false
			$MakeTrumpPhase2/Spades.visible = false
			$MakeTrumpPhase2/Pass.visible = false
			_deck[23].position = Vector2(1000,1000)
	elif _game_phase == Enums.PHASES.BID_DOWN:
		$MakeTrumpPhase2.visible = false
		
	$Timer.start()
	_active_player = _next_player(_active_player)
	
# CPU Functions
func _cpu_turn():
	print("_cpu_turn()")
	if _game_phase == Enums.PHASES.BID_UP:
		_cpu_bid_up()
	elif _game_phase == Enums.PHASES.BID_DOWN:
		_cpu_bid_down()
	elif _game_phase == Enums.PHASES.PLAYING:
		_cpu_play()

func _cpu_bid_up(force = false):
	print("_cpu_bid_up()")
	var options = [Enums.BID_UP_OPTIONS.PICK_IT_UP, Enums.BID_UP_OPTIONS.PASS]
	var choice = options.pick_random()
	if force:
		choice = Enums.BID_UP_OPTIONS.PASS

	if choice == Enums.BID_UP_OPTIONS.PASS:
		_player_pass()
	elif  choice == Enums.BID_UP_OPTIONS.PICK_IT_UP:
		#$HintLabel.text = Enums.Players_toString[_active_player] + " made trump"
		_player_called = _active_player
		_game_phase = Enums.PHASES.PLAYING
		_remove_bid_ui()
		_cpu_discard(_active_player)
		_active_player = _next_player(_dealer)
		var hint_str = "%s made trump %s to lead" % [Enums.Players_toString[_player_called], Enums.Players_toString[_active_player]]
		$HintLabel.text = hint_str

func _cpu_bid_down(force = false):
	print("_cpu_bid_down")
	var options = []
	if _deck[23].suit != Enums.Suits.SPADES:
		options.append(Enums.BID_DOWN_OPTIONS.SPADES)
	if _deck[23].suit != Enums.Suits.CLUBS:
		options.append(Enums.BID_DOWN_OPTIONS.CLUBS)
	if _deck[23].suit != Enums.Suits.HEARTS:
		options.append(Enums.BID_DOWN_OPTIONS.HEARTS)
	if _deck[23].suit != Enums.Suits.DIAMONDS:
		options.append(Enums.BID_DOWN_OPTIONS.DIAMONDS)
	
	if _active_player != _dealer:
		options.append(Enums.BID_DOWN_OPTIONS.PASS)
		
	
	var choice = options.pick_random()
	if force and _active_player != _dealer:
		choice = Enums.BID_DOWN_OPTIONS.PASS
		
	if choice == Enums.BID_DOWN_OPTIONS.PASS:
		_player_pass()
	else:
		# Make trump selected trump and next phase:
		if choice == Enums.BID_DOWN_OPTIONS.SPADES:
			_trump = Enums.Suits.SPADES
		elif choice == Enums.BID_DOWN_OPTIONS.HEARTS:
			_trump = Enums.Suits.HEARTS
		elif choice == Enums.BID_DOWN_OPTIONS.DIAMONDS:
			_trump = Enums.Suits.DIAMONDS
		elif choice == Enums.BID_DOWN_OPTIONS.CLUBS:
			_trump = Enums.Suits.CLUBS
		$HintLabel.text = "%s made trump: %s" % [Enums.Players_toString[_active_player], Enums.TO_STR_SUITS[_trump]]
		$MakeTrumpPhase2.visible = false
		_game_phase = Enums.PHASES.PLAYING
		_active_player = _next_player(_dealer)
		$Timer.start()

func _cpu_discard(player):
	print("_cpu_discard")
	var randy = randi() % 5
	_players_hands[player][randy].position = Vector2(1000,1000)
	_players_hands[player][randy] = _deck[23]
	_players_hands[player][randy].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[player][randy][0],
	PlayerPositions.PLAYER_HAND_POSITIONS[player][randy][1])
	_players_hands[player][randy].rotation = PlayerPositions.PLAYER_HAND_ROTATION[player]
	
	_player_called = _active_player
	_active_player = _next_player(_dealer)
	_game_phase = Enums.PHASES.PLAYING
	_remove_bid_ui()
	$HintLabel.text = "%s called ordered it up " % Enums.Players_toString[_active_player]
	$Timer.start()

func _cpu_play():
	var options = []
	for i in range(5):
		if _players_hands[_active_player][i] != null:
			options.append(i)
	var choice = options.pick_random()
	_cpu_play_card(choice)

func _cpu_play_card(index):
	var card = _players_hands[_active_player][index]
	if card != null:
		card.position = Vector2(
			PlayerPositions.PLAYED_CARD_POSITIONS[_active_player][0],
			PlayerPositions.PLAYED_CARD_POSITIONS[_active_player][1]
		)
	_active_player = _next_player(_active_player)
	_played_card_count += 1
	if _played_card_count < 4:
		$Timer.start()
	else:
		_hand_eval()

func _player_turn():
	if _game_phase == Enums.PHASES.BID_UP:
		_player_bid_up()
	if _game_phase == Enums.PHASES.BID_DOWN:
		_player_bid_down()
	if _game_phase == Enums.PHASES.PLAYING:
		_player_play_hand()

func _player_bid_up():
	$HintLabel.text = "Players turn to pass or order it up"
	$MakeTrumpPhase1/Pass.visible = true
	$"MakeTrumpPhase1/Order UP".visible = true

func _player_bid_down():
	if _dealer != Enums.PLAYERS.Player:
		$MakeTrumpPhase2/Pass.visible = true
	if _deck[23].suit != Enums.Suits.SPADES:
		$MakeTrumpPhase2/Spades.visible = true
	if _deck[23].suit != Enums.Suits.HEARTS:
		$MakeTrumpPhase2/Hearts.visible = true
	if _deck[23].suit != Enums.Suits.DIAMONDS:
		$MakeTrumpPhase2/Diamonds.visible = true
	if _deck[23].suit != Enums.Suits.CLUBS:
		$MakeTrumpPhase2/Clubs.visible = true
	
func _player_play_hand():
	print("_player_play_hand")
	$HintLabel.text = "Players turn to play"
	_connect_player_hand_play("select_card", _select_card)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Callbacks
func _on_timer_timeout():
	_play_turn()

func _on_make_trump_phase_1_order_up():
	if _dealer == Enums.PLAYERS.Player:
		$HintLabel.text = "Pick a card to discard"
		_connect_player_hand_play("select_card", _select_card)
	else: 
		_cpu_discard(_dealer)

func _on_make_trump_phase_1_pass():
	_player_pass()
	
func _select_card(card):
	if _game_phase == Enums.PHASES.BID_UP:
		var idx = _players_hands[Enums.PLAYERS.Player].find(card)
		_players_hands[Enums.PLAYERS.Player][idx].position = Vector2(1000,1000)
		_players_hands[Enums.PLAYERS.Player][idx] = _deck[23]
		_players_hands[Enums.PLAYERS.Player][idx].position = Vector2(
			PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][idx][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][idx][1])
		_game_phase = Enums.PHASES.PLAYING
		_remove_bid_ui()
		_active_player = _next_player(_dealer)
		$Timer.start()
	elif _game_phase == Enums.PHASES.PLAYING:
		card.position = Vector2(
			PlayerPositions.PLAYED_CARD_POSITIONS[Enums.PLAYERS.Player][0],
			PlayerPositions.PLAYED_CARD_POSITIONS[Enums.PLAYERS.Player][1]
		)
		_played_card_count += 1
		if _played_card_count < 4:
			_active_player = _next_player(_active_player)
			$Timer.start()
		else:
			_hand_eval()
	
func _player_make_trump(suit):
	_trump = suit
	$MakeTrumpPhase2.visible = false
	_player_called = Enums.PLAYERS.Player
	_active_player = _next_player(_dealer)
	_game_phase = Enums.PHASES.PLAYING
	$HintLabel.text = "Player made %s trump" % Enums.TO_STR_SUITS[_trump]
	$Timer.start()

func _on_make_trump_phase_2_clubs_signal():
	_player_make_trump(Enums.Suits.CLUBS)

func _on_make_trump_phase_2_diamonds_signal():
	_player_make_trump(Enums.Suits.DIAMONDS)
	
func _on_make_trump_phase_2_hearts_signal():
	_player_make_trump(Enums.Suits.HEARTS)

func _on_make_trump_phase_2_spades_signal():
	_player_make_trump(Enums.Suits.SPADES)

func _on_make_trump_phase_2_pass_signal():
	_player_pass()
