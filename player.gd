extends CharacterBody2D

#region Player Variables

#Physics variables
const JUMP_VELOCITY = -150
#const FALL_GRAVITY = 1.5
#const JUMP_GRAVITY = 1.0
const RUN_SPEED = 140
const ACCELERATION = 30
const DECELERATION = 25
const GRAVITY = 300
const MAX_JUMP = 2

var jumpCount = 0
var jumpSpeed = JUMP_VELOCITY
var canCoyoteJump = false
var moveSpeed = RUN_SPEED
var moveDirectionX = 0
var facing = 1
#var direction := Input.get_axis("KeyLeft", "KeyRight") 	#Get the input direction: -1, 0 1 
	# As good practice, you should replace UI actions with custom gameplay actions.

#Input variables
var keyUp = false
var keyDown = false
var keyLeft = false
var keyRight = false
var keyJump = false
var keyJumpPressed = false

#State machine
var currentState = null
var previousState = null

#Nodes
@onready var animatedSprite: AnimatedSprite2D = $Sprite
@onready var jumpSound: AudioStreamPlayer2D = $"Jump Sound"
@onready var coyoteTimer: Timer = $CoyoteTimer
@onready var States: Node = $StateMachine
@onready var Camera: Camera2D = $playerCamera
#endregion

func _ready():
	#init state machine
	for state in States.get_children():
		state.States = States
		state.Player = self
	if is_on_floor():
		currentState = States.Idle
	else:
		currentState = States.Fall
	previousState = currentState
	currentState.enterState()

func _draw():
	currentState.draw()

func _physics_process(delta: float) -> void:
	#get input states
	getInputStates()
	
	#Update current state
	currentState.update(delta)
	
	#handle movements

	horizontalMovement()
	handleJump()
	
	#handle animation
	handleAnimation()
	handleFlipH()

#Coyote Time
	var was_on_floor = is_on_floor()
#Commit movement
	move_and_slide()
	
	if was_on_floor && !is_on_floor():
		canCoyoteJump = true
		coyoteTimer.start() 

func changeState(newState):
	if (newState != null):
		previousState = currentState
		currentState = newState
		previousState.exitState()
		currentState.enterState()
		print("State change from " + previousState.StateName + " to: " + currentState.StateName)

func getInputStates():
	keyUp = Input.is_action_pressed("KeyUp")
	keyDown = Input.is_action_pressed("KeyDown")
	keyLeft = Input.is_action_pressed("KeyLeft")
	keyRight = Input.is_action_pressed("KeyRight")
	keyJump = Input.is_action_pressed("KeyJump")
	keyJumpPressed = Input.is_action_just_pressed("KeyJump")
	
	if (keyRight): facing = 1
	if (keyLeft): facing = -1

func horizontalMovement(acceleration: float = ACCELERATION, deceleration: float = DECELERATION):
	moveDirectionX = Input.get_axis("KeyLeft", "KeyRight")
	if (moveDirectionX != 0):
		velocity.x = move_toward(velocity.x, moveDirectionX * moveSpeed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, moveDirectionX * moveSpeed, deceleration)

func handleFalling():
	#See if we walked off ledge, if so, go to fall state
	if (!is_on_floor()):
		changeState(States.Fall)

func handleLanding():
	if (is_on_floor()):
		jumpCount = 0
		changeState(States.Idle)

func handleAnimation():
	#Jump anim
	if is_on_floor():
		if moveDirectionX == 0:
			animatedSprite.play("idle")
		else:
			animatedSprite.play("run")
	else:
		if (velocity.y < 0):
			animatedSprite.play("jumping")
		elif Input.is_action_just_pressed("KeyJump") && jumpCount < MAX_JUMP:
				animatedSprite.play("double jump")

func handleGravity(delta, gravity: float = GRAVITY ):
	if  (!is_on_floor()):
		velocity.y += gravity * delta

func handleFlipH():
		animatedSprite.flip_h = (facing < 0)

func handleJump():
	if ((keyJumpPressed) and (jumpCount < MAX_JUMP)):
			jumpCount += 1
			jumpSound.play()
			changeState(States.Jump)
	
	# Old Handle jump
	#if Input.is_action_just_pressed("KeyJump") && (is_on_floor() || !coyoteTimer.is_stopped()) && jumpCount < 1:
		#jumpCount += 1
		#velocity.y = JUMP_VELOCITY
		#jumpSound.play()
	#elif Input.is_action_just_pressed("KeyJump") && jumpCount < MAX_JUMP:
		#jumpCount += 1
		#velocity.y = JUMP_VELOCITY
		#jumpSound.play()
