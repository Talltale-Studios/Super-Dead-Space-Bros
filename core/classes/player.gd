class_name GamePlayer
extends GameCharacter


enum LEG_STATES {
	STAND,
	CROUCH,
	CLIMB,
	RUN,
	JUMP,
	FALL,
}

enum TORSO_STATES {
	AIM,
	SHOOT,
	CLIMB,
}

enum ENVIRONMENTS {
	SURFACE,
	UNDERWATER,
	SPACE,
}


@export var speed : int
@export var max_jumps : int

@export var surface_jump_height : float
@export var surface_jump_time_to_peak : float
@export var surface_jump_time_to_descend : float
@export var surface_grounded_acceleration : float # (float, 0, 1, 0.01)
@export var surface_airborne_acceleration : float # (float, 0, 1, 0.01)
@export var surface_grounded_friction : float # (float, 0, 1, 0.01)
@export var surface_airborne_friction : float # (float, 0, 1, 0.01)
@export var surface_y_velocity_clamp_min : float
@export var surface_y_velocity_clamp_max : float
@export var underwater_jump_height : float
@export var underwater_jump_time_to_peak : float
@export var underwater_jump_time_to_descend : float
@export var underwater_grounded_acceleration : float # (float, 0, 1, 0.01)
@export var underwater_airborne_acceleration : float # (float, 0, 1, 0.01)
@export var underwater_grounded_friction : float # (float, 0, 1, 0.01)
@export var underwater_airborne_friction : float # (float, 0, 1, 0.01)
@export var underwater_y_velocity_clamp_min : float
@export var underwater_y_velocity_clamp_max : float
@export var space_jump_height : float
@export var space_jump_time_to_peak : float
@export var space_jump_time_to_descend : float
@export var space_grounded_acceleration : float # (float, 0, 1, 0.01)
@export var space_airborne_acceleration : float # (float, 0, 1, 0.01)
@export var space_grounded_friction : float # (float, 0, 1, 0.01)
@export var space_airborne_friction : float # (float, 0, 1, 0.01)
@export var space_y_velocity_clamp_min : float
@export var space_y_velocity_clamp_max : float


var leg_state : int = LEG_STATES.STAND
var torso_state : int = TORSO_STATES.AIM
var environment : int = ENVIRONMENTS.SURFACE
var snap_vector : Vector2
var gravity : int
var buffered_jump : bool
var jump_height : int
var jump_time_to_peak : float
var jump_time_to_descend : float
var y_velocity_clamp_min : float
var y_velocity_clamp_max : float
var accel : float
var fric : float
var had_coyote_time : bool = true
var can_jump : bool = true
var has_jumped : bool
var jumps_made : int

var jump_velocity : float:
	get:
		return ((2.0 * jump_height) / jump_time_to_peak) * -1.0
var jump_gravity : float:
	get:
		return ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
var fall_gravity : float:
	get:
		return ((-2.0 * jump_height) / (jump_time_to_descend * jump_time_to_descend)) * -1.0


@onready var torso_sprite : Sprite2D = $TorsoSprite
@onready var legs_sprite : Sprite2D = $LegsSprite
@onready var weaponflash_sprite : Sprite2D = $WeaponflashSprite
@onready var muzzle : Marker2D = $TorsoSprite/Muzzle
@onready var torso_anim_player : AnimationPlayer = $TorsoAnimationPlayer
@onready var legs_anim_player : AnimationPlayer = $LegsAnimationPlayer
@onready var weaponflash_dir_handler : AnimationPlayer = $WeaponflashDirectionHandler
@onready var weaponflash_anim_player : AnimationPlayer = $WeaponflashAnimationPlayer
@onready var legs_anim_tree : AnimationTree = $LegsAnimationTree
@onready var weaponflash_anim_tree : AnimationTree = $WeaponflashAnimationTree
@onready var jump_buffer_timer : Timer = $Timers/JumpBufferTimer
@onready var coyote_timer : Timer = $Timers/CoyoteTimer
@onready var camera : Camera2D = $Camera2D


func _get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity


