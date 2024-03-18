class_name GameMovementComponent
extends Node2D


signal dashed
signal jumped
signal coyote_time_started
signal coyote_time_finished
signal jump_buffer_started
signal jump_buffer_finished
signal wall_jumped(normal: Vector2)
signal wall_cling_started
signal wall_cling_finished
signal wall_slide_started
signal wall_slide_finished
signal wall_climb_started
signal wall_climb_finished
signal knockback_received(direction: Vector2)
signal gravity_changed(enabled: bool)
signal inverted_gravity(inverted: bool)


enum ENVIRONMENTS {
	SURFACE,
	UNDERWATER,
	SPACE,
}


@export_node_path("PhysicsBody2D") var actor

@export_group("Speed")
## The speed at which this character starts when it begins to move.
@export var initial_speed: int
## The maximum speed this character can reach.
@export var max_speed: int
@export var speed: int

@export_group("Dash")
## The speed multiplier would be applied to the player velocity on runtime.
@export var dash_speed_multiplier: float = 1.5
## The amount of times this character is allowed to  dash until the cooldown is
## activated.
@export var times_can_dash: int = 1
## The time it takes for the dash ability to become available again.
@export var dash_cooldown: float = 1.5
@export var dash_gravity_time_disabled: float = 0.2

@export_group("Jump")
## The value represents a velocity threshold that determines whether the
## character can jump.
@export var jump_velocity_threshold: float = 300.0
## The amount of jumps the character is allowed to perform in a row.
@export var times_can_jump: int = 1
## The time window in which the character can execute a jump when coyote time
## is active.
@export var coyote_jump_time_window: float = 0.1
## The time window this jump can be executed when the character is not on the
## floor.
@export var jump_buffer_time_window: float = 0.05

@export_group("Wall Cling")
## How long the character can cling to the wall before falling off or beginning
## to slide.
## Set to 0 to make it infinite.
@export var wall_cling_duration: float = 2.0

@export_group("Wall Jump")
## Defines whether the wall jump is counted as a jump in the overall count.
@export var wall_jump_count_as_jump: bool = false
## The maximum angle of deviation that a wall can have to allow the jump to be
## executed.
@export var max_permissible_wall_angle : float = 0.0

@export_group("Wall Slide")
## How long the character can slide on the wall before falling off.
## Set to 0 to make it infinite.
@export var wall_slide_duration: float = 2.0

@export_group("Wall Climb")
## The speed when climb upwards
@export var wall_climb_speed_up: float = 450.0
## The speed when climb downwards
@export var wall_climb_speed_down: float = 500.0
## The force applied when the time it can climb reachs the timeout
@export var wall_climb_fatigue_knockback: float = 100.0
## How long the character can climb up the wall before falling off or beginning
## to slide.
## Set to 0 to make it infinite.
@export var wall_climb_duration: float = 2.0
## Time that the climb action is disabled when the fatigue timeout is triggered.
@export var wall_climb_fatigue_cooldown: float = 0.7

@export_group("Knockback")
## The amount of power the character is pushed in the direction of the force
## source.
@export var knockback_power: int = 250

@export_group("Gravity")
## The duration for which gravity will be suspended.
@export var suspend_gravity_duration: float = 1

