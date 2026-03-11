extends PlayerState

func enterState():
	StateName = "Idle"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.handleFalling()
	Player.handleJump()
	Player.horizontalMovement()
	if (Player.moveDirectionX != 0):
		Player.changeState(States.Run)
	handleAnimation()

func handleAnimation():
	Player.animatedSprite.play("idle")
	Player.HandleFlipH()
