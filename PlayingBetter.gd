extends Node2D

# Random chances
const PASS_UP_CHANCE = 0 # if 5, 1 in 6 chance to order up trump
const PASS_DOWN_CHANCE = 10 # if 10, 1 in 11 chance to order up

# External Scripts
const Enums = preload("res://CommonScripts/enums.gd")
const PlayerPositions = preload("res://CommonScripts/PlayerPositions.gd")
const TrumpRankings = preload("res://CommonScripts/TrumpRanking.gd")
@export var card_scene: PackedScene

# State Properties
var _active_player = -1
var _player_called = -1
var _dealer = Enums.PLAYERS.Player
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
var _tricks_won = 0
var _good_guys_score = 0
var _bad_guys_score = 0

# Common Util functions
###############################################################################
# This section if for functions that can be useful in different phases of the game
###############################################################################
func _remove_card_from_hand(card):
	var hand_idx = _players_hands[_active_player].find(card)
	_players_hands[_active_player][hand_idx] = null

func _all_hands_null():
	for i in range(5):
		for player in range(4):
			if _players_hands[player][i] != null:
				return false
	return true

func _hand_eval():
	
	var rank_dict: Dictionary = _get_ranking_dictionary(_trump, _played_cards[_lead_player].suit)
	
	# start with leading player, loop 4 times
	var winning_player = _lead_player
	var curr_player = _next_player(_lead_player)
	for i in range(3):
		var winning_player_card: StaticBody2D = _played_cards[winning_player]
		var curr_player_card: StaticBody2D = _played_cards[curr_player]
		if rank_dict.has(str(curr_player_card)):
			if rank_dict[str(curr_player_card)] < rank_dict[str(winning_player_card)]:
				winning_player = curr_player
		curr_player = _next_player(curr_player)
	print("winning: " + Enums.Players_toString[winning_player])
	return winning_player

func _print_players_hands():
	for player_idx in range(4):
		var hand = []
		for j in range(5):
			if _players_hands[player_idx][j] != null:
				hand.append(_players_hands[player_idx][j])
		var s = "%s ".repeat(len(hand))
		var hand_str = s % hand
		print("%s [%s]" % [Enums.Players_toString[player_idx], hand_str])

func _print_played_cards():
	var str = "%s %s\n".repeat(4)
	var parms = []
	for i in range(4):
		parms.append(Enums.Players_toString[i])
		parms.append(str(_played_cards[i]))
	print(str % parms)
# Returns a dictionary with the ranking of each card based trump and lead
func _get_ranking_dictionary(trump, lead):
	var dict = {}
	var trump_rank = ["a", "k", "q", "10", "9"]
	var normal_rank = ["a", "k", "q", "j", "10", "9"]
	
	# Add the jacks at 0 and 1
	if trump == Enums.Suits.SPADES:
		dict["j_spades"] = 0
		dict["j_clubs"] = 1
	elif trump == Enums.Suits.CLUBS:
		dict["j_clubs"] = 0
		dict["j_spades"] = 1
	elif trump == Enums.Suits.HEARTS:
		dict["j_hearts"] = 0
		dict["j_diamonds"] = 1
	elif trump == Enums.Suits.DIAMONDS:
		dict["j_diamonds"] = 0
		dict["j_hearts"] = 1
	
	# Add the rest of trump
	var curr_value = 2
	for rank in trump_rank:
		dict[rank + "_" + Enums.TO_STR_SUITS[trump]] = curr_value
		curr_value += 1
	
	# Add the rest of everything else:
	for rank in normal_rank:
		var key = rank + "_" + Enums.TO_STR_SUITS[lead]
		if not dict.has(key): #Skip anything we have for the left
			dict[key] = curr_value
		curr_value += 1
	return dict

func _next_player(player):
	return (player + 1) % 4
	
func _connect_player_hand_play(connect_str, play_or_discard, connect = true, options=range(5)):
	for i in options:
		var player_card : StaticBody2D = _players_hands[Enums.PLAYERS.Player][i]
		if player_card != null:
			if connect:
				player_card.connect(connect_str, play_or_discard)
			else:
				player_card.disconnect(connect_str, play_or_discard)

func _remove_bid_ui():
	$MakeTrumpPhase1.visible = false
	$MakeTrumpPhase2.visible = false

func _place_made_it_chip(player, suit):
	print("_place_made_it_chip")
	$DealerChipMadeIt.visible = true
	$DealerChipMadeIt.position = PlayerPositions.MADE_IT_CHIP_POSITIONS[player][0]
	$DealerChipMadeIt.rotation = PlayerPositions.MADE_IT_CHIP_POSITIONS[player][1]
	$DealerChipMadeIt.set_sprite_suit(_trump)