@export_group("Environments")
@export_subgroup("Surface", "surface")
@export var surface_jump_height: float
@export var surface_jump_release_velocity_cut: float
@export var surface_jump_time_to_peak: float
@export var surface_jump_time_to_drop: float
@export var surface_multijump_height_reduction: float
@export var surface_wall_slide_gravity: float
@export var surface_wall_climb_gravity: float
@export var surface_grounded_acceleration: float
@export var surface_airborne_acceleration: float
@export var surface_grounded_friction: float
@export var surface_airborne_friction: float
@export var surface_max_downwards_velocity: float
@export var surface_max_upwards_velocity: float
@export var surface_max_rightwards_velocity: float
@export var surface_max_leftwards_velocity: float
@export_subgroup("Underwater", "underwater")
@export var underwater_jump_height: float
@export var underwater_jump_release_velocity_cut: float
@export var underwater_jump_time_to_peak: float
@export var underwater_jump_time_to_drop: float
@export var underwater_multijump_height_reduction: float
@export var underwater_wall_slide_gravity: float
@export var underwater_wall_climb_gravity: float
@export var underwater_grounded_acceleration: float
@export var underwater_airborne_acceleration: float
@export var underwater_grounded_friction: float
@export var underwater_airborne_friction: float
@export var underwater_max_downwards_velocity: float
@export var underwater_max_upwards_velocity: float
@export var underwater_max_rightwards_velocity: float
@export var underwater_max_leftwards_velocity: float
@export_subgroup("Space", "space")
@export var space_jump_height: float
@export var space_jump_release_velocity_cut: float
@export var space_jump_time_to_peak: float
@export var space_jump_time_to_drop: float
@export var space_multijump_height_reduction: float
@export var space_wall_slide_gravity: float
@export var space_wall_climb_gravity: float
@export var space_grounded_acceleration: float
@export var space_airborne_acceleration: float
@export var space_grounded_friction: float
@export var space_airborne_friction: float
@export var space_max_downwards_velocity: float
@export var space_max_upwards_velocity: float
@export var space_max_rightwards_velocity: float
@export var space_max_leftwards_velocity: float


## This value affects the time it takes the character to reach its
## [code]max_speed[/code], starting from its [code]initial_speed[/code].
var acceleration: float
## This value affects the time it takes the character to decelerate to a
## standstill.
var friction: float

var environment: int = ENVIRONMENTS.SURFACE
var snap_vector: Vector2
var gravity: int

## The maximum height the character can reach when jumping.
var jump_height: float:
	set(value):
		jump_height = value
		jump_velocity = calculate_jump_velocity(jump_height, jump_time_to_peak)
		jump_gravity = calculate_jump_gravity(jump_height, jump_time_to_peak )
		fall_gravity = calculate_fall_gravity(jump_height, jump_time_to_drop)
	get:
		return jump_height

## How much of the jump's velocity is lost when the jump is released.
var jump_release_velocity_cut: float

## The time it takes the character to reach the maximum jump height.
var jump_time_to_peak: float:
	set(value):
		jump_time_to_peak = value
		jump_velocity = calculate_jump_velocity(jump_height, jump_time_to_peak)
		jump_gravity = calculate_jump_gravity(jump_height, jump_time_to_peak )
	get:
		return jump_time_to_peak

## The time it takes the character to reach the floor after a jump.
var jump_time_to_drop: float:
	set(value):
		jump_time_to_drop = value
		fall_gravity = calculate_fall_gravity(jump_height, jump_time_to_drop)
	get:
		return jump_time_to_drop

## Reduced amount of jump effectiveness at each iteration.
var multijump_height_reduction: float
## The amount of gravity applied while wall sliding.
var wall_slide_gravity: float
var wall_climb_gravity: float

var max_downwards_velocity: float
var max_upwards_velocity: float
var max_rightwards_velocity: float
var max_leftwards_velocity: float

var had_coyote_time: bool = true
var has_jumped: bool

var is_gravity_enabled: bool = true:
	set(value):
		if value != is_gravity_enabled:
			gravity_changed.emit(value)
			
		is_gravity_enabled = value

var is_gravity_inverted: bool = false

var times_jumped: int
var times_dashed: int

var velocity: Vector2 = Vector2.ZERO

var facing_direction: Vector2 = Vector2.ZERO
var last_faced_direction: Vector2 = Vector2.DOWN

var is_dashing: bool = false
var is_wall_jumping: bool =  false
var is_wall_clinging: bool =  false

var is_wall_sliding: bool =  false:
	set(value):
		if value != is_wall_sliding:
			if value:
				wall_slide_started.emit()
			else:
				wall_slide_finished.emit()
		
		is_wall_sliding = value

