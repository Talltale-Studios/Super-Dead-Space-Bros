class_name State
extends Node


var fsm : FiniteStateMachine


func enter() -> void:
	pass


func exit(next_state: String) -> void:
	fsm.change_to(next_state)


# Optional handler functions for game loop events
func process(_delta: float) -> void:
	# Add handler code here
	pass


# Optional handler functions for game loop events
func physics_process(_delta: float) -> void:
	# Add handler code here
	pass


# Optional handler functions for game loop events
func input(_event: InputEvent) -> void:
	# Add handler code here
	pass


# Optional handler functions for game loop events
func unhandled_input(_event: InputEvent) -> void:
	# Add handler code here
	pass


# Optional handler functions for game loop events
func unhandled_key_input(_event: InputEvent) -> void:
	# Add handler code here
	pass


# Optional handler functions for game loop events
func notification_custom(_what: int, _flag: bool = false) -> void:
	# Add handler code here
	pass
