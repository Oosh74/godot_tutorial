extends PlayerState

func enterState():
	StateName = "JumpPeak"

func exitState():
	pass

func draw():
	pass

func update(delta: float):
	Player.changeState(States.Fall)

func handleAnimation():
		pass