var is_wall_climbing: bool = false:
	set(value):
		if value != is_wall_climbing:
			if value:
				wall_climb_started.emit()
			else:
				wall_climb_finished.emit()
		
		is_wall_climbing = value

var is_jump_buffered: bool

var dash_cooldown_timer: Timer
var dash_duration_timer: Timer
var wall_climb_timer: Timer
var suspend_gravity_timer: Timer
var coyote_timer: Timer
var jump_buffer_timer: Timer


@onready var jump_velocity: float = calculate_jump_velocity()
@onready var jump_gravity: float = calculate_jump_gravity()
@onready var fall_gravity: float = calculate_fall_gravity()


func can_dash() -> bool:
	return times_dashed < times_can_dash and dash_cooldown > 0 \
		and times_can_dash > 0 and not velocity.is_zero_approx()


func can_jump() -> bool:
	if not can_wall_slide() and not can_wall_climb():
		if actor.is_on_floor() or (GameSettings.is_coyote_jump_enabled \
			and coyote_timer.time_left > 0.0):
				return true
		else:
			return (velocity.y < absf(jump_velocity_threshold) \
				or (is_gravity_inverted and velocity.y \
				< -absf(jump_velocity_threshold))) and times_jumped >= 1 \
				and times_jumped < times_can_jump
	
	return false


func can_wall_jump() -> bool:
	return GameSettings.is_wall_jump_enabled and actor.is_on_wall() \
		and not actor.is_on_ceiling() and not velocity.y == 0


func can_wall_slide() -> bool:
	return GameSettings.is_wall_slide_enabled and not is_wall_climbing \
		and actor.is_on_wall() and not actor.is_on_floor() \
		and not actor.is_on_ceiling()


func can_wall_climb(direction: Vector2 = facing_direction) -> bool:
	return GameSettings.is_wall_climb_enabled and (direction.is_equal_approx(
		Vector2.UP) or direction.is_equal_approx(Vector2.DOWN)) \
		and actor.is_on_wall() and not actor.is_on_ceiling()


func is_within_jumping_threshold() -> bool:
	var is_within_threshold = jump_velocity_threshold > 0 \
		and velocity.y < jump_velocity_threshold
	
	if is_gravity_inverted:
		is_within_threshold = jump_velocity_threshold < 0 and velocity.y \
			> jump_velocity_threshold
	
	return is_within_threshold


func is_coyote_time_active() -> bool:
	if GameSettings.is_coyote_time_enabled and not coyote_timer.is_stopped():
		return true
	else:
		return false


func is_jump_buffer_active() -> bool:
	if GameSettings.is_jump_buffer_enabled and not jump_buffer_timer.is_stopped():
		return true
	else:
		return false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var parent_node = get_parent()
	
	if parent_node == null or not parent_node is Node2D:
		warnings.append("This component needs a Node2D parent in order to work 
			properly")
		
	return warnings


func _ready():
	_create_coyote_timer()
	_create_dash_duration_timer()
	_create_wall_climb_timer()
	
	gravity_changed.connect(on_gravity_changed)
	jumped.connect(on_jumped)
	wall_jumped.connect(on_jumped)
	wall_climb_started.connect(on_wall_climb_started)
	wall_climb_finished.connect(on_wall_climb_finished)
	wall_jumped.connect(on_wall_jumped)


func move() -> void:
	if get_node_or_null(actor):
		var was_on_floor: bool = actor.is_on_floor()

		actor.velocity = velocity
		actor.move_and_slide()
		
		check_coyote_jump_time_window(was_on_floor)
		reset_times_jumped()


func move_and_collide() -> KinematicCollision2D:
	if get_node_or_null(actor):
		var was_on_floor: bool = actor.is_on_floor()
	
		actor.velocity = velocity
		var collision: KinematicCollision2D = actor.move_and_collide(
			actor.velocity * get_physics_process_delta_time())
		
		check_coyote_jump_time_window(was_on_floor)
		reset_times_jumped()
		
		return collision
	else:
		return null


func accelerate_in_direction(direction: Vector2) -> void:
	if not direction.is_zero_approx():
		last_faced_direction = direction
		
	facing_direction = direction
	
	if acceleration > 0:
		velocity = velocity.move_toward(facing_direction * max_speed, 
			acceleration * get_physics_process_delta_time())
	else:
		velocity = facing_direction * max_speed


func accelerate_to_target(target: Node2D) -> void:
	var target_direction: Vector2 = (target.global_position - global_position).normalized()
	
	return accelerate_in_direction(target_direction)


func accelerate_to_position(position: Vector2) -> void:
	var target_direction: Vector2 = (position - global_position).normalized()
	
	return accelerate_in_direction(target_direction)


func decelerate() -> void:
	if friction > 0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * get_physics_process_delta_time())
	else:
		velocity = Vector2.ZERO


