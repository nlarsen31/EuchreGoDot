const TO_STR_SUITS = ["spades", "clubs", "hearts", "diamonds"] # Same order as enum
enum Suits {
	SPADES,
	CLUBS,
	HEARTS,
	DIAMONDS
}

enum Ranks {
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING,
	ACE
}
enum RanksTrump {
	NINE,
	TEN,
	JACK,
	QUEEN,
	KING,
	ACE,
}
const Players_toString = ["right", "partner", "left", "player"]
enum PLAYERS {
	Right,
	Partner,
	Left,
	Player
}
enum PHASES { # Current state of the game
	BID_UP,
	BID_DOWN,
	Discard,
	PLAYING
}

const BID_UP_OPTIONS_STR = ["PICK_IT_UP", "PASS"]
enum BID_UP_OPTIONS {
	PICK_IT_UP,
	PASS
}
const BID_DOWN_OPTIONS_STR = ["PASS", "SPADES", "CLUBS", "HEARTS", "DIAMONDS"]
enum BID_DOWN_OPTIONS {
	PASS,
	SPADES,
	CLUBS,
	HEARTS,
	DIAMONDS
}
