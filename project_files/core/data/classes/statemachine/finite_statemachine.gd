class_name FiniteStateMachine
extends Node


const DEBUG : bool = true


var state : State
var history : Array[String]


func _ready() -> void:
	# Set the initial state to the first child node
	state = get_child(0)
	_enter_state()


## Change to a new state
func change_to(new_state : String) -> void:
	history.append(state.name)
	state = get_node(new_state.to_pascal_case())
	_enter_state()


## Travel to the previous state
func back() -> void:
	if history.size() > 0:
		state = get_node(history.pop_back())
		_enter_state()


func _enter_state() -> void:
	if DEBUG:
		print("Entering State: ", state.name)
	# Give the new state a reference to this statemachine script
	state.fsm = self
	state.enter()


# Route game loop function calls to
# current state handler method if it exists
func _process(delta: float) -> void:
	if state.has_method("process"):
		state.process(delta)


func _physics_process(delta: float) -> void:
	if state.has_method("physics_process"):
		state.physics_process(delta)


func _input(event: InputEvent) -> void:
	if state.has_method("input"):
		state.input(event)


func _unhandled_input(event: InputEvent) -> void:
	if state.has_method("unhandled_input"):
		state.unhandled_input(event)


func _unhandled_key_input(event: InputEvent) -> void:
	if state.has_method("unhandled_key_input"):
		state.unhandled_key_input(event)


func _notification(what: int) -> void:
	if is_instance_valid(state) and state.has_method("notification_custom"):
		state.notification_custom(what)