func knockback(direction: Vector2, power: int = knockback_power) -> void:
	var knockback_direction: Vector2 = (direction if direction.is_normalized() else direction.normalized()) * max(1, power)
	velocity = knockback_direction
	move()
	
	knockback_received.emit(direction)


func dash() -> void:
	if can_dash():
		apply_dash()


func apply_dash(target_direction: Vector2 = facing_direction, speed_multiplier: float = dash_speed_multiplier) -> void:
	times_dashed += 1
	
	velocity += target_direction * (max_speed * speed_multiplier)
	facing_direction = target_direction
	
	_create_dash_cooldown_timer()
	_create_dash_duration_timer()
	
	move()
			
	dashed.emit()


func calculate_jump_velocity(height: int = jump_height, time_to_peak: float = jump_time_to_peak) -> float:
	var y_axis: float = 1.0 if is_gravity_inverted else -1.0
	return ((2.0 * height) / time_to_peak) * y_axis


func calculate_jump_gravity(height: int = jump_height, time_to_peak: float = jump_time_to_peak) -> float:
	return (2.0 * height) / pow(time_to_peak, 2)


func calculate_fall_gravity(height: int = jump_height, time_to_drop: float = jump_time_to_drop) -> float:
	return (2.0 * height) / pow(time_to_drop, 2)


func get_gravity() -> float:
	if is_gravity_inverted:
		return jump_gravity if velocity.y > 0.0 else fall_gravity
	else:
		return jump_gravity if velocity.y < 0.0 else fall_gravity


func apply_gravity() -> void:
	if is_gravity_enabled:
		var gravity_force = get_gravity() * get_physics_process_delta_time()
		
		if is_gravity_inverted:
			velocity.y -= gravity_force
		else:
			velocity.y += gravity_force


func limit_y_velocity() -> void:
	if max_downwards_velocity > 0:
		if is_gravity_inverted:
			velocity.y = max(velocity.y, -max_downwards_velocity)
		else:
			min(velocity.y, absf(max_downwards_velocity))
	
	if max_upwards_velocity > 0:
		if is_gravity_inverted:
			velocity.y = min(velocity.y, absf(max_upwards_velocity))
		else:
			max(velocity.y, -max_upwards_velocity)


func limit_x_velocity() -> void:
	if max_rightwards_velocity > 0:
		if is_gravity_inverted:
			velocity.y = max(velocity.y, -max_rightwards_velocity)
		else:
			min(velocity.y, absf(max_rightwards_velocity))
	
	if max_leftwards_velocity > 0:
		if is_gravity_inverted:
			velocity.y = min(velocity.y, absf(max_leftwards_velocity))
		else:
			max(velocity.y, -max_leftwards_velocity)


func invert_gravity() -> void:
	if is_gravity_enabled:
		jump_velocity = -jump_velocity
		
		if GameSettings.is_wall_slide_enabled:
			wall_slide_gravity = -wall_slide_gravity
			
		if jump_velocity > 0:
			is_gravity_inverted = true
		
		if is_gravity_inverted:
			actor.up_direction = Vector2.DOWN
		else:
			actor.up_direction = Vector2.UP
		
		inverted_gravity.emit(is_gravity_inverted)


