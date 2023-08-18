## Virtual base class for all states.
class_name GameState
extends Node


## Reference to the state machine, to call its [code]transition_to()[/code]
## method directly.
## It adds a dependency between the state and the state machine objects.
## The state machine will set it.
var state_machine: GameStateMachine = null


## Virtual function. Called by the state machine upon changing the active state.
func enter_state() -> void:
	pass


## Virtual function. Called by the state machine before changing the active state.
func exit_state() -> void:
	pass


func transition_to(state_name: String) -> void:
	exit_state()
	state_machine.change_state(state_name)


## Virtual function. Receives events from the [code]_physics()[/code] callback.
func process(_delta: float) -> void:
	pass


## Virtual function. Receives events from the [code]_physics_process()[/code] callback.
func physics_process(_delta: float) -> void:
	pass


## Virtual function. Receives events from the [code]_input()[/code] callback.
func input(_event: InputEvent) -> void:
	pass


## Virtual function. Receives events from the [code]_unhandled_input()[/code] callback.
func unhandled_input(_event: InputEvent) -> void:
	pass


## Virtual function. Receives events from the [code]_unhandled_key_input()[/code] callback.
func unhandled_key_input(_event: InputEvent) -> void:
	pass


## Virtual function. Receives events from the [code]_notification()[/code] callback.
func notification_custom(_what: int, _flag: bool = false) -> void:
	pass
