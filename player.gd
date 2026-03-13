extends CharacterBody2D

#region Constants

const RUN_SPEED = 140.0
const ACCELERATION = 700.0
const DECELERATION = 900.0

const GRAVITY_JUMP = 600.0
const GRAVITY_FALL = 900.0
const MAX_FALL_VELOCITY = 320.0

const JUMP_VELOCITY = -240.0
const VARIABLE_JUMP_MULTI = 0.5

const MAX_JUMPS = 2
const JUMP_BUFFER_TIME = 0.10
const COYOTE_TIME = 0.10

const WALL_SLIDE_SPEED = 60.0
const WALL_JUMP_X = 180.0
const WALL_JUMP_Y = -240.0
const WALL_JUMP_LOCK_TIME = 0.12

const LEDGE_VAULT_X = 10.0
const LEDGE_VAULT_Y = 14.0

#endregion

#region Variables

var facing := 1
var moveDirectionX := 0.0

# Jump state
var jumpsUsed := 0
var jumpBufferTimer := 0.0
var coyoteTimer := 0.0
var jumpCutApplied := false

# Ground tracking
var wasOnFloor := false

# Wall logic
var wallJumpLockTimer := 0.0
var wallJumpDirection := 0
var lastWallJumpedFrom := 0
# -1 = left wall, 1 = right wall, 0 = none

# Ledge vault
var isVaulting := false

# Input
var keyLeft := false
var keyRight := false
var keyJump := false
var keyJumpPressed := false
var keyJumpReleased := false

# State machine
var currentState = null
var previousState = null

#endregion

#region Nodes

@onready var animatedSprite: AnimatedSprite2D = $Sprite
@onready var jumpSound: AudioStreamPlayer2D = $"Jump Sound"
@onready var States: Node = $StateMachine
@onready var Camera: Camera2D = $playerCamera

# Wall rays
@onready var wallRayLeft: RayCast2D = $WallRayLeft
@onready var wallRayRight: RayCast2D = $WallRayRight

# Ledge rays
@onready var ledgeRayLeftLow: RayCast2D = $LedgeRayLeftLow
@onready var ledgeRayLeftHigh: RayCast2D = $LedgeRayLeftHigh
@onready var ledgeRayRightLow: RayCast2D = $LedgeRayRightLow
@onready var ledgeRayRightHigh: RayCast2D = $LedgeRayRightHigh

#endregion

func _ready():
	for state in States.get_children():
		state.States = States
		state.Player = self

	currentState = States.Idle
	previousState = States.Idle
	wasOnFloor = is_on_floor()

func _physics_process(delta: float) -> void:
	getInputStates()
	updateTimers(delta)

	if isVaulting:
		updateState()
		currentState.update(delta)
		wasOnFloor = is_on_floor()
		return

	var onFloorNow := is_on_floor()
	var justLanded := !wasOnFloor and onFloorNow
	var justLeftFloor := wasOnFloor and !onFloorNow and velocity.y >= 0.0

	if justLanded:
		handleLanding()

	if justLeftFloor:
		coyoteTimer = COYOTE_TIME

	handleLedgeVault()

	# If vault started this frame, stop further processing
	if isVaulting:
		updateState()
		currentState.update(delta)
		wasOnFloor = is_on_floor()
		return

	handleWallJump()
	handleJump()
	handleVariableJump()
	handleGravity(delta)
	handleWallSlide()
	handleHorizontalMovement(delta)
	handleMaxFallVelocity()

	move_and_slide()

	updateState()
	currentState.update(delta)

	wasOnFloor = is_on_floor()

func _draw():
	if currentState != null:
		currentState.draw()

#region Input / Timers

func getInputStates():
	keyLeft = Input.is_action_pressed("KeyLeft")
	keyRight = Input.is_action_pressed("KeyRight")
	keyJump = Input.is_action_pressed("KeyJump")
	keyJumpPressed = Input.is_action_just_pressed("KeyJump")
	keyJumpReleased = Input.is_action_just_released("KeyJump")

	moveDirectionX = Input.get_axis("KeyLeft", "KeyRight")

	if keyRight:
		facing = 1
	elif keyLeft:
		facing = -1

	if keyJumpPressed:
		jumpBufferTimer = JUMP_BUFFER_TIME

func updateTimers(delta: float):
	jumpBufferTimer = max(jumpBufferTimer - delta, 0.0)
	coyoteTimer = max(coyoteTimer - delta, 0.0)
	wallJumpLockTimer = max(wallJumpLockTimer - delta, 0.0)

#endregion

#region Movement

func handleHorizontalMovement(delta: float):
	if wallJumpLockTimer > 0.0:
		velocity.x = move_toward(velocity.x, WALL_JUMP_X * wallJumpDirection, ACCELERATION * delta)
		return

	if moveDirectionX != 0.0:
		velocity.x = move_toward(velocity.x, moveDirectionX * RUN_SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)

func handleGravity(delta: float):
	if !is_on_floor():
		if velocity.y < 0.0:
			velocity.y += GRAVITY_JUMP * delta
		else:
			velocity.y += GRAVITY_FALL * delta