# Take what was lead, and what is in a hand, and return valid options
# lead -> a suit 
# hand -> an element of _player_hands, can contain nulls
func _get_options(lead, hand):
	var options_lead = []
	var options_other = []
	
	for i in range(len(hand)):
		if hand[i] == null:
			continue
		if _get_suit(_trump, hand[i]) == lead:
			options_lead.append(i)
		else:
			options_other.append(i)
	if len(options_lead) > 0:
		return options_lead
	return options_other

func _move_up_all_options(options, displacement):
	for i in len(_players_hands[Enums.PLAYERS.Player]):
		var card = _players_hands[Enums.PLAYERS.Player][i]
		if i in options:
			card.position = Vector2(card.position[0], card.position[1] + displacement)

###############################################################################
# Hand evaluation methods
###############################################################################

# return true if card1 wins, false if card2 wins
func _compare_two_cards(card1, card2):
	var leading_suit = _played_cards[_lead_player].suit
	print("comparing " + card1.toString() + " " + card2.toString())
	print("Trump: " + Enums.TO_STR_SUITS[_trump] + 
		" Leading Player: " + Enums.Players_toString[_lead_player] +
		" Leading Suit: " + Enums.TO_STR_SUITS[leading_suit])
	if _get_suit(_trump, card1) == _trump and _get_suit(_trump, card2) != _trump:
		return true
	elif  _get_suit(_trump, card1) != _trump and _get_suit(_trump, card2) == _trump:
		return false
	elif _get_suit(_trump, card1) == _trump and _get_suit(_trump, card2) == _trump:
		var idx1 = TrumpRankings.ALL_RANKINGS[_trump].find(card1.toString())
		var idx2 = TrumpRankings.ALL_RANKINGS[_trump].find(card2.toString())
		if idx1 > idx2:
			return true
		return false
	elif _get_suit(_trump, card1) != _trump and _get_suit(_trump, card2) != _trump:
		if card1.rank > card2.rank:
			return true
		return false
	return
	
# _get_suit takes into account jacks changing.
func _get_suit(CurrentTrump, card):
	if card.rank != Enums.Ranks.JACK:
		return card.suit
	elif _trump == Enums.Suits.SPADES and card.suit == Enums.Suits.CLUBS:
		return Enums.Suits.SPADES
	elif _trump == Enums.Suits.CLUBS and card.suit == Enums.Suits.SPADES:
		return Enums.Suits.CLUBS
	elif _trump == Enums.Suits.HEARTS and card.suit == Enums.Suits.DIAMONDS:
		return Enums.Suits.HEARTS
	elif _trump == Enums.Suits.DIAMONDS and card.suit == Enums.Suits.HEARTS:
		return Enums.Suits.DIAMONDS
	else:
		return card.suit

###############################################################################
# scene methods
###############################################################################
func _ready():
	_active_player = _dealer
	$MakeTrumpPhase1/Pass.visible = false
	$"MakeTrumpPhase1/Order UP".visible = false
	
	_play_turn()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

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
	# TODO: this is not working right in some cases of player leading
	if _played_card_count == 0 and _game_phase == Enums.PHASES.PLAYING:
		_lead_player = _active_player
		print(Enums.Players_toString[_lead_player] + " is leading")
		
	if not _dealt:
		deal()
	elif _played_card_count >= 4:
		_print_played_cards()
		_print_players_hands()
		_clean_up_mark_points()
	elif _active_player != Enums.PLAYERS.Player:
		_cpu_turn()
	elif _active_player == Enums.PLAYERS.Player:
		_player_turn()

func _reset_player_hand():
	for i in len(_players_hands[Enums.PLAYERS.Player]):
		var card = _players_hands[Enums.PLAYERS.Player][i]
		if card == null:
			continue
		card.position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][i][1])
		card.rotation = PlayerPositions.PLAYER_HAND_ROTATION[Enums.PLAYERS.Player]
	

