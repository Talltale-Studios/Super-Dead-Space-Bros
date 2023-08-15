@tool
extends ConfirmationDialog

# MIT License
# 
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

signal updated(data: Dictionary)


@onready var label_edit: LineEdit = $VBox/LabelEdit

var data: Dictionary = {}


func _ready() -> void:
	register_text_enter(label_edit)


func edit_board(board_data: Dictionary) -> void:
	label_edit.text = board_data.label
	data = board_data
	popup_centered()
	label_edit.grab_focus()
	label_edit.select_all()


### Signals


func _on_edit_board_dialog_confirmed():
	var next_data: Dictionary = data.duplicate()
	next_data.merge({ label = label_edit.text }, true)
	emit_signal("updated", next_data)
