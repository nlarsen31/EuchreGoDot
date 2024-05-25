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
	QUEEN,
	KING,
	ACE,
	JACK,
}
enum Players {
	Right,
	Player,
	Left,
	Partner
}
enum GameState { # Current state of the game
	FaceUpPickTrump,
	FaceDownPickTrump,
	Discard,
	Playing
}