func suspend_gravity_for_duration(duration: float) -> void:
	if duration > 0:
		is_gravity_enabled = false
	suspend_gravity_timer.wait_time = max(0.05, duration)
	suspend_gravity_timer.start()


func toggle_gravity() -> void:
	is_gravity_enabled = !is_gravity_enabled


func reset_times_jumped() -> void:
		times_jumped = 0


func reset_times_dashed() -> void:
		times_dashed = 0


func jump():
	if can_jump():
		apply_jump()
	
	return self


func apply_jump() -> void:
	jumped.emit()
	times_jumped += 1
	is_wall_sliding = false
	is_wall_climbing = false
	
	if times_jumped > 1 and multijump_height_reduction > 0:
		var jump_height_reduced: float = max(0, times_jumped - 1) \
			* multijump_height_reduction
		velocity.y = calculate_jump_velocity(jump_height - jump_height_reduced)
	else:
		velocity.y = calculate_jump_velocity(jump_height)


func wall_jump(direction: Vector2):
	if can_wall_jump():
		var wall_normal = actor.get_wall_normal()
		var left_angle = abs(wall_normal.angle_to(Vector2.LEFT))
		var right_angle = abs(wall_normal.angle_to(Vector2.RIGHT))
		
		if is_wall_sliding or is_wall_climbing:
			apply_wall_jump(wall_normal)
		elif wall_normal.is_equal_approx(Vector2.LEFT) or left_angle \
			<= max_permissible_wall_angle:
				apply_wall_jump(wall_normal)
		elif wall_normal.is_equal_approx(Vector2.RIGHT) or right_angle \
			<= max_permissible_wall_angle:
				apply_wall_jump(wall_normal)
	
	return self


func apply_wall_jump(wall_normal: Vector2) -> void:
	velocity.x = wall_normal.x * max_speed
	velocity.y = jump_velocity
	if wall_jump_count_as_jump:
		times_jumped += 1
	else:
		reset_times_jumped()
	
	wall_jumped.emit(wall_normal)


func wall_climb(direction: Vector2 = Vector2.ZERO):
	is_wall_climbing = can_wall_climb(direction)
	
	if is_wall_climbing:
		if is_gravity_enabled:
			wall_climb_started.emit()
		
		var is_climbing_up = direction.is_equal_approx(Vector2.UP)
		var wall_climb_speed_direction = wall_climb_speed_up if is_climbing_up \
			else wall_climb_speed_down
		var climb_force = wall_climb_speed_direction * get_physics_process_delta_time()
		
		if is_gravity_inverted:
			if not is_climbing_up:
				climb_force *= -1
		else:
			if is_climbing_up:
				climb_force *= -1
			
		velocity.y += climb_force
		
		if is_gravity_inverted:
			velocity.y = min(velocity.y, wall_climb_speed_direction) \
				if is_climbing_up else max(velocity.y, -wall_climb_speed_direction)
		else:
			velocity.y = max(velocity.y, -wall_climb_speed_direction) \
				if is_climbing_up else min(velocity.y, wall_climb_speed_direction)
	
	else:
		if not is_gravity_enabled:
			wall_climb_finished.emit()
	
	return self


func wall_slide():
	is_wall_sliding = can_wall_slide()
	
	if not is_wall_climbing and is_wall_sliding:
		velocity.y += wall_slide_gravity * get_physics_process_delta_time()
		velocity.y = max(velocity.y, wall_slide_gravity) if is_gravity_inverted \
			else min(velocity.y, wall_slide_gravity)
	
	return self


func check_coyote_jump_time_window(was_on_floor: bool = true) -> void:
	if GameSettings.is_coyote_jump_enabled:
		var just_left_ledge = was_on_floor and not actor.is_on_floor() \
			and (velocity.y >= 0 or (is_gravity_inverted and velocity.y <= 0))
		
		if just_left_ledge:
			coyote_timer.start()


func check_jump_buffer_time_window(was_on_floor: bool = true) -> void:
	jump_buffer_timer.start()