func deal():
	_deck.clear()
	_build_deck()
	_deck.shuffle()
	# Positions 0, 5 Right
	for i in range(0, 5):
		_deck[i].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[0][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[0][i][1])
		_deck[i].rotation = PlayerPositions.PLAYER_HAND_ROTATION[0]
		_deck[i].visible = true
		_players_hands[Enums.PLAYERS.Right][i] = _deck[i]
		_deck[i].flipDownCard()
		
	# Positions 5, 10 Partner
	for i in range(0, 5):
		_deck[i+5].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[1][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[1][i][1])
		_deck[i+5].rotation = PlayerPositions.PLAYER_HAND_ROTATION[1]
		_deck[i+5].visible = true
		_players_hands[Enums.PLAYERS.Partner][i] = _deck[i+5]
		_deck[i+5].flipDownCard()
	
	# Positions 10, 15 Left
	for i in range(0, 5):
		_deck[i+10].position = Vector2(PlayerPositions.PLAYER_HAND_POSITIONS[2][i][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[2][i][1])
		_deck[i+10].rotation = PlayerPositions.PLAYER_HAND_ROTATION[2]
		_deck[i+10].visible = true
		_players_hands[Enums.PLAYERS.Left][i] = _deck[i+10]
		_deck[i+10].flipDownCard()
		
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
	_deck[23].rotation = 0
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
	# Set dealer token
	$DealerChipDealer.set_sprite("dealer")
	$DealerChipDealer.position = PlayerPositions.DEALER_CHIP_POSITIONS[_dealer][0]
	$DealerChipDealer.rotation = PlayerPositions.DEALER_CHIP_POSITIONS[_dealer][1]
	$DealerChipMadeIt.visible = false
	$ResultLabel.visible = false
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
		
	_active_player = _next_player(_active_player)
	$Timer.start()
	
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
	var options = [Enums.BID_UP_OPTIONS.PICK_IT_UP]
	for i in range(PASS_UP_CHANCE):
		options.append(Enums.BID_UP_OPTIONS.PASS)
	var choice = options.pick_random()
	if force:
		choice = Enums.BID_UP_OPTIONS.PASS

	if choice == Enums.BID_UP_OPTIONS.PASS:
		_player_pass()
	elif  choice == Enums.BID_UP_OPTIONS.PICK_IT_UP:
		_player_called = _active_player
		_game_phase = Enums.PHASES.PLAYING
		_trump = _deck[23].suit
		_remove_bid_ui()
		_active_player = _next_player(_dealer)
		var hint_str = "%s made trump %s to lead" % [Enums.Players_toString[_player_called], Enums.Players_toString[_active_player]]
		$HintLabel.text = hint_str
		_place_made_it_chip(_player_called, _trump)
		
		if _dealer in [Enums.PLAYERS.Partner, Enums.PLAYERS.Right, Enums.PLAYERS.Left]:
			_cpu_discard(_dealer)
		else:
			$HintLabel.text += "\nPick a card to discard"
			_connect_player_hand_play("select_card", _select_card)

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
		for i in range(PASS_DOWN_CHANCE):
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
		_player_called = _active_player
		_active_player = _next_player(_dealer)
		_place_made_it_chip(_player_called, _trump)
		$Timer.start()

# This gets called when any player "orders it up" in bid up phase
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
	var lead = -1
	if _played_card_count > 0:
		lead = _get_suit(_trump, _played_cards[_lead_player])
	var options = _get_options(lead, _players_hands[_active_player])
	var choice = options.pick_random()
	_cpu_play_card(choice)

func _cpu_play_card(index):
	var card = _players_hands[_active_player][index]
	card.flipUpCard()
	if card != null:
		card.position = Vector2(
			PlayerPositions.PLAYED_CARD_POSITIONS[_active_player][0],
			PlayerPositions.PLAYED_CARD_POSITIONS[_active_player][1]
		)
	_remove_card_from_hand(card)
	_played_cards[_active_player] = card
	_active_player = _next_player(_active_player)
	_played_card_count += 1
	$Timer.start()

func _player_turn():
	if _game_phase == Enums.PHASES.BID_UP:
		_player_bid_up()
	elif _game_phase == Enums.PHASES.BID_DOWN:
		_player_bid_down()
	elif _game_phase == Enums.PHASES.PLAYING:
		_player_play_hand()

func _player_bid_up():
	$HintLabel.text = "Players turn to pass or order it up"
	$MakeTrumpPhase1.visible = true
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
	
	$HintLabel.text = "Pick a suit to be trump"
	$MakeTrumpPhase2.visible = true
	
func _player_play_hand():
	print("_player_play_hand")
	$HintLabel.text = "Players turn to play"
	var lead = -1
	if _played_card_count > 0:
		lead = _get_suit(_trump, _played_cards[_lead_player])
	var options = _get_options(lead, _players_hands[Enums.PLAYERS.Player])
	_connect_player_hand_play("select_card", _select_card, true, options)
	_move_up_all_options(options, -20)
	
	
###############################################################################
# Callbacks for objects in game
###############################################################################
func _on_timer_timeout():
	_play_turn()

func _on_make_trump_phase_1_order_up():
	if _dealer == Enums.PLAYERS.Player:
		$HintLabel.text = "Pick a card to discard"
		_connect_player_hand_play("select_card", _select_card)
	else:
		_trump = _deck[23].suit
		_player_called = _active_player
		_cpu_discard(_dealer)
		_place_made_it_chip(_player_called, _trump)

func _on_make_trump_phase_1_pass():
	_player_pass()

func _select_card(card):
	if _game_phase == Enums.PHASES.BID_UP:
		_trump = _deck[23].suit
		_player_called = Enums.PLAYERS.Player
		_place_made_it_chip(_player_called, _trump)
		var idx = _players_hands[Enums.PLAYERS.Player].find(card)
		_players_hands[Enums.PLAYERS.Player][idx].position = Vector2(1000,1000)
		_players_hands[Enums.PLAYERS.Player][idx] = _deck[23]
		_players_hands[Enums.PLAYERS.Player][idx].position = Vector2(
			PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][idx][0],
			PlayerPositions.PLAYER_HAND_POSITIONS[Enums.PLAYERS.Player][idx][1])
		_game_phase = Enums.PHASES.PLAYING
		_remove_bid_ui()
		_active_player = _next_player(_dealer)
		_connect_player_hand_play("select_card", _select_card, false)
		$Timer.start()
	elif _game_phase == Enums.PHASES.PLAYING:
		_reset_player_hand()
		card.position = Vector2(
			PlayerPositions.PLAYED_CARD_POSITIONS[Enums.PLAYERS.Player][0],
			PlayerPositions.PLAYED_CARD_POSITIONS[Enums.PLAYERS.Player][1]
		)
		_remove_card_from_hand(card)
		
		_played_cards[_active_player] = card
		_played_card_count += 1
		_active_player = _next_player(_active_player)
		$Timer.start()

