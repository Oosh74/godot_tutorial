extends PlayerState

func enterState():
	StateName = "Jump"
	Player.velocity.y = Player.jumpSpeed

func exitState():
	pass

func update(delta: float):
	Player.handleGravity(delta)
	Player.horizontalMovement()
	handleJumpToFall()
	handleAnimation()

func handleJumpToFall():
	if (Player.velocity.y >= 0):
		Player.changeState(States.JumpPeak)

func handleAnimation():
	Player.animatedSprite.play("jumping")
	Player.handleFlipH()
