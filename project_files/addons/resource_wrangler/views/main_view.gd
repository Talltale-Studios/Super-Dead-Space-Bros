@tool
extends Control

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad (Thank you!)
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

signal types_change(types: Array[Dictionary])


const ResoureWranglerSettings = preload("../utilities/settings.gd")


@onready var add_board_button: Button = $Margin/VBox/Toolbar/AddBoardButton
@onready var boards_menu: MenuButton = $Margin/VBox/Toolbar/BoardsMenu
@onready var edit_board_button: Button = $Margin/VBox/Toolbar/EditBoardButton
@onready var remove_board_button: Button = $Margin/VBox/Toolbar/RemoveBoardButton
@onready var board := $Margin/VBox/Board
@onready var edit_board_dialog := $EditBoardDialog
@onready var confirm_remove_board_dialog: AcceptDialog = $ConfirmRemoveBoardDialog


var editor_plugin: EditorPlugin

## WTF does this do?
var undo_redo: EditorUndoRedoManager:
	set(next_undo_redo):
		undo_redo = next_undo_redo
		board.undo_redo = next_undo_redo
	get:
		return undo_redo

var boards: Dictionary = {}
var current_board_id: String = ""


func _ready() -> void:
	boards_menu.text = "Choose a board..."

	board.editor_plugin = editor_plugin

	call_deferred("apply_theme")
	ResoureWranglerSettings.setup()
	# Get boards
	boards = ResoureWranglerSettings.load_database()

	go_to_board(ResoureWranglerSettings.get_setting("current_board_id", ""))
	if current_board_id != "":
		board.from_serialized(boards.get(current_board_id))


func apply_changes() -> void:
	if is_instance_valid(board):
		save_board()
		board.apply_changes()


### Helpers


func apply_theme() -> void:
	# Simple check if onready
	if is_instance_valid(add_board_button):
		add_board_button.icon = get_theme_icon("New", "EditorIcons")
		boards_menu.icon = get_theme_icon("GraphNode", "EditorIcons")
		edit_board_button.icon = get_theme_icon("Edit", "EditorIcons")
		remove_board_button.icon = get_theme_icon("Remove", "EditorIcons")


func go_to_board(id: String) -> void:

	if id not in boards.keys(): return

	if current_board_id != id:
		save_board()

		current_board_id = id
		ResoureWranglerSettings.set_setting("current_board_id", id)

		if boards.has(current_board_id):
			var board_data = boards.get(current_board_id)
			board.from_serialized(board_data)

	if current_board_id == "":
		board.hide()
		edit_board_button.disabled = true
		remove_board_button.disabled = true
	else:
		board.show()
		edit_board_button.disabled = false
		remove_board_button.disabled = false

	build_boards_menu()


func build_boards_menu() -> void:
	var menu: PopupMenu = boards_menu.get_popup()
	menu.clear()

	if menu.index_pressed.is_connected(_on_boards_menu_index_pressed):
		menu.index_pressed.disconnect(_on_boards_menu_index_pressed)

	if boards.size() == 0:
			boards_menu.text = "No boards yet"
			boards_menu.disabled = true

	else:
		boards_menu.disabled = false

		# Add board labels to the menu in alphabetical order
		var labels := []
		for board_data in boards.values():
			labels.append(board_data.label)
		labels.sort()
		for label in labels:
			menu.add_icon_item(get_theme_icon("GraphNode", "EditorIcons"), label)

		if boards.has(current_board_id):
			boards_menu.text = boards.get(current_board_id).label
		menu.index_pressed.connect(_on_boards_menu_index_pressed)

		# hide the dustbin icon if there's zero or one boards
		remove_board_button.visible = boards.size() > 1

func set_board_data(id: String, data: Dictionary) -> void:
	var board_data = boards.get(id) if boards.has(id) else data
	for key in data.keys():
		board_data[key] = data.get(key)
	boards[id] = board_data
	build_boards_menu()


func save_board() -> void:
	if boards.has(current_board_id):
		var data = board.to_serialized()
		for key in data.keys():
			boards[current_board_id][key] = data.get(key)
	# Try prevent overwriting a good db with an empty one!
	if not boards.is_empty():
		ResoureWranglerSettings.save_database(boards)


func remove_board() -> void:
	var board_data = boards.get(current_board_id)
	var undo_board_data = board.to_serialized()
	for key in undo_board_data.keys():
		board_data[key] = undo_board_data.get(key)

	undo_redo.create_action("Delete board")
	undo_redo.add_do_method(self, "_remove_board", current_board_id)
	undo_redo.add_undo_method(self, "_unremove_board", current_board_id, board_data)
	undo_redo.commit_action()