func enable_dash(cooldown: float = dash_cooldown, times: int = times_can_dash):
	dash_cooldown = cooldown
	times_can_dash = times


func _create_dash_cooldown_timer() -> void:
	if dash_cooldown_timer:
		return
	
	dash_cooldown_timer = Timer.new()
	dash_cooldown_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	dash_cooldown_timer.wait_time = max(0.05, dash_cooldown)
	dash_cooldown_timer.one_shot = true
	dash_cooldown_timer.autostart = false
	
	add_child(dash_cooldown_timer)
	dash_cooldown_timer.timeout.connect(on_dash_cooldown_timer_timeout)


func _create_dash_duration_timer() -> void:
	if dash_duration_timer:
		return
	
	dash_duration_timer = Timer.new()
	dash_duration_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	dash_duration_timer.wait_time = dash_gravity_time_disabled
	dash_duration_timer.one_shot = true
	dash_duration_timer.autostart = false
	
	add_child(dash_duration_timer)
	dash_duration_timer.timeout.connect(on_dash_duration_timer_timeout)


func _create_wall_climb_timer() -> void:
	if wall_climb_timer:
		return
	
	wall_climb_timer = Timer.new()
	wall_climb_timer.name = "WallClimbTimer"
	wall_climb_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	wall_climb_timer.wait_time = wall_climb_duration
	wall_climb_timer.one_shot = true
	wall_climb_timer.autostart = false
	
	add_child(wall_climb_timer)
	wall_climb_timer.timeout.connect(on_wall_climb_timer_timeout)


func _create_suspend_gravity_timer() -> void:
	if suspend_gravity_timer:
		return
	
	suspend_gravity_timer = Timer.new()
	suspend_gravity_timer.name = "SuspendGravityTimer"
	suspend_gravity_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	suspend_gravity_timer.wait_time = suspend_gravity_duration
	suspend_gravity_timer.one_shot = true
	suspend_gravity_timer.autostart = false
	
	add_child(suspend_gravity_timer)
	suspend_gravity_timer.timeout.connect(on_suspend_gravity_timeout)


func _create_coyote_timer() -> void:
	if coyote_timer:
		return
	
	coyote_timer = Timer.new()
	coyote_timer.name = "CoyoteTimer"
	coyote_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	coyote_timer.wait_time = coyote_jump_time_window
	coyote_timer.one_shot = true
	coyote_timer.autostart = false
	
	add_child(coyote_timer)


func _create_jump_buffer_timer() -> void:
	if jump_buffer_timer:
		return
	
	jump_buffer_timer = Timer.new()
	jump_buffer_timer.name = "JumpBufferTimer"
	jump_buffer_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	jump_buffer_timer.wait_time = jump_buffer_time_window
	jump_buffer_timer.one_shot = true
	jump_buffer_timer.autostart = false
	
	add_child(jump_buffer_timer)


func on_dash_cooldown_timer_timeout(timer: Timer) -> void:
	times_dashed -= 1


func on_dash_duration_timer_timeout(timer: Timer) -> void:
	is_gravity_enabled = true


func on_wall_climb_timer_timeout() -> void:
	is_gravity_enabled = true
	GameSettings.is_wall_climb_enabled = false
	wall_climb_finished.emit()
	
	knockback(actor.get_wall_normal(), wall_climb_fatigue_knockback)
	
	if wall_climb_fatigue_cooldown > 0:
		await (get_tree().create_timer(wall_climb_fatigue_cooldown)).timeout
	
	GameSettings.is_wall_climb_enabled = true


func on_suspend_gravity_timeout(timer: Timer) -> void:
	timer.queue_free()
	is_gravity_enabled = true


func on_coyote_time_started() -> void:
	is_gravity_enabled = false
	coyote_timer.start()


func on_coyote_timer_timeout() -> void:
	is_gravity_enabled = true


func on_jumped() -> void:
	is_gravity_enabled = true
	is_wall_climbing = false
	is_wall_sliding = false
	is_dashing = false
	
	coyote_timer.stop()


