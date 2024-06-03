

const PLAYED_CARD_POSITIONS = [
	[812, 450, -1*PI/2],#RIGHT
	[700,338,PI], #Partner
	[588,450,PI/2],#LEFT
	[700,562,0],#Player
]


const PLAYER_HAND_ROTATION = [ 
	-1*PI/2,
	PI,
	PI/2,
	0.0,
]
const PLAYER_HAND_POSITIONS = [
	[#right
		[1326, 238],
		[1326, 344],
		[1326, 450],
		[1326, 556],
		[1326, 662]
	],
	[#partner
		[508, 74],
		[614, 74],
		[720, 74],
		[826, 74],
		[932, 74]
	],
	[#left
		[86, 238],
		[86, 344],
		[86, 450],
		[86, 556],
		[86, 662]
	],
	[#player
		[508, 826],
		[614, 826],
		[720, 826],
		[826, 826],
		[932, 826]
	]
]

const KittyLocation = Vector2(700, 450)

const DEALER_CHIP_POSITIONS = [
	[Vector2(1288,159), -1*PI/2],#right,
	[Vector2(429,112), PI],#Partner
	[Vector2(112, 741), PI/2],#LEFT
	[Vector2(1011, 788), 0.0]#Player
]
const MADE_IT_CHIP_POSITIONS = [
	[Vector2(1364,159), -1*PI/2],#right,
	[Vector2(429,36), PI],#Partner
	[Vector2(36, 741), PI/2],#left
	[Vector2(1011, 863), 0.0]#player
]
