extends Sprite2D


const Enums = preload("res://CommonScripts/enums.gd")

func set_dealer(dealer):
	if dealer == Enums.Players.Right:
		$AnimatedSprite2D2.animation = "right"
	if dealer == Enums.Players.Left:
		$AnimatedSprite2D2.animation = "left"
	if dealer == Enums.Players.Player:
		$AnimatedSprite2D2.animation = "down"
	if dealer == Enums.Players.Partner:
		$AnimatedSprite2D2.animation = "up"
