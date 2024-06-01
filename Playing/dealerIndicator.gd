extends Sprite2D


const Enums = preload("res://CommonScripts/enums.gd")

func set_dealer(dealer):
	if dealer == Enums.PLAYERS.Right:
		$AnimatedSprite2D2.animation = "right"
	if dealer == Enums.PLAYERS.Left:
		$AnimatedSprite2D2.animation = "left"
	if dealer == Enums.PLAYERS.Player:
		$AnimatedSprite2D2.animation = "down"
	if dealer == Enums.PLAYERS.Partner:
		$AnimatedSprite2D2.animation = "up"
