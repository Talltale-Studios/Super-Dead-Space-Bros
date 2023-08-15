@tool
extends EditorPlugin

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


const MainViewScene = preload(  "res://addons/resource_wrangler/views/main_view.tscn")
const MainView = preload(       "res://addons/resource_wrangler/views/main_view.gd")
const ResoureWranglerSettings = preload("res://addons/resource_wrangler/utilities/settings.gd")


var main_view: MainView

var inspector_plugin

# Block resource classnames here that crash Godot when they
# are instantiated. I don't know why they crash, but they do:
var blocked_resource_classes:=["Image"] # Add them as you find them


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		main_view = MainViewScene.instantiate()
		main_view.editor_plugin = self
		get_editor_interface().get_editor_main_screen().add_child(main_view)
		main_view.undo_redo = get_undo_redo()
		_make_visible(false)
		
#		add_custom_type(
#			"ResourceNode",
#			"GraphNode",
#			preload("./src/scatter.gd"),
#			preload("./icons/scatter.svg")
#		)
	

func _exit_tree() -> void:
	if is_instance_valid(main_view):
		main_view.queue_free()


func _has_main_screen() -> bool:
	return true


func _make_visible(next_visible: bool) -> void:
	if is_instance_valid(main_view):
		main_view.visible = next_visible


func _get_plugin_name() -> String:
	return "Resource Wrangler"


func _get_plugin_icon() -> Texture2D:
	return create_main_icon()


func create_main_icon(scale: float = 1.0) -> Texture2D:
	var size: Vector2 = Vector2(16, 16) * get_editor_interface().get_editor_scale() * scale
	#var base_color: Color = get_editor_interface().get_editor_main_screen().get_theme_color("base_color", "Editor")
	#var theme: String = "light" if base_color.v > 0.5 else "dark"
	var base_icon = load("res://addons/resource_wrangler/assets/resource_wrangler_icon_large_cleaned.svg") as Texture2D
	var image: Image = base_icon.get_image()
	image.resize(size.x, size.y, Image.INTERPOLATE_TRILINEAR)
	return ImageTexture.create_from_image(image)


func _apply_changes() -> void:
	if is_instance_valid(main_view):
		main_view.apply_changes()
