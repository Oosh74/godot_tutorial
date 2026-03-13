extends PlayerState

func enterState():
	StateName = "Fall"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.animatedSprite.play("idle")
	Player.handleFlipH()
