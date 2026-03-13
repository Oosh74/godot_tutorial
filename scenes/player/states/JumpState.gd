extends PlayerState

func enterState():
	StateName = "Jump"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.animatedSprite.play("jumping")
	Player.handleFlipH()
