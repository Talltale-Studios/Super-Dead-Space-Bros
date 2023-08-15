@tool
extends GraphNode

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
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

signal new_resource_class_chosen(kind, classname)

const Hacks = preload("res://addons/resource_wrangler/utilities/class_hacks.gd")

var board:Control
var editor_plugin
var list_of_resource_classnames:Array #PackedStringArray
enum KIND {NONE, MAKE_FROM_POPUP, MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY}
var kind : KIND = KIND.NONE

static var last_filter:String

# July 2023 : The EditorResourcePicker object is a Node, but I could
# not figure out how to show or use it. It's still useful but I had to
# make the entire gui manually.
@onready var editor_resource_picker := EditorResourcePicker.new()
@onready var _filter = %filter
@onready var _resources = %resources


func _ready() -> void:
	editor_resource_picker.base_type="Resource"


func _on_close_request() -> void:
	board._close_chooser_thing()


func _common(_board,_posoff):
	board = _board
	editor_plugin = _board.editor_plugin
	_filter.grab_focus()
	_filter.text = ""
	position_offset = _posoff
	list_of_resource_classnames.clear()


func _setsize(list):
	var width = _resources.size.x
	var rows = 20
	if list.size() < rows: rows = list.size() + 1

	var rowh = _resources.get_item_rect(0).size.y

	var height = (rows * rowh)
	_resources.set("size", Vector2(width, height) )

	var thenode = Vector2(width, height + (3*rowh) )
	self.set("size", thenode )


# MAKE_FROM_POPUP - list ALL resources possible
func kind1_setup(_board, _posoff):
	kind = KIND.MAKE_FROM_POPUP
	_common(_board, _posoff)
	list_of_resource_classnames = editor_resource_picker.get_allowed_types()
	if list_of_resource_classnames:
		list_of_resource_classnames.sort()
		# filter out those classes we cannot instantiate
		# We also can't make a basic "Resource" type. It goes haywire.
		list_of_resource_classnames = list_of_resource_classnames.filter(func(i):
			return Hacks.can_we_instantiate(i) and i != "Resource")
		_fill_resources_list(list_of_resource_classnames)
	_filter.text = last_filter
	if last_filter:
		_do_filter(last_filter)


# MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY - list specific family of resources
func kind2_setup(_board, _thing, _classname, _posoff, _slot, _to, _to_port):
	kind = KIND.MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY
	_common(_board, _posoff)
	list_of_resource_classnames = [_classname] # include the initial classname too
	list_of_resource_classnames.append_array(
			ClassDB.get_inheriters_from_class(_classname))
	# There are a bunch if Resource types that simply won't instance ∴ exlude:
	list_of_resource_classnames = list_of_resource_classnames.filter(
			func(c): return Hacks.can_we_instantiate(c))
	if list_of_resource_classnames:
		list_of_resource_classnames.sort()
		_resources.clear()
		_fill_resources_list(list_of_resource_classnames,
				{
					"from_thing" = _thing,
					"from_slot" = _slot,
					"release_position" = _posoff,
					"to" = _to,
					"to_port" = _to_port,
				})
		_fill_resources_list(list_of_resource_classnames)
	_filter.text = last_filter
	if last_filter:
		_do_filter(last_filter)
		

func _fill_resources_list(list, dict={}):
	_resources.clear()
	for resclass in list:
		if not resclass in editor_plugin.blocked_resource_classes:
			var icon = Hacks.get_icon_for(resclass, editor_plugin)
			_resources.add_item(resclass, icon)
	# record that dict from board in my meta
	if dict:
		set_meta("situation", dict)
		
	call_deferred("_setsize", list)


func _on_filter_text_changed(new_text: String) -> void:
	if new_text:
		_do_filter(new_text)
		last_filter = new_text
	else:
		_fill_resources_list(list_of_resource_classnames)
	last_filter = new_text

func _do_filter(filter:String):
		var newa:Array = Array(list_of_resource_classnames).filter(
			func(n):return _filter.text.to_upper() in n.to_upper())
		_fill_resources_list(newa)


func _on_list_item_activated(index: int) -> void:
	var res_class_name : String = _resources.get_item_text(index)
	if res_class_name:
		new_resource_class_chosen.emit(kind, res_class_name)


func _on_filter_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.call_deferred("_close_chooser_thing")
