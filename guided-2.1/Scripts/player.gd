extends CharacterBody2D

signal create_after_image

# --- Global / Managers ---
var ReplayManager = null

# --- Konstantan / Skalasi ---
const scaling: float = 6.0

# --- Variabel Gerakan ---
const SPEED: float = 100.0 * scaling # Sesuai request Anda (100.0)
const JUMP_VELOCITY: float = -220.0 * scaling

# --- Variabel Double Jump & Wall ---
const MAX_JUMPS: int = 2 
const WALL_SLIDE_SPEED: float = 20.0 * scaling
const WALL_JUMP_PUSHBACK: float = 220.0 * scaling
const WALL_JUMP_VELOCITY: float = -280.0 * scaling

var jump_count: int = 0 

# --- Variabel Dash ---
const DASH_SPEED: float = 400.0 * scaling
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN_TIME: float = 0.5 

# Variabel 'can_dash' lokal dihapus, diganti logic GameManager
# Variabel 'has_dash' tetap ada untuk cooldown/reset di udara
var is_dashing: bool = false
var has_dash: bool = true

# --- Variabel Status ---
var controls_enabled: bool = true
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var was_on_floor: bool = false
var is_wall_sliding: bool = false
var is_double_jumping: bool = false
var is_wall_jumping: bool = false

# --- Referensi Node Anak ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_buffer_timer: Timer = $JumpBufferTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_orb: Node2D = $DashOrb
@onready var after_image_timer: Timer = $AfterImageTimer
@onready var wall_jump_timer: Timer = $WallJumpTimer
@onready var dash_cooldown_timer: Timer = $DashCooldownTimer

func _ready() -> void:
	# Register player to GameManager
	if has_node("/root/GameManager"):
		GameManager.register_player(self)

	# Try resolve ReplayManager
	if has_node("/root/ReplayManager"):
		ReplayManager = get_node("/root/ReplayManager")

	add_to_group("player")
	set_process_input(true)
	
	# Update visual orb di awal berdasarkan skill yang sudah unlocked
	if dash_orb:
		dash_orb.visible = GameManager.skill_dash_unlocked

func _input(event: InputEvent) -> void:
	if not controls_enabled:
		return

	# Debug toggle keys (Mengubah skill di GameManager secara live)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				GameManager.skill_dash_unlocked = not GameManager.skill_dash_unlocked
				if dash_orb: dash_orb.visible = GameManager.skill_dash_unlocked
				print("Debug: Dash Unlocked =", GameManager.skill_dash_unlocked)
			KEY_2:
				GameManager.skill_double_jump_unlocked = not GameManager.skill_double_jump_unlocked
				print("Debug: Double Jump Unlocked =", GameManager.skill_double_jump_unlocked)
			KEY_3:
				GameManager.skill_wall_grab_unlocked = not GameManager.skill_wall_grab_unlocked
				print("Debug: Wall Grab Unlocked =", GameManager.skill_wall_grab_unlocked)

