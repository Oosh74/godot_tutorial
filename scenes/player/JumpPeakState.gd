extends PlayerState

func enterState():
	StateName = "JumpPeak"

func exitState():
	pass

func draw():
	pass

func update(delta):
	Player.changeState(States.Fall)

func handleAnimation():
		pass