func handleMaxFallVelocity():
	if velocity.y > MAX_FALL_VELOCITY:
		velocity.y = MAX_FALL_VELOCITY

func handleVariableJump():
	if keyJumpReleased and velocity.y < 0.0 and !jumpCutApplied:
		velocity.y *= VARIABLE_JUMP_MULTI
		jumpCutApplied = true

#endregion

#region Jump Logic

func canGroundJump() -> bool:
	return is_on_floor() or coyoteTimer > 0.0

func canAirJump() -> bool:
	return jumpsUsed < MAX_JUMPS and !canGroundJump()

func doJump():
	velocity.y = JUMP_VELOCITY
	jumpsUsed += 1
	jumpBufferTimer = 0.0
	coyoteTimer = 0.0
	jumpCutApplied = false
	jumpSound.play()

func handleJump():
	if isVaulting:
		return

	if wallJumpLockTimer > 0.0:
		return

	if jumpBufferTimer <= 0.0:
		return

	if canGroundJump():
		if jumpsUsed == 0:
			doJump()
		else:
			jumpsUsed = 0
			doJump()
		return

	if canAirJump():
		doJump()
		return

func handleLanding():
	jumpsUsed = 0
	coyoteTimer = 0.0
	jumpCutApplied = false
	lastWallJumpedFrom = 0

#endregion

#region Wall Logic

func isTouchingLeftWall() -> bool:
	return wallRayLeft.is_colliding()

func isTouchingRightWall() -> bool:
	return wallRayRight.is_colliding()

func getTouchedWallSide() -> int:
	if isTouchingLeftWall():
		return -1
	if isTouchingRightWall():
		return 1
	return 0

func isHoldingTowardWall() -> bool:
	if isTouchingLeftWall():
		return keyLeft
	if isTouchingRightWall():
		return keyRight
	return false

func isWallSliding() -> bool:
	return !is_on_floor() \
		and velocity.y > 0.0 \
		and getTouchedWallSide() != 0 \
		and isHoldingTowardWall()

func handleWallSlide():
	if isWallSliding() and velocity.y > WALL_SLIDE_SPEED:
		velocity.y = WALL_SLIDE_SPEED

func getWallJumpDirection() -> int:
	# Return the direction AWAY from the wall
	if isTouchingLeftWall():
		return 1
	if isTouchingRightWall():
		return -1
	return 0

func handleWallJump():
	if isVaulting:
		return

	if !keyJumpPressed or is_on_floor():
		return

	var touchedWall := getTouchedWallSide()
	if touchedWall == 0:
		return

	# Must be holding toward wall to use wall interaction
	if !isHoldingTowardWall():
		return

	# No consecutive same-wall jumps
	if touchedWall == lastWallJumpedFrom:
		return

	var jumpDir := getWallJumpDirection()
	if jumpDir == 0:
		return

	velocity.x = WALL_JUMP_X * jumpDir
	velocity.y = WALL_JUMP_Y

	jumpBufferTimer = 0.0
	coyoteTimer = 0.0
	jumpCutApplied = false
	jumpsUsed = 1

	wallJumpDirection = jumpDir
	wallJumpLockTimer = WALL_JUMP_LOCK_TIME
	lastWallJumpedFrom = touchedWall

	jumpSound.play()

#endregion

#region Ledge Vault

func canVaultLeft() -> bool:
	return !is_on_floor() \
		and ledgeRayLeftLow.is_colliding() \
		and !ledgeRayLeftHigh.is_colliding()

func canVaultRight() -> bool:
	return !is_on_floor() \
		and ledgeRayRightLow.is_colliding() \
		and !ledgeRayRightHigh.is_colliding()

func handleLedgeVault():
	# Tap jump near ledge to vault
	if !keyJumpPressed:
		return

	# Prevent wall-jump-lock weirdness from fighting vault
	if wallJumpLockTimer > 0.0:
		return

	if canVaultLeft():
		doVault(-1)
	elif canVaultRight():
		doVault(1)

func doVault(direction: int):
	isVaulting = true
	velocity = Vector2.ZERO

	# Snap player up and forward.
	# You will likely want to tune these values for your sprite/collision shape.
	global_position.x += LEDGE_VAULT_X * direction
	global_position.y -= LEDGE_VAULT_Y

	coyoteTimer = 0.0
	jumpBufferTimer = 0.0
	jumpCutApplied = false
	lastWallJumpedFrom = 0

	# Optional: treat as grounded reset if you want vault to "refresh" movement
	jumpsUsed = 0

	isVaulting = false

#endregion

#region State / Animation

func updateState():
	if isVaulting:
		changeState(States.Idle)
		return

	if is_on_floor():
		if moveDirectionX == 0.0:
			changeState(States.Idle)
		else:
			changeState(States.Run)
	else:
		if velocity.y < 0.0:
			changeState(States.Jump)
		else:
			changeState(States.Fall)

func changeState(newState):
	if newState == null or newState == currentState:
		return

	previousState = currentState

	if previousState != null:
		previousState.exitState()

	currentState = newState
	currentState.enterState()

func handleFlipH():
	animatedSprite.flip_h = (facing < 0)

#endregion


func _on_area_2d_area_entered(area: Area2D) -> void:
	print('collided')