func _physics_process(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	var on_wall: bool = is_on_wall()

	if not is_dashing:
		if controls_enabled:
			# --- Gravity & Wall Slide Logic ---
			if not on_floor:
				var wall_normal: Vector2 = get_wall_normal()
				var is_pressing_down: bool = Input.is_action_pressed("ui_down")

				# Syarat wall slide:
				# Di dinding, jatuh, tidak wall jump, SKILL AKTIF, dan tidak tekan bawah.
				# Menggunakan GameManager.skill_wall_grab_unlocked
				if on_wall and velocity.y > 0 and not is_wall_jumping and GameManager.skill_wall_grab_unlocked and not is_pressing_down:
					velocity.y = WALL_SLIDE_SPEED
					is_wall_sliding = true
					is_double_jumping = false

					# Sticky Force
					velocity.x = -wall_normal.x * 10.0

					# Visual flip
					if wall_normal.x < 0:
						animated_sprite.flip_h = false
						dash_orb.orbit_offset.x = -abs(dash_orb.orbit_offset.x)
					elif wall_normal.x > 0:
						animated_sprite.flip_h = true
						dash_orb.orbit_offset.x = abs(dash_orb.orbit_offset.x)

					if not has_dash:
						has_dash = true
						if dash_orb and dash_orb.has_method("reset_dash"):
							dash_orb.reset_dash()
				else:
					velocity.y += gravity * delta
					is_wall_sliding = false
			else:
				is_wall_sliding = false

			# Jump input handling
			if Input.is_action_just_pressed("jump"):
				if on_floor or not coyote_timer.is_stopped():
					jump()
				# Cek skill wall grab untuk wall jump
				elif on_wall and not on_floor and GameManager.skill_wall_grab_unlocked:
					wall_jump()
				# Cek skill double jump
				elif jump_count < MAX_JUMPS and GameManager.skill_double_jump_unlocked:
					double_jump()
				else:
					jump_buffer_timer.start()

			# Left / Right movement
			var direction: float = Input.get_axis("ui_left", "ui_right")

			if not is_wall_jumping and not is_wall_sliding:
				if direction != 0.0:
					velocity.x = direction * SPEED
					if direction < 0.0:
						animated_sprite.flip_h = true
						dash_orb.orbit_offset.x = abs(dash_orb.orbit_offset.x)
					else:
						animated_sprite.flip_h = false
						dash_orb.orbit_offset.x = -abs(dash_orb.orbit_offset.x)
				else:
					velocity.x = move_toward(velocity.x, 0.0, SPEED)
			elif is_wall_jumping:
				velocity.x = move_toward(velocity.x, 0.0, 5.0)

	# --- Dash handling ---
	# Cek GameManager.skill_dash_unlocked
	if controls_enabled and Input.is_action_just_pressed("dash") and GameManager.skill_dash_unlocked and not is_dashing and has_dash and dash_cooldown_timer.is_stopped():
		start_dash()

	move_and_slide()

	# Post-movement logic
	if is_on_floor():
		is_double_jumping = false
		is_wall_jumping = false

		if not was_on_floor:
			has_dash = true
			if dash_orb and dash_orb.has_method("reset_dash"):
				dash_orb.reset_dash()
			jump_count = 0
			if not jump_buffer_timer.is_stopped():
				jump()

	if was_on_floor and not is_on_floor() and not is_dashing:
		jump_count = 1
		coyote_timer.start()

	was_on_floor = is_on_floor()
	update_animation()

# --- Helper actions ---

func freeze() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO
	if is_dashing:
		is_dashing = false
		if dash_timer: dash_timer.stop()
		if after_image_timer: after_image_timer.stop()
	set_process_input(false)

func unfreeze() -> void:
	controls_enabled = true
	set_process_input(true)

func jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_count = 1
	is_double_jumping = false
	is_wall_jumping = false
	if coyote_timer: coyote_timer.stop()
	if jump_buffer_timer: jump_buffer_timer.stop()

func double_jump() -> void:
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	is_double_jumping = true
	is_wall_jumping = false
	animated_sprite.play("double_jump")

func wall_jump() -> void:
	velocity.y = WALL_JUMP_VELOCITY
	var wall_normal: Vector2 = get_wall_normal()
	velocity.x = wall_normal.x * WALL_JUMP_PUSHBACK
	is_wall_jumping = true
	if wall_jump_timer: wall_jump_timer.start()
	jump_count = 1
	is_double_jumping = false

	if velocity.x < 0.0:
		animated_sprite.flip_h = true
		if dash_orb and dash_orb.has_method("reset_dash"):
			dash_orb.orbit_offset.x = abs(dash_orb.orbit_offset.x)
	else:
		animated_sprite.flip_h = false
		if dash_orb and dash_orb.has_method("reset_dash"):
			dash_orb.orbit_offset.x = -abs(dash_orb.orbit_offset.x)

func _on_wall_jump_timer_timeout() -> void:
	is_wall_jumping = false

func start_dash() -> void:
	is_dashing = true
	has_dash = false
	is_wall_sliding = false
	is_double_jumping = false
	is_wall_jumping = false
	velocity.y = 0

	var dash_direction: int = 1 if not animated_sprite.flip_h else -1
	velocity.x = dash_direction * DASH_SPEED

	if dash_timer: dash_timer.start(DASH_DURATION)
	if dash_cooldown_timer: dash_cooldown_timer.start(DASH_COOLDOWN_TIME)
	if dash_orb and dash_orb.has_method("use_dash"): dash_orb.use_dash()
	if after_image_timer: after_image_timer.start()

func _on_dash_timer_timeout() -> void:
	is_dashing = false
	velocity.x = move_toward(velocity.x, 0.0, DASH_SPEED)
	if after_image_timer: after_image_timer.stop()

	if is_on_floor():
		has_dash = true
		if dash_orb and dash_orb.has_method("reset_dash"): dash_orb.reset_dash()
		jump_count = 0

func _on_after_image_timer_timeout() -> void:
	emit_signal("create_after_image",
		animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame),
		global_position,
		animated_sprite.flip_h
	)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "double_jump":
		is_double_jumping = false

func update_animation() -> void:
	if is_dashing:
		if animated_sprite.animation != "dash": animated_sprite.play("dash")
		return
	if is_double_jumping:
		if animated_sprite.animation != "double_jump": animated_sprite.play("double_jump")
		return
	if is_wall_sliding:
		if animated_sprite.animation != "crawl": animated_sprite.play("crawl")
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			if animated_sprite.animation != "jump": animated_sprite.play("jump")
		else:
			if animated_sprite.animation != "fall": animated_sprite.play("fall")
	else:
		if velocity.x != 0.0:
			if animated_sprite.animation != "walk": animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle": animated_sprite.play("idle")