func on_wall_jumped(normal: Vector2) -> void:
	if not normal.is_zero_approx():
		facing_direction = normal
		last_faced_direction = normal


func on_wall_climb_started() -> void:
	is_gravity_enabled = false
	wall_climb_timer.start()


func on_wall_climb_finished() -> void:
	is_gravity_enabled = true
	wall_climb_timer.stop()


func on_gravity_changed(enabled: bool) -> void:
	if not enabled:
		velocity.y = 0


func set_environment_variables() -> void:
	match environment:
		ENVIRONMENTS.SURFACE:
			_set_jump_height_env("surface")
			_set_jump_time_to_peak_env("surface")
			_set_jump_time_to_drop_env("surface")
			_set_multijump_height_reduction_env("surface")
			_set_wall_slide_gravity_env("surface")
			_set_wall_climb_gravity_env("surface")
			_set_jump_release_vel_cut_env("surface")
			_set_max_downwards_vel_env("surface")
			_set_max_upwards_vel_env("surface")
			_set_max_rightwards_vel_env("surface")
			_set_max_leftwards_vel_env("surface")
			if actor.is_on_floor() or actor.is_on_wall() or actor.is_on_ceiling():
				_set_accel_env("surface_grounded")
				_set_fric_env("surface_grounded")
			else:
				_set_accel_env("surface_airborne")
				_set_fric_env("surface_airborne")
		
		ENVIRONMENTS.UNDERWATER:
			_set_jump_height_env("underwater")
			_set_jump_time_to_peak_env("underwater")
			_set_jump_time_to_drop_env("underwater")
			_set_multijump_height_reduction_env("underwater")
			_set_wall_slide_gravity_env("underwater")
			_set_wall_climb_gravity_env("underwater")
			_set_jump_release_vel_cut_env("underwater")
			_set_max_downwards_vel_env("underwater")
			_set_max_upwards_vel_env("underwater")
			_set_max_rightwards_vel_env("underwater")
			_set_max_leftwards_vel_env("underwater")
			if actor.is_on_floor() or actor.is_on_wall() or actor.is_on_ceiling():
				_set_accel_env("underwater_grounded")
				_set_fric_env("underwater_grounded")
			else:
				_set_accel_env("underwater_airborne")
				_set_fric_env("underwater_airborne")
		
		ENVIRONMENTS.SPACE:
			_set_jump_height_env("space")
			_set_jump_time_to_peak_env("space")
			_set_jump_time_to_drop_env("space")
			_set_multijump_height_reduction_env("space")
			_set_wall_slide_gravity_env("space")
			_set_wall_climb_gravity_env("space")
			_set_jump_release_vel_cut_env("space")
			_set_max_downwards_vel_env("space")
			_set_max_upwards_vel_env("space")
			_set_max_rightwards_vel_env("space")
			_set_max_leftwards_vel_env("space")
			if actor.is_on_floor() or actor.is_on_wall() or actor.is_on_ceiling():
				_set_accel_env("space_grounded")
				_set_fric_env("space_grounded")
			else:
				_set_accel_env("space_airborne")
				_set_fric_env("space_airborne")


func _set_jump_height_env(env: String = "surface") -> void:
	if env == "surface":
		jump_height = surface_jump_height
	
	if env == "underwater":
		jump_height = underwater_jump_height
	
	if env == "space":
		jump_height = space_jump_height


func _set_jump_time_to_peak_env(env: String = "surface") -> void:
	if env == "surface":
		jump_time_to_peak = surface_jump_time_to_peak
	
	if env == "underwater":
		jump_time_to_peak = underwater_jump_time_to_peak
	
	if env == "space":
		jump_time_to_peak = space_jump_time_to_peak


func _set_jump_time_to_drop_env(env: String = "surface") -> void:
	if env == "surface":
		jump_time_to_drop = surface_jump_time_to_drop
	
	if env == "underwater":
		jump_time_to_drop = underwater_jump_time_to_drop
	
	if env == "space":
		jump_time_to_drop = space_jump_time_to_drop


