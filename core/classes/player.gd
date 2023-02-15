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


export var speed : int
export var jump_power : int
export var max_jumps : int
export var surface_gravity : int
export var underwater_gravity : int
export var space_gravity : int
export(float, 0, 1, 0.01) var surface_grounded_acceleration : float
export(float, 0, 1, 0.01) var surface_airborne_acceleration : float
export(float, 0, 1, 0.01) var underwater_grounded_acceleration : float
export(float, 0, 1, 0.01) var underwater_afloat_acceleration : float
export(float, 0, 1, 0.01) var space_grounded_acceleration : float
export(float, 0, 1, 0.01) var space_afloat_acceleration : float
export(float, 0, 1, 0.01) var surface_grounded_friction : float
export(float, 0, 1, 0.01) var surface_airborne_friction : float
export(float, 0, 1, 0.01) var underwater_grounded_friction : float
export(float, 0, 1, 0.01) var underwater_afloat_friction : float
export(float, 0, 1, 0.01) var space_grounded_friction : float
export(float, 0, 1, 0.01) var space_afloat_friction : float

export var up_direction : Vector2
export var stop_on_slope : bool
export var max_slides : int
export var floor_max_angle : float
export var infinite_inertia : bool


var leg_state : int = LEG_STATES.STAND
var torso_state : int = TORSO_STATES.AIM
var environment : int = ENVIRONMENTS.SURFACE

var snap_vector : Vector2
var velocity : Vector2
var gravity : int
var accel : float
var fric : float
var can_jump : bool = true
var is_jumping : bool
var has_jumped : bool
var jumps_made : int


onready var torso_sprite : Sprite = $TorsoSprite
onready var legs_sprite : Sprite = $LegsSprite
onready var weaponflash_sprite : Sprite = $WeaponflashSprite
onready var muzzle : Position2D = $Muzzle
onready var torso_anim_player : AnimationPlayer = $TorsoAnimationPlayer
onready var legs_anim_player : AnimationPlayer = $LegsAnimationPlayer
onready var weaponflash_dir_handler : AnimationPlayer = $WeaponflashDirectionHandler
onready var weaponflash_anim_player : AnimationPlayer = $WeaponflashAnimationPlayer
onready var legs_anim_tree : AnimationTree = $LegsAnimationTree
onready var weaponflash_anim_tree : AnimationTree = $WeaponflashAnimationTree
onready var camera : Camera2D = $Camera2D


func _set_gravity(type : String = "surface"):
	if type == "surface":
		gravity = surface_gravity
	if type == "underwater":
		gravity = underwater_gravity
	if type == "space":
		gravity = space_gravity


func _set_accel(type : String = "surface_grounded"):
	if type == "surface_grounded":
		accel = surface_grounded_acceleration
	if type == "surface_airborne":
		accel = surface_airborne_acceleration
	if type == "underwater_grounded":
		accel = underwater_grounded_acceleration
	if type == "underwater_afloat":
		accel = underwater_afloat_acceleration
	if type == "space_grounded":
		accel = space_grounded_acceleration
	if type == "space_afloat":
		accel = space_afloat_acceleration


func _set_fric(type : String = "surface_grounded"):
	if type == "surface_grounded":
		fric = surface_grounded_friction
	if type == "surface_airborne":
		fric = surface_airborne_friction
	if type == "underwater_grounded":
		fric = underwater_grounded_friction
	if type == "underwater_afloat":
		fric = underwater_afloat_friction
	if type == "space_grounded":
		fric = space_grounded_friction
	if type == "space_afloat":
		fric = space_afloat_friction


func _get_x_input() -> float:
	return Input.get_action_strength("right") - Input.get_action_strength("left")


func _get_direction() -> Vector2:
	return Vector2(_get_x_input(), -1.0 if Input.is_action_just_pressed("jump") and is_jumping else 1.0)


#func _calculate_move_velocity(linear_velocity: Vector2, direction: Vector2, speed: Vector2) -> Vector2:
#	var new_velocity: = linear_velocity
#	new_velocity.x = speed.x * direction.x
#	new_


func _jump():
	velocity.y = -jump_power
	jumps_made += 1
	is_jumping = true


