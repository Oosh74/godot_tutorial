extends CharacterBody2D

const SPEED = 130
const JUMP_VELOCITY = -300.0
const GRAVITY = 1000
const FALL_GRAVITY = 1.5
const JUMP_GRAVITY = 1.0
const MAX_JUMP = 2

var jump_count = 0
var can_double_jump = false
var can_coyote_jump = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $"Jump Sound"
@onready var coyote_timer: Timer = $CoyoteTimer

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if velocity.y < 0:
			velocity += get_gravity() * JUMP_GRAVITY * delta
		else:
			velocity += get_gravity() * FALL_GRAVITY * delta


#Adds a falling velocity, and allows to "bunny hops"
	if Input.is_action_just_released("jump") && velocity.y < 0:
		velocity.y = JUMP_VELOCITY / 4

	# Handle jump.
	if Input.is_action_just_pressed("jump") && (is_on_floor() || !coyote_timer.is_stopped()) && jump_count < 1:
		jump_count += 1
		velocity.y = JUMP_VELOCITY
		jump_sound.play()
	elif Input.is_action_just_pressed("jump") && jump_count < MAX_JUMP:
		jump_count += 1
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	
	#Get the input direction: -1, 0 1
	
	#Flip sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	#play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		animated_sprite.play("jumping")
	
	#Apply movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

#Coyote Time
	var was_on_floor = is_on_floor()

	move_and_slide()
	
	if was_on_floor && !is_on_floor():
		can_coyote_jump = true
		coyote_timer.start() 

	if is_on_floor():
		jump_count = 0
		
		