func _set_multijump_height_reduction_env(env: String = "surface") -> void:
	if env == "surface":
		multijump_height_reduction = surface_multijump_height_reduction
	
	if env == "underwater":
		multijump_height_reduction = underwater_multijump_height_reduction
	
	if env == "space":
		multijump_height_reduction = space_multijump_height_reduction


func _set_wall_slide_gravity_env(env: String = "surface") -> void:
	if env == "surface":
		wall_slide_gravity = surface_wall_slide_gravity
	
	if env == "underwater":
		wall_slide_gravity = underwater_wall_slide_gravity
	
	if env == "space":
		wall_slide_gravity = space_wall_slide_gravity


func _set_wall_climb_gravity_env(env: String = "surface") -> void:
	if env == "surface":
		wall_climb_gravity = surface_wall_climb_gravity
	
	if env == "underwater":
		wall_climb_gravity = underwater_wall_climb_gravity
	
	if env == "space":
		wall_climb_gravity = space_wall_climb_gravity


func _set_jump_release_vel_cut_env(env: String = "surface_grounded") -> void:
	if env == "surface":
		jump_release_velocity_cut = surface_jump_release_velocity_cut
	
	if env == "underwater":
		jump_release_velocity_cut = underwater_jump_release_velocity_cut
	
	if env == "space":
		jump_release_velocity_cut = space_jump_release_velocity_cut


func _set_max_downwards_vel_env(env: String = "surface") -> void:
	if env == "surface":
		max_downwards_velocity = surface_max_downwards_velocity
	
	if env == "underwater":
		max_downwards_velocity = underwater_max_downwards_velocity
	
	if env == "space":
		max_downwards_velocity = space_max_downwards_velocity


func _set_max_upwards_vel_env(env: String = "surface") -> void:
	if env == "surface":
		max_upwards_velocity = surface_max_upwards_velocity
	
	if env == "underwater":
		max_upwards_velocity = underwater_max_upwards_velocity
	
	if env == "space":
		max_upwards_velocity = space_max_upwards_velocity


func _set_max_rightwards_vel_env(env: String = "surface") -> void:
	if env == "surface":
		max_rightwards_velocity = surface_max_rightwards_velocity
	
	if env == "underwater":
		max_rightwards_velocity = underwater_max_rightwards_velocity
	
	if env == "space":
		max_rightwards_velocity = space_max_rightwards_velocity


func _set_max_leftwards_vel_env(env: String = "surface") -> void:
	if env == "surface":
		max_leftwards_velocity = surface_max_leftwards_velocity
	
	if env == "underwater":
		max_leftwards_velocity = underwater_max_leftwards_velocity
	
	if env == "space":
		max_leftwards_velocity = space_max_leftwards_velocity


func _set_accel_env(env: String = "surface_grounded") -> void:
	if env.begins_with("surface"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			acceleration = surface_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			acceleration = surface_airborne_acceleration
	
	if env.begins_with("underwater"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			acceleration = underwater_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			acceleration = underwater_airborne_acceleration
	
	if env.begins_with("space"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			acceleration = space_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			acceleration = space_airborne_acceleration


func _set_fric_env(env: String = "surface_grounded") -> void:
	if env.contains("surface"):
		if not coyote_timer.is_stopped() or env.contains("grounded"):
			friction = surface_grounded_friction
		elif coyote_timer.is_stopped() and env.contains("airborne"):
			friction = surface_airborne_friction
	
	if env.contains("underwater"):
		if not coyote_timer.is_stopped() or env.contains("grounded"):
			friction = underwater_grounded_friction
		elif coyote_timer.is_stopped() and env.contains("airborne"):
			friction = underwater_airborne_friction
	
	if env.contains("space"):
		if not coyote_timer.is_stopped() or env.contains("grounded"):
			friction = space_grounded_friction
		elif coyote_timer.is_stopped() and env.contains("airborne"):
			friction = space_airborne_friction
