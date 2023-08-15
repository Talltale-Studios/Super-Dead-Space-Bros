@tool
extends PopupMenu

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

const ResoureWranglerSettings = preload("res://addons/resource_wrangler/utilities/settings.gd")
const ITEM_DUPLICATE = 10
const ITEM_MAKEUNIQUE = 30

var board: Control
var selected_things:Array # poked into from board._on_thing_popup_menu_request()

### Helpers

func popup_at(next_position: Vector2) -> void:
	position = next_position
	popup()

### Signals

func _on_thing_popup_menu_about_to_popup() -> void:
	clear()
	size = Vector2.ZERO
	
	add_item("Duplicate",ITEM_DUPLICATE)
	add_separator()
	add_item("Duplicate Unique",ITEM_MAKEUNIQUE)


func _on_thing_popup_menu_id_pressed(id: int) -> void:
	match id:
		ITEM_DUPLICATE:
			board.duplicate_things(selected_things)
		ITEM_MAKEUNIQUE:
			board.make_unique(selected_things)
