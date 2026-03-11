extends PlayerState

func enterState():
	StateName = "Run"

func exitState():
	pass

func update(delta: float):
	#Handle movements
	Player.horizontalMovement()
	Player.handleJump()
	Player.handleFalling()
	handleAnimation()
	handleIdle()

func handleIdle():
	if (Player.moveDirectionX == 0):
		Player.changeState(States.Idle)

func handleAnimation():
	Player.animatedSprite.play("run")
