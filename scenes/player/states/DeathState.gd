extends PlayerState

func enterState():
	StateName = "Death"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.animatedSprite.play("hit")
	Player.handleFlipH()
