class_name State
extends Node


var fsm: FiniteStateMachine

func enter():
	pass


func exit(next_state: String):
	fsm.change_to(next_state)


# Option handler functions for game loop events
func process(_delta: float) -> void:
	# Add handler code here
	pass


func physics_process(_delta: float) -> void:
	# Add handler code here
	pass


func input(_event: InputEvent) -> void:
	# Add handler code here
	pass


func unhandled_input(_event: InputEvent) -> void:
	# Add handler code here
	pass


func unhandled_key_input(_event: InputEvent) -> void:
	# Add handler code here
	pass


func notification_custom(_what: int, _flag = false):
	# Add handler code here
	return [_what, _flag]