func _remove_board(id: String) -> void:
	boards.erase(id)
	go_to_board(boards.keys().front() if boards.size() > 0 else "")
	build_boards_menu()


func _unremove_board(id: String, data: Dictionary) -> void:
	boards[id] = data
	build_boards_menu()
	go_to_board(id)


### Signals


func _on_boards_menu_index_pressed(index):
	var popup = boards_menu.get_popup()
	var label = popup.get_item_text(index)
	for board_data in boards.values():
		if board_data.label == label:
			undo_redo.create_action("Change board")
			undo_redo.add_do_method(self, "go_to_board", board_data.id)
			undo_redo.add_undo_method(self, "go_to_board", current_board_id)
			undo_redo.commit_action()


func _on_main_view_theme_changed() -> void:
	apply_theme()


func _on_main_view_visibility_changed() -> void:
	if visible:
		apply_changes()
		if is_instance_valid(board):
			board.redraw()


func _on_add_board_button_pressed() -> void:
	edit_board_dialog.edit_board(board.create_new_board_data())


func _on_boards_menu_about_to_popup() -> void:
	build_boards_menu()


func _on_edit_board_button_pressed() -> void:
	edit_board_dialog.edit_board(boards[current_board_id])


func _on_edit_board_dialog_updated(data: Dictionary) -> void:
	if boards.has(data.id):
		undo_redo.create_action("Set board label")
		undo_redo.add_do_method(self, "set_board_data", data.id, { label = data.label })
		undo_redo.add_undo_method(self, "set_board_data", data.id, { label = boards.get(data.id).label })
		undo_redo.commit_action()
	else:
		undo_redo.create_action("Set board label")
		undo_redo.add_do_method(self, "set_board_data", data.id, data)
		undo_redo.add_undo_method(self, "_remove_board", data.id)
		undo_redo.add_do_method(self, "go_to_board", data.id)
		undo_redo.add_undo_method(self, "go_to_board", current_board_id)
		undo_redo.commit_action()


func _on_remove_board_button_pressed() -> void:
	if boards.size()>1:
		confirm_remove_board_dialog.dialog_text = \
		"Remove '%s'" % boards.get(current_board_id).label
		confirm_remove_board_dialog.popup_centered()


func _on_remove_thing_button_pressed() -> void:
	board.delete_selected_things()


func _on_confirm_remove_board_dialog_confirmed() -> void:
	remove_board()

## Tries to clean up the automade folder.
## Massive re-write Aug 14, 2023
func _on_prune_automades_pressed():# -> void:
	var db_owns:Array

	# Get a list of all the resources known to to all the boards
	for board in boards.values():
		if "things" in (board as Dictionary).keys():
			for thing in board.things:
				if "dbat_data" in thing:
					if "files" in thing.dbat_data:
						db_owns.append(thing.dbat_data.files[0])

	if db_owns.is_empty():
		return # can't do anything

	var path:String=ResoureWranglerSettings.automade_path
	var makepaf := "%s/%s" % [path,"%s"]
	var all_autos:Array

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name
		file_name = dir.get_next()

		# Build a list of <Resources> that are in the automades dir
		while file_name != "":
			if not dir.current_is_dir():
				var paf = makepaf % [file_name]
				#print("automade:",paf)
				all_autos.append(paf)
			file_name = dir.get_next()

	if all_autos.is_empty():
		return #no automades anyway...

	var unowned:Array
	# Reasoning: if the automade is not in the db, then
	# it must be unowned by the db
	for automade_paf in all_autos:
		if not automade_paf in db_owns:
			unowned.append(automade_paf)

	if unowned.is_empty():
		return # Nothing is unowned - so, all good

	# Ok! Move the buggers out!
	# If the resource has dependencies, it goes into a sub
	# folder has_deps
	# If not, has_no_deps
	# It's left to the user to sort those out.
	var have_deps_path:String="%s/have_deps" % [path]
	var have_no_deps_path:String="%s/have_no_deps" % [path]
	for paf in unowned:
		# This barfs a lot on any error
		var deps = ResourceLoader.get_dependencies(paf)
		var to_paf:String
		if deps.is_empty():
			to_paf = "%s/%s" % [have_no_deps_path, paf.get_file()]
			dir.make_dir(have_no_deps_path)
			dir.rename(paf, to_paf)
		else:
			to_paf = "%s/%s" % [have_deps_path, paf.get_file()]
			dir.make_dir(have_deps_path)
			dir.rename(paf, to_paf)

	save_board()
	return

