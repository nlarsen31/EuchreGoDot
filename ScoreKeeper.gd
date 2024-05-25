extends Node2D

@export var card_scene: PackedScene

var _score = 0
var _card6
var _card4

# each element is the positon of the 4, U/D,x,y,Rot
# U/D -> 0 is face down 1 is face up.
var pointPoistions = [
	[0,0,0,0], # 0 points
	[0, 17, 4, PI/4], # 1 points
	[0, 17, 4, PI/2], # 2 points
	[0, 34, 29, PI/4], # 3 points
	[0, 18, 45, PI/2], # 4 points
	[1, 17, 4, PI/4], # 5 points
	[1, 17, 4, PI/2], # 6 points
	[1, 34, 29,PI/4], # 7 points
	[1, 18, 45, PI/2], # 8 points
	[1, 44, 62, PI/4], # 9 points
]

# Called when the node enters the scene tree for the first time.
func _ready():
	_card6 = card_scene.instantiate()
	_card6.setCardSprite("6_hearts")
	add_child(_card6)
	
	_card4 = card_scene.instantiate()
	_card4.setCardSprite("card_back")
	add_child(_card4)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_score_tick_timeout():
	pass
	#_score = (_score + 1) % 10
	#
	## Set Position of the 4
	#if pointPoistions[_score][0] == 1:
		#_card4.setCardSprite("4_hearts")
	#else:
		#_card4.setCardSprite("card_back")
	#
	#
	#_card4.position = Vector2(pointPoistions[_score][1], pointPoistions[_score][2])
	#_card4.rotation = pointPoistions[_score][3]