func _player_make_trump(suit):
	_trump = suit
	$MakeTrumpPhase2.visible = false
	_player_called = Enums.PLAYERS.Player
	_place_made_it_chip(_player_called, _trump)
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

func _clear_played_cards():
	for card in _played_cards:
		card.position = Vector2(1000,1000)
	for i in range(len(_played_cards)):
		_played_cards[i] = null

func _set_tricks_label():
	$TrickCount.text = "Tricks Won in Hand: %s" % str(_tricks_won)

func _clean_up_mark_points():
	var winning_player = _hand_eval()
	if winning_player in [Enums.PLAYERS.Partner, Enums.PLAYERS.Player]:
		_tricks_won += 1
		_set_tricks_label()
		
	_clear_played_cards()
	_active_player = winning_player
	_played_card_count = 0
	
	if _all_hands_null():
		_set_up_next_hand()
	else:
		$Timer.start()

func _set_up_next_hand():
	_dealt = false
	var label_text = """%s made trump
	and won %d tricks
	%s gets %d points
	"""
	var winner = -1
	var points = 0
	
	if _tricks_won >= 3:
		winner = Enums.PLAYERS.Player
	elif _player_called != Enums.PLAYERS.Partner and _player_called != Enums.PLAYERS.Player:
		winner = _player_called
	elif _player_called == Enums.PLAYERS.Player:
		winner = Enums.PLAYERS.Right
		
	var good_guys = [Enums.PLAYERS.Player, Enums.PLAYERS.Partner]
	var good_guys_made_it = _player_called in good_guys
	var bad_guys_tricks = 5 - _tricks_won
	
	if good_guys_made_it and _tricks_won == 5:
		points = 2
	elif not good_guys_made_it and bad_guys_tricks == 5:
		points = 2
	elif good_guys_made_it and _tricks_won in [3, 4]:
		points = 1
	elif not good_guys_made_it and bad_guys_tricks in [3,4]:
		points = 1
	elif good_guys_made_it and _tricks_won in [0, 1, 2]:
		points = 2
	elif not good_guys_made_it and _tricks_won in [0, 1, 2]:
		points = 2
	
	var tricks = _tricks_won
	if winner not in [Enums.PLAYERS.Player, Enums.PLAYERS.Partner]:
		tricks = bad_guys_tricks

	$ResultLabel.text = label_text % [
		Enums.Players_toString[_player_called],
		tricks, 
		Enums.Players_toString[winner], points
	]
	$ResultLabel.visible = true
	if winner in good_guys:
		_good_guys_score += points
		$GoodGuyLabel.text = "Good guys Score: %d" % [_good_guys_score]
	else:
		_bad_guys_score += points
		$OppoLabel.text = "Oppos Score %d" % [_bad_guys_score]
	
	_tricks_won = 0
	_set_tricks_label()
	
	_dealer = _next_player(_dealer)
	$TimerLong.start()
