extends PlayerState

func enterState():
	StateName = "Run"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.animatedSprite.play("run")
	Player.handleFlipH()
