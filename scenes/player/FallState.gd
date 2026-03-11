extends PlayerState


func enterState():
	StateName = "Fall"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.handleGravity(delta)
	Player.horizontalMovement()
	Player.handleAnimation()
	handleAnimation()

func handleAnimation():
	Player.animatedSprite.play("idle")
