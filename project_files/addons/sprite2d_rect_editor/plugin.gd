@tool
extends EditorPlugin


enum DragState {
	none,
	right,
	left,
	top,
	bottom,
}

const handle_offset := 8.0
const grid_size := 8.0

var inspector_plugin: EditorInspectorPlugin

var img_handle_right := load("res://addons/sprite2d_rect_editor/handle_right.svg") as Texture2D
var img_handle_bottom := load("res://addons/sprite2d_rect_editor/handle_bottom.svg") as Texture2D
var img_handle_left := load("res://addons/sprite2d_rect_editor/handle_left.svg") as Texture2D
var img_handle_top := load("res://addons/sprite2d_rect_editor/handle_top.svg") as Texture2D

var current_object: Sprite2D
var drag_state := DragState.none
var starting_mouse_pos_in_scene: Vector2
var starting_current_object_global_rect: Rect2
var starting_current_object_region_rect: Rect2
var starting_current_object_global_pos: Vector2
var undo_redo: EditorUndoRedoManager


func _enter_tree() -> void:
	set_force_draw_over_forwarding_enabled()
	undo_redo = get_undo_redo()
	inspector_plugin = preload("res://addons/sprite2d_rect_editor/autorect_inspector_plugin.gd").new(undo_redo)
	add_inspector_plugin(inspector_plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(inspector_plugin)


func _handles(object: Object) -> bool:
	return object is Sprite2D


func _edit(object: Object) -> void:
	current_object = object as Sprite2D
	update_overlays()


func _forward_canvas_force_draw_over_viewport(viewport_control: Control) -> void:

	# Fail fast if no sprite is selected or if it doesn't use the texture region feature.
	if not is_region_rect_editable():
		return

	# Draw handles
	var right_handle_rect := get_handle_editor_rect("right")
	var bottom_handle_rect := get_handle_editor_rect("bottom")
	var left_handle_rect := get_handle_editor_rect("left")
	var top_handle_rect := get_handle_editor_rect("top")

	viewport_control.draw_texture_rect(img_handle_right, right_handle_rect, false)
	viewport_control.draw_texture_rect(img_handle_bottom, bottom_handle_rect, false)
	viewport_control.draw_texture_rect(img_handle_left, left_handle_rect, false)
	viewport_control.draw_texture_rect(img_handle_top, top_handle_rect, false)

	# Set the cursor
	if (
		right_handle_rect.has_point(viewport_control.get_local_mouse_position()) or
		left_handle_rect.has_point(viewport_control.get_local_mouse_position())
	):
		viewport_control.mouse_default_cursor_shape = Control.CURSOR_HSIZE
	elif (
		bottom_handle_rect.has_point(viewport_control.get_local_mouse_position()) or
		top_handle_rect.has_point(viewport_control.get_local_mouse_position())
	):
		viewport_control.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	else:
		viewport_control.mouse_default_cursor_shape = Control.CURSOR_ARROW


func _forward_canvas_gui_input(event: InputEvent) -> bool:

	if not is_region_rect_editable():
		return false

	if event is InputEventMouseMotion:

		var mouse_event := event as InputEventMouseMotion

		match drag_state:
			DragState.right:
				var mouse_pos_in_scene := get_editor_transform().affine_inverse() * mouse_event.position
				var distance := mouse_pos_in_scene.x - starting_mouse_pos_in_scene.x

				current_object.region_rect = Rect2(
					starting_current_object_region_rect.position,
					Vector2(
						snappedf(
							(starting_current_object_global_rect.size.x / current_object.global_scale.x) + (distance / current_object.global_scale.x),
							grid_size / current_object.global_scale.x,
						),
						starting_current_object_region_rect.size.y,
					)
				)

				current_object.global_position = Vector2(
					snappedf(
						(starting_current_object_global_rect.position.x + starting_current_object_global_rect.size.x / 2) + distance / 2.0,
						grid_size / 2.0
					),
					current_object.global_position.y,
				)

			DragState.bottom:
				var mouse_pos_in_scene := get_editor_transform().affine_inverse() * mouse_event.position
				var distance := mouse_pos_in_scene.y - starting_mouse_pos_in_scene.y

				current_object.region_rect = Rect2(
					starting_current_object_region_rect.position,
					Vector2(
						starting_current_object_region_rect.size.x,
						snappedf(
							(starting_current_object_global_rect.size.y / current_object.global_scale.y) + (distance / current_object.global_scale.y),
							grid_size / current_object.global_scale.y,
						),
					)
				)

				current_object.global_position = Vector2(
					current_object.global_position.x,
					snappedf(
						(starting_current_object_global_rect.position.y + starting_current_object_global_rect.size.y / 2) + distance / 2.0,
						grid_size / 2.0,
					),
				)

			DragState.left:
				var mouse_pos_in_scene := get_editor_transform().affine_inverse() * mouse_event.position
				var distance := mouse_pos_in_scene.x - starting_mouse_pos_in_scene.x

				current_object.region_rect = Rect2(
					Vector2(
						snappedf(
							(starting_current_object_region_rect.position.x) + (distance / current_object.global_scale.x),
							grid_size / current_object.global_scale.x,
						),
						starting_current_object_region_rect.position.y,
					),
					Vector2(
						snappedf(
							(starting_current_object_global_rect.size.x / current_object.global_scale.x) - (distance / current_object.global_scale.x),
							grid_size / current_object.global_scale.x,
						),
						starting_current_object_region_rect.size.y,
					),
				)

				current_object.global_position = Vector2(
					snappedf(
						(starting_current_object_global_rect.position.x + starting_current_object_global_rect.size.x / 2) + distance / 2.0,
						grid_size / 2.0,
					),
					current_object.global_position.y,
				)

			DragState.top:
				var mouse_pos_in_scene := get_editor_transform().affine_inverse() * mouse_event.position
				var distance := mouse_pos_in_scene.y - starting_mouse_pos_in_scene.y

				current_object.region_rect = Rect2(
					Vector2(
						starting_current_object_region_rect.position.x,
						snappedf(
							(starting_current_object_region_rect.position.y) + (distance / current_object.global_scale.y),
							grid_size / current_object.global_scale.y,
						),
					),
					Vector2(
						starting_current_object_region_rect.size.x,
						snappedf(
							(starting_current_object_global_rect.size.y / current_object.global_scale.y) - (distance / current_object.global_scale.y),
							grid_size / current_object.global_scale.y,
						),
					),
				)

				current_object.global_position = Vector2(
					current_object.global_position.x,
					snappedf(
						(starting_current_object_global_rect.position.y + starting_current_object_global_rect.size.y / 2) + distance / 2.0,
						grid_size / 2.0,
					),
				)


			DragState.none:
				update_overlays()
				return false

			_:
				printerr("Invalid drag state: ", drag_state)
				update_overlays()
				return false


		# Redraw viewport when cursor is moved.
		update_overlays()
		return true

	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_event.pressed and drag_state != DragState.none:
				drag_state = DragState.none

				undo_redo.create_action("Sprite2D Rect Editor: resize rect in editor")
				undo_redo.add_do_property(current_object, "region_rect", current_object.region_rect)
				undo_redo.add_undo_property(current_object, "region_rect", starting_current_object_region_rect)
				undo_redo.add_do_property(current_object, "global_position", current_object.global_position)
				undo_redo.add_undo_property(current_object, "global_position", starting_current_object_global_pos)
				undo_redo.commit_action(false)

				return true

			elif mouse_event.pressed:
				if get_handle_editor_rect("right").has_point(mouse_event.position):
					drag_state = DragState.right
					starting_mouse_pos_in_scene = get_editor_transform().affine_inverse() * mouse_event.position
					starting_current_object_global_rect = get_current_object_global_rect()
					starting_current_object_region_rect = current_object.region_rect
					starting_current_object_global_pos = current_object.global_position
					return true

				elif get_handle_editor_rect("bottom").has_point(mouse_event.position):
					drag_state = DragState.bottom
					starting_mouse_pos_in_scene = get_editor_transform().affine_inverse() * mouse_event.position
					starting_current_object_global_rect = get_current_object_global_rect()
					starting_current_object_region_rect = current_object.region_rect
					starting_current_object_global_pos = current_object.global_position
					return true

				if get_handle_editor_rect("left").has_point(mouse_event.position):
					drag_state = DragState.left
					starting_mouse_pos_in_scene = get_editor_transform().affine_inverse() * mouse_event.position
					starting_current_object_global_rect = get_current_object_global_rect()
					starting_current_object_region_rect = current_object.region_rect
					starting_current_object_global_pos = current_object.global_position
					return true

				elif get_handle_editor_rect("top").has_point(mouse_event.position):
					drag_state = DragState.top
					starting_mouse_pos_in_scene = get_editor_transform().affine_inverse() * mouse_event.position
					starting_current_object_global_rect = get_current_object_global_rect()
					starting_current_object_region_rect = current_object.region_rect
					starting_current_object_global_pos = current_object.global_position
					return true

	return false


func is_region_rect_editable() -> bool:
	return (
		current_object != null and
		current_object.region_enabled and
		is_equal_approx(fmod(current_object.global_rotation, 2 * PI), 0)
	)


func get_editor_transform() -> Transform2D:
	return get_editor_interface().get_edited_scene_root().get_viewport().global_canvas_transform


func get_current_object_global_rect() -> Rect2:
	return current_object.get_global_transform_with_canvas() * current_object.get_rect()


func get_current_object_editor_rect() -> Rect2:
	return get_editor_transform() * get_current_object_global_rect()


func get_handle_editor_rect(direction: StringName) -> Rect2:

	match direction:

		&"right":
			var position := Vector2(
				round(get_current_object_editor_rect().position.x + get_current_object_editor_rect().size.x + handle_offset * get_editor_interface().get_editor_scale()),
				round(get_current_object_editor_rect().position.y + (get_current_object_editor_rect().size.y / 2.0) - (img_handle_right.get_height() / 2.0)),
			)
			return Rect2(position, img_handle_right.get_size())

		&"bottom":
			var position := Vector2(
				round(get_current_object_editor_rect().position.x + (get_current_object_editor_rect().size.x / 2.0) - (img_handle_bottom.get_width() / 2.0)),
				round(get_current_object_editor_rect().position.y + get_current_object_editor_rect().size.y + handle_offset * get_editor_interface().get_editor_scale()),
			)
			return Rect2(position, img_handle_bottom.get_size())

		&"left":
			var position := Vector2(
				round(get_current_object_editor_rect().position.x - img_handle_left.get_size().x - handle_offset * get_editor_interface().get_editor_scale()),
				round(get_current_object_editor_rect().position.y + (get_current_object_editor_rect().size.y / 2.0) - (img_handle_left.get_height() / 2.0)),
			)
			return Rect2(position, img_handle_right.get_size())

		&"top":
			var position := Vector2(
				round(get_current_object_editor_rect().position.x + (get_current_object_editor_rect().size.x / 2.0) - (img_handle_top.get_width() / 2.0)),
				round(get_current_object_editor_rect().position.y - img_handle_top.get_size().y - handle_offset * get_editor_interface().get_editor_scale()),
			)
			return Rect2(position, img_handle_bottom.get_size())

		_:
			printerr("Invalid direction: ", direction)
			return Rect2(NAN, NAN, NAN, NAN)