func _set_gravity_environment(env : String = "surface"):
	if env == "surface":
		jump_height = surface_jump_height
		jump_time_to_peak = surface_jump_time_to_peak
		jump_time_to_descend = surface_jump_time_to_descend
	if env == "underwater":
		jump_height = underwater_jump_height
		jump_time_to_peak = underwater_jump_time_to_peak
		jump_time_to_descend = underwater_jump_time_to_descend
	if env == "space":
		jump_height = space_jump_height
		jump_time_to_peak = space_jump_time_to_peak
		jump_time_to_descend = space_jump_time_to_descend


func _set_velocity_clamp_environment(env : String = "surface"):
	if env == "surface":
		y_velocity_clamp_min = surface_y_velocity_clamp_min
		y_velocity_clamp_max = surface_y_velocity_clamp_max
	if env == "underwater":
		y_velocity_clamp_min = underwater_y_velocity_clamp_min
		y_velocity_clamp_max = underwater_y_velocity_clamp_max
	if env == "space":
		y_velocity_clamp_min = space_y_velocity_clamp_min
		y_velocity_clamp_max = space_y_velocity_clamp_max


func _set_accel_environment(env : String = "surface_grounded"):
	if env.begins_with("surface"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			accel = surface_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			accel = surface_airborne_acceleration
	if env.begins_with("underwater"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			accel = underwater_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			accel = underwater_airborne_acceleration
	if env.begins_with("space"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			accel = space_grounded_acceleration
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			accel = space_airborne_acceleration


func _set_fric_environment(env : String = "surface_grounded"):
	if env.begins_with("surface"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			fric = surface_grounded_friction
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			fric = surface_airborne_friction
	if env.begins_with("underwater"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			fric = underwater_grounded_friction
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			fric = underwater_airborne_friction
	if env.begins_with("space"):
		if not coyote_timer.is_stopped() or env.ends_with("grounded"):
			fric = space_grounded_friction
		elif coyote_timer.is_stopped() and env.ends_with("airborne"):
			fric = space_airborne_friction


func _get_x_input() -> float:
	return Input.get_action_strength("right") - Input.get_action_strength("left")


func _get_direction() -> Vector2:
	return Vector2(_get_x_input(), -1.0 if Input.is_action_just_pressed("jump") and has_jumped else 1.0)


func _apply_gravity(delta):
	if coyote_timer.is_stopped():
		velocity.y += _get_gravity() * delta
		velocity.y = clamp(velocity.y, y_velocity_clamp_min, y_velocity_clamp_max)


func _apply_coyote_time():
	if coyote_timer.is_stopped() and not had_coyote_time and not has_jumped:
		coyote_timer.start()
		velocity.y = 0
		had_coyote_time = true


func _jump():
	velocity.y = jump_velocity
	jumps_made += 1
	coyote_timer.stop()


func _ledge_hop():
	velocity.y = jump_velocity


func _shoot():
	var bullet = preload("res://core/scenes/projectiles/player_test_bullet.tscn").instantiate()
	bullet.spawner = self
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation


func _aim():
	var angle = torso_sprite.global_position.angle_to_point(get_global_mouse_position())
	var degrees = rad_to_deg(angle)
	
	if torso_sprite.get_global_position().distance_to(get_global_mouse_position()) > 50:
		muzzle.look_at(get_global_mouse_position())
	else:
		muzzle.rotation = angle
	
	if degrees >= 0:
		if degrees >= 0 and degrees <= 3.75:
			torso_anim_player.play("right")
		
		elif degrees > 3.75 and degrees <= 11.25:
			torso_anim_player.play("right -1")
		elif degrees > 11.25 and degrees <= 18.75:
			torso_anim_player.play("right -2")
		elif degrees > 18.75 and degrees <= 26.25:
			torso_anim_player.play("right -3")
		elif degrees > 26.25 and degrees <= 33.75:
			torso_anim_player.play("right -4")
		elif degrees > 33.75 and degrees <= 41.25:
			torso_anim_player.play("right -5")
		elif degrees > 41.25 and degrees <= 48.75:
			torso_anim_player.play("right -6")
		elif degrees > 48.75 and degrees <= 56.25:
			torso_anim_player.play("right -7")
		elif degrees > 56.25 and degrees <= 63.75:
			torso_anim_player.play("right -8")
		elif degrees > 63.75 and degrees <= 71.25:
			torso_anim_player.play("right -9")
		elif degrees > 71.25 and degrees <= 78.75:
			torso_anim_player.play("right -10")
		elif degrees > 78.75 and degrees <= 86.25:
			torso_anim_player.play("right -11")
		
		elif degrees > 86.25 and degrees <= 90:
			torso_anim_player.play("down right")
		elif degrees > 90 and degrees <= 93.75:
			torso_anim_player.play("down left")
		
		elif degrees > 93.75 and degrees <= 101.25:
			torso_anim_player.play("left -11")
		elif degrees > 101.25 and degrees <= 108.75:
			torso_anim_player.play("left -10")
		elif degrees > 108.75 and degrees <= 116.25:
			torso_anim_player.play("left -9")
		elif degrees > 116.25 and degrees <= 123.75:
			torso_anim_player.play("left -8")
		elif degrees > 123.75 and degrees <= 131.25:
			torso_anim_player.play("left -7")
		elif degrees > 131.25 and degrees <= 138.75:
			torso_anim_player.play("left -6")
		elif degrees > 138.75 and degrees <= 146.25:
			torso_anim_player.play("left -5")
		elif degrees > 146.25 and degrees <= 153.75:
			torso_anim_player.play("left -4")
		elif degrees > 153.75 and degrees <= 161.25:
			torso_anim_player.play("left -3")
		elif degrees > 161.25 and degrees <= 168.75:
			torso_anim_player.play("left -2")
		elif degrees > 168.75 and degrees <= 176.25:
			torso_anim_player.play("left -1")
		
		elif degrees > 176.25 and degrees <= 180:
			torso_anim_player.play("left")
	
	elif degrees <= 0:
		if degrees <= 0 and degrees >= -3.75:
			torso_anim_player.play("right")
		
		elif degrees < -3.75 and degrees >= -11.25:
			torso_anim_player.play("right +1")
		elif degrees < -11.25 and degrees >= -18.75:
			torso_anim_player.play("right +2")
		elif degrees < -18.75 and degrees >= -26.25:
			torso_anim_player.play("right +3")
		elif degrees < -26.25 and degrees >= -33.75:
			torso_anim_player.play("right +4")
		elif degrees < -33.75 and degrees >= -41.25:
			torso_anim_player.play("right +5")
		elif degrees < -41.25 and degrees >= -48.75:
			torso_anim_player.play("right +6")
		elif degrees < -48.75 and degrees >= -56.25:
			torso_anim_player.play("right +7")
		elif degrees < -56.25 and degrees >= -63.75:
			torso_anim_player.play("right +8")
		elif degrees < -63.75 and degrees >= -71.25:
			torso_anim_player.play("right +9")
		elif degrees < -71.25 and degrees >= -78.75:
			torso_anim_player.play("right +10")
		elif degrees < -78.75 and degrees >= -86.25:
			torso_anim_player.play("right +11")
		
		elif degrees < -86.25 and degrees >= -90:
			torso_anim_player.play("up right")
		elif degrees < -90 and degrees >= -93.75:
			torso_anim_player.play("up left")
		
		elif degrees < -93.75 and degrees >= -101.25:
			torso_anim_player.play("left +11")
		elif degrees < -101.25 and degrees >= -108.75:
			torso_anim_player.play("left +10")
		elif degrees < -108.75 and degrees >= -116.25:
			torso_anim_player.play("left +9")
		elif degrees < -116.25 and degrees >= -123.75:
			torso_anim_player.play("left +8")
		elif degrees < -123.75 and degrees >= -131.25:
			torso_anim_player.play("left +7")
		elif degrees < -131.25 and degrees >= -138.75:
			torso_anim_player.play("left +6")
		elif degrees < -138.75 and degrees >= -146.25:
			torso_anim_player.play("left +5")
		elif degrees < -146.25 and degrees >= -153.75:
			torso_anim_player.play("left +4")
		elif degrees < -153.75 and degrees >= -161.25:
			torso_anim_player.play("left +3")
		elif degrees < -161.25 and degrees >= -168.75:
			torso_anim_player.play("left +2")
		elif degrees < -168.75 and degrees >= -176.25:
			torso_anim_player.play("left +1")
		
		elif degrees < -176.25 and degrees >= -180:
			torso_anim_player.play("left")