func _shoot():
	var bullet = preload("res://core/scenes/projectiles/player_test_bullet.tscn").instance()
	bullet.spawner = self
	get_parent().add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = muzzle.global_rotation


func _aim():
	muzzle.look_at(get_global_mouse_position())
	var angle = torso_sprite.global_position.angle_to_point(get_global_mouse_position())
	var degrees = rad2deg(angle)
	if degrees >= 0:
		if degrees >= 0 and degrees <= 3.75:
			torso_anim_player.play("left")
		
		elif degrees > 3.75 and degrees <= 11.25:
			torso_anim_player.play("11.25")
			weaponflash_dir_handler.play("11.25")
		elif degrees > 11.25 and degrees <= 18.75:
			torso_anim_player.play("18.75")
			weaponflash_dir_handler.play("18.75")
		elif degrees > 18.75 and degrees <= 26.25:
			torso_anim_player.play("26.25")
			weaponflash_dir_handler.play("26.25")
		elif degrees > 26.25 and degrees <= 33.75:
			torso_anim_player.play("33.75")
			weaponflash_dir_handler.play("33.75")
		elif degrees > 33.75 and degrees <= 41.25:
			torso_anim_player.play("41.25")
			weaponflash_dir_handler.play("41.25")
		elif degrees > 41.25 and degrees <= 48.75:
			torso_anim_player.play("48.75")
			weaponflash_dir_handler.play("48.75")
		elif degrees > 48.75 and degrees <= 56.25:
			torso_anim_player.play("56.25")
			weaponflash_dir_handler.play("56.25")
		elif degrees > 56.25 and degrees <= 63.75:
			torso_anim_player.play("63.75")
			weaponflash_dir_handler.play("63.75")
		elif degrees > 63.75 and degrees <= 71.25:
			torso_anim_player.play("71.25")
			weaponflash_dir_handler.play("71.25")
		elif degrees > 71.25 and degrees <= 78.75:
			torso_anim_player.play("78.75")
			weaponflash_dir_handler.play("78.75")
		elif degrees > 78.75 and degrees <= 86.25:
			torso_anim_player.play("86.25")
			weaponflash_dir_handler.play("86.25")
		
		elif degrees > 86.25 and degrees <= 90:
			torso_anim_player.play("up left")
			weaponflash_dir_handler.play("up left")
		elif degrees > 90 and degrees <= 93.75:
			torso_anim_player.play("up right")
			weaponflash_dir_handler.play("up right")
		
		elif degrees > 93.75 and degrees <= 101.25:
			torso_anim_player.play("101.25")
			weaponflash_dir_handler.play("101.25")
		elif degrees > 101.25 and degrees <= 108.75:
			torso_anim_player.play("108.75")
			weaponflash_dir_handler.play("108.75")
		elif degrees > 108.75 and degrees <= 116.25:
			torso_anim_player.play("116.25")
			weaponflash_dir_handler.play("116.25")
		elif degrees > 116.25 and degrees <= 123.75:
			torso_anim_player.play("123.75")
			weaponflash_dir_handler.play("123.75")
		elif degrees > 123.75 and degrees <= 131.25:
			torso_anim_player.play("131.25")
			weaponflash_dir_handler.play("131.25")
		elif degrees > 131.25 and degrees <= 138.75:
			torso_anim_player.play("138.75")
			weaponflash_dir_handler.play("138.75")
		elif degrees > 138.75 and degrees <= 146.25:
			torso_anim_player.play("146.25")
			weaponflash_dir_handler.play("146.25")
		elif degrees > 146.25 and degrees <= 153.75:
			torso_anim_player.play("153.75")
			weaponflash_dir_handler.play("153.75")
		elif degrees > 153.75 and degrees <= 161.25:
			torso_anim_player.play("161.25")
			weaponflash_dir_handler.play("161.25")
		elif degrees > 161.25 and degrees <= 168.75:
			torso_anim_player.play("168.75")
			weaponflash_dir_handler.play("168.75")
		elif degrees > 168.75 and degrees <= 176.25:
			torso_anim_player.play("176.25")
			weaponflash_dir_handler.play("176.25")
		
		elif degrees > 176.25 and degrees <= 180:
			torso_anim_player.play("right")
			weaponflash_dir_handler.play("right")
	
	elif degrees <= 0:
		if degrees <= 0 and degrees >= -3.75:
			torso_anim_player.play("left")
			weaponflash_dir_handler.play("left")
		
		elif degrees < -3.75 and degrees >= -11.25:
			torso_anim_player.play("-11.25")
			weaponflash_dir_handler.play("-11.25")
		elif degrees < -11.25 and degrees >= -18.75:
			torso_anim_player.play("-18.75")
			weaponflash_dir_handler.play("-18.75")
		elif degrees < -18.75 and degrees >= -26.25:
			torso_anim_player.play("-26.25")
			weaponflash_dir_handler.play("-26.25")
		elif degrees < -26.25 and degrees >= -33.75:
			torso_anim_player.play("-33.75")
			weaponflash_dir_handler.play("-33.75")
		elif degrees < -33.75 and degrees >= -41.25:
			torso_anim_player.play("-41.25")
			weaponflash_dir_handler.play("-41.25")
		elif degrees < -41.25 and degrees >= -48.75:
			torso_anim_player.play("-48.75")
			weaponflash_dir_handler.play("-48.75")
		elif degrees < -48.75 and degrees >= -56.25:
			torso_anim_player.play("-56.25")
			weaponflash_dir_handler.play("-56.25")
		elif degrees < -56.25 and degrees >= -63.75:
			torso_anim_player.play("-63.75")
			weaponflash_dir_handler.play("-63.75")
		elif degrees < -63.75 and degrees >= -71.25:
			torso_anim_player.play("-71.25")
			weaponflash_dir_handler.play("-71.25")
		elif degrees < -71.25 and degrees >= -78.75:
			torso_anim_player.play("-78.75")
			weaponflash_dir_handler.play("-78.75")
		elif degrees < -78.75 and degrees >= -86.25:
			torso_anim_player.play("-86.25")
			weaponflash_dir_handler.play("-86.25")
		
		elif degrees < -86.25 and degrees >= -90:
			torso_anim_player.play("down left")
			weaponflash_dir_handler.play("down left")
		elif degrees < -90 and degrees >= -93.75:
			torso_anim_player.play("down right")
			weaponflash_dir_handler.play("down right")
		
		elif degrees < -93.75 and degrees >= -101.25:
			torso_anim_player.play("-101.25")
			weaponflash_dir_handler.play("-101.25")
		elif degrees < -101.25 and degrees >= -108.75:
			torso_anim_player.play("-108.75")
			weaponflash_dir_handler.play("-108.75")
		elif degrees < -108.75 and degrees >= -116.25:
			torso_anim_player.play("-116.25")
			weaponflash_dir_handler.play("-116.25")
		elif degrees < -116.25 and degrees >= -123.75:
			torso_anim_player.play("-123.75")
			weaponflash_dir_handler.play("-123.75")
		elif degrees < -123.75 and degrees >= -131.25:
			torso_anim_player.play("-131.25")
			weaponflash_dir_handler.play("-131.25")
		elif degrees < -131.25 and degrees >= -138.75:
			torso_anim_player.play("-138.75")
			weaponflash_dir_handler.play("-138.75")
		elif degrees < -138.75 and degrees >= -146.25:
			torso_anim_player.play("-146.25")
			weaponflash_dir_handler.play("-146.25")
		elif degrees < -146.25 and degrees >= -153.75:
			torso_anim_player.play("-153.75")
			weaponflash_dir_handler.play("-153.75")
		elif degrees < -153.75 and degrees >= -161.25:
			torso_anim_player.play("-161.25")
			weaponflash_dir_handler.play("-161.25")
		elif degrees < -161.25 and degrees >= -168.75:
			torso_anim_player.play("-168.75")
			weaponflash_dir_handler.play("-168.75")
		elif degrees < -168.75 and degrees >= -176.25:
			torso_anim_player.play("-176.25")
			weaponflash_dir_handler.play("-176.25")
		
		elif degrees < -176.25 and degrees >= -180:
			torso_anim_player.play("right")
			weaponflash_dir_handler.play("right")
