extends CharacterBody2D

signal create_after_image

# --- Variabel Gerakan ---
const SPEED = 100.0
const JUMP_VELOCITY = -220.0

# --- Variabel Double Jump & Wall ---
const MAX_JUMPS = 2 
const WALL_SLIDE_SPEED = 20.0
const WALL_JUMP_PUSHBACK = 220.0 
const WALL_JUMP_VELOCITY = -280.0 

var jump_count = 0 

# --- Variabel Dash ---
const DASH_SPEED = 400.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN_TIME = 0.5 

var can_dash = true
var is_dashing = false
var has_dash = true

# --- Variabel Status ---
var controls_enabled = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var was_on_floor = false
var is_wall_sliding = false
var is_double_jumping = false
var is_wall_jumping = false

# --- Referensi Node Anak ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var jump_buffer_timer = $JumpBufferTimer
@onready var dash_timer = $DashTimer
@onready var dash_orb = $DashOrb
@onready var after_image_timer = $AfterImageTimer
@onready var wall_jump_timer = $WallJumpTimer
@onready var dash_cooldown_timer = $DashCooldownTimer


func _physics_process(delta):
	var on_floor = is_on_floor()
	var on_wall = is_on_wall() 

	# --- Logika Gerakan Normal ---
	if not is_dashing:
		if controls_enabled:
			
			# 1. Gravitasi & Wall Slide
			if not on_floor:
				var direction_input = Input.get_axis("ui_left", "ui_right")
				var pushing_wall = (direction_input < 0 and get_wall_normal().x > 0) or (direction_input > 0 and get_wall_normal().x < 0)
				
				if on_wall and velocity.y > 0 and pushing_wall and not is_wall_jumping:
					velocity.y = WALL_SLIDE_SPEED
					is_wall_sliding = true
					is_double_jumping = false 
					
					if not has_dash:
						has_dash = true
						dash_orb.reset_dash()
				else:
					velocity.y += gravity * delta
					is_wall_sliding = false
			else:
				is_wall_sliding = false

			# 2. Tangani Input Lompat
			if Input.is_action_just_pressed("jump"):
				if on_floor or not coyote_timer.is_stopped():
					jump() 
				elif on_wall and not on_floor:
					wall_jump() 
				elif jump_count < MAX_JUMPS:
					double_jump() 
				else:
					jump_buffer_timer.start()

			# 3. Tangani gerakan kiri/kanan
			var direction = Input.get_axis("ui_left", "ui_right")
			
			if not is_wall_jumping:
				if direction:
					velocity.x = direction * SPEED
					
					# Logika Orb Trailing (Di belakang pemain)
					if direction < 0: 
						animated_sprite.flip_h = true
						dash_orb.orbit_offset.x = abs(dash_orb.orbit_offset.x)
					else: 
						animated_sprite.flip_h = false
						dash_orb.orbit_offset.x = -abs(dash_orb.orbit_offset.x)
				else:
					velocity.x = move_toward(velocity.x, 0, SPEED)
			else:
				velocity.x = move_toward(velocity.x, 0, 5.0)

	# --- Logika Dash ---
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing and has_dash and dash_cooldown_timer.is_stopped():
		start_dash()
	
	move_and_slide()

	# --- Logika Pasca-Gerakan ---
	if is_on_floor():
		is_double_jumping = false 
		is_wall_jumping = false
		
		if not was_on_floor: 
			has_dash = true
			dash_orb.reset_dash()
			jump_count = 0 
			if not jump_buffer_timer.is_stopped():
				jump()
	
	if was_on_floor and not is_on_floor() and not is_dashing:
		jump_count = 1 
		coyote_timer.start()

	was_on_floor = is_on_floor()
	update_animation()


# --- Fungsi Helper ---

func freeze():
	controls_enabled = false
	velocity = Vector2.ZERO

func unfreeze():
	controls_enabled = true

func jump():
	velocity.y = JUMP_VELOCITY
	jump_count = 1 
	is_double_jumping = false 
	is_wall_jumping = false
	coyote_timer.stop()
	jump_buffer_timer.stop()

func double_jump():
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	is_double_jumping = true
	is_wall_jumping = false
	animated_sprite.play("double_jump")
	
func wall_jump():
	velocity.y = WALL_JUMP_VELOCITY
	var wall_normal = get_wall_normal()
	velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
	
	is_wall_jumping = true
	wall_jump_timer.start()
	
	jump_count = 1
	is_double_jumping = false 
	
	if velocity.x < 0: 
		animated_sprite.flip_h = true
		dash_orb.orbit_offset.x = abs(dash_orb.orbit_offset.x)
	else: 
		animated_sprite.flip_h = false
		dash_orb.orbit_offset.x = -abs(dash_orb.orbit_offset.x)

func _on_wall_jump_timer_timeout():
	is_wall_jumping = false

func start_dash():
	is_dashing = true
	has_dash = false
	is_wall_sliding = false
	is_double_jumping = false 
	is_wall_jumping = false 
	velocity.y = 0
	
	var dash_direction = 1 if not animated_sprite.flip_h else -1
	velocity.x = dash_direction * DASH_SPEED
	
	dash_timer.start(DASH_DURATION)
	dash_cooldown_timer.start(DASH_COOLDOWN_TIME)
	
	dash_orb.use_dash()
	after_image_timer.start()

func _on_dash_timer_timeout():
	is_dashing = false
	velocity.x = move_toward(velocity.x, 0, DASH_SPEED)
	after_image_timer.stop()
	
	if is_on_floor():
		has_dash = true
		dash_orb.reset_dash()
		jump_count = 0

func _on_after_image_timer_timeout():
	emit_signal("create_after_image", animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame), global_position, animated_sprite.flip_h)

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "double_jump":
		is_double_jumping = false

func update_animation():
	if is_dashing:
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
		return

	if is_double_jumping:
		if animated_sprite.animation != "double_jump":
			animated_sprite.play("double_jump")
		return

	if is_wall_sliding:
		if animated_sprite.animation != "crawl":
			animated_sprite.play("crawl")
		return

	if not is_on_floor():
		if velocity.y < 0:
			if animated_sprite.animation != "jump":
				animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall":
				animated_sprite.play("fall")
	else:
		if velocity.x != 0:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
