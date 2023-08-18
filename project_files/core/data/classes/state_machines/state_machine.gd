## Virtual base class for all state machines
class_name GameStateMachine
extends Node


const DEBUG: bool = true


@export var actor : PhysicsBody2D
## Path to the initial active state. It is exported so that the
## [code]initial_state[/code] can be picked in the Inspector.
@export_node_path("GameState") var initial_state: NodePath


var history: Array[String]


## The current active state.
## At the start of the game, we get the [code]initial_state[/code].
var current_state: Object


func _ready() -> void:
	# Set the initial active state to the [code]initial_state[/code]
	current_state = get_node(initial_state)
	_enter_state()


## Change to a new state
func change_state(new_state: String) -> void:
	history.append(current_state.name)
	current_state = get_node(new_state.to_pascal_case())
	_enter_state()


## Travel to the previous state
func back() -> void:
	if history.size() > 0:
		current_state = get_node(history.pop_back())
		_enter_state()


func _enter_state() -> void:
	if DEBUG:
		print("Entering State: ", current_state.name)
	# Give the new state a reference to this statemachine script
	current_state.state_machine = self
	current_state.enter_state()


# Route game loop function calls to
# current state handler method if it exists
func _process(delta: float) -> void:
	if current_state.has_method("process"):
		current_state.process(delta)


func _physics_process(delta: float) -> void:
	if current_state.has_method("physics_process"):
		current_state.physics_process(delta)


func _input(event: InputEvent) -> void:
	if current_state.has_method("input"):
		current_state.input(event)


func _unhandled_input(event: InputEvent) -> void:
	if current_state.has_method("unhandled_input"):
		current_state.unhandled_input(event)


func _unhandled_key_input(event: InputEvent) -> void:
	if current_state.has_method("unhandled_key_input"):
		current_state.unhandled_key_input(event)


func _notification(what: int) -> void:
	if is_instance_valid(current_state) and current_state.has_method("notification_custom"):
		current_state.notification_custom(what)
