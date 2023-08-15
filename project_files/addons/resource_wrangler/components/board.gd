@tool
extends Control

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

## Board is a control that contains the actual Graph

const ResoureWranglerSettings = preload("res://addons/resource_wrangler/utilities/settings.gd")
const Hacks = preload("res://addons/resource_wrangler/utilities/class_hacks.gd")

const BASE_NODE_SCENE = preload(
			"res://addons/resource_wrangler/components/nodes/thing_node.tscn")

const ChooserThingScene = preload("res://addons/resource_wrangler/components/chooser_thing.tscn")
const ChooserThing = preload("res://addons/resource_wrangler/components/chooser_thing.gd")

const THING_SIZE = Vector2(150, 80)


@onready var graph: GraphEdit = $Graph
@onready var thing_menu := $ThingPopupMenu
@onready var file_dialogue := %filedialogue
#@onready var resource_picker := %resource_picker


var things: Dictionary = {}
var editor_plugin: EditorPlugin
var undo_redo: EditorUndoRedoManager

func _ready() -> void:
	graph.show_zoom_label = true

	graph.minimap_enabled = ResoureWranglerSettings.get_setting("minimap_enabled", false)
	graph.minimap_size = ResoureWranglerSettings.get_setting("minimap_size", Vector2(200, 150))
	graph.use_snap = ResoureWranglerSettings.get_setting("use_snap", true)
	graph.snap_distance = ResoureWranglerSettings.get_setting("snap_distance", 20)

	thing_menu.board = self

	graph.something_was_dropped.connect(_something_was_dropped)

	

	# Only way I could think to make sure that all out ports can connect to
	# a generic "Resource" type input port.
	for i in range(0,512):
		graph.add_valid_connection_type(i, Hacks.smallhash("Resource"))


### Helpers


func apply_changes() -> void:
	ResoureWranglerSettings.set_setting("minimap_enabled", graph.minimap_enabled)
	ResoureWranglerSettings.set_setting("minimap_size", graph.minimap_size)
	ResoureWranglerSettings.set_setting("use_snap", graph.use_snap)
	ResoureWranglerSettings.set_setting("snap_distance", graph.snap_distance)


## Sometimes the graph connections are pointing to the wrong position
## on resized things. This forces it to rerender.
func redraw() -> void:
	if things.size() > 0:
		var first_thing = things[things.keys()[0]]
		first_thing.position_offset += Vector2.UP
		await get_tree().process_frame
		first_thing.position_offset -= Vector2.UP
		#print(first_thing, " was redrawn")


func create_new_board_data() -> Dictionary:
	return {
		id = get_random_id(),
		label = "Untitled board",
		scroll_offset = Vector2.ZERO,
		zoom = 1,
		things = [],
		connections = []
	}


func clear() -> void:
	graph.clear_connections()
	for thing in things.values():
		thing.free()
	things.clear()


func to_serialized() -> Dictionary:
	# There's some startup timing thing that causes a bunch of errors
	# making sure there's an editor_plugin here seems to stop that.
	if not editor_plugin: return {}

	var editor_scale: float = get_editor_scale()

	var serialized_things: Array = []
	for thing in things.values():
		serialized_things.append(thing.to_serialized(editor_scale))

	var serialized_connections: Array = []
	for connection in graph.get_connection_list():
		serialized_connections.append({
			from = connection.from,
			from_port = connection.from_port,
			to = connection.to,
			to_port = connection.to_port
		})

	return {
		scroll_offset = graph.scroll_offset / editor_scale,
		zoom = graph.zoom,
		things = serialized_things,
		connections = serialized_connections
	}


func from_serialized(data: Dictionary) -> void:
	# There's some startup timing thing that causes a bunch of errors
	# making sure there's an editor_plugin here seems to stop that.
	if not editor_plugin: return

	clear()
	var editor_scale: float = get_editor_scale()

	for serialized_thing in data.things:
		_add_thing(serialized_thing.id, serialized_thing)

	for serialized_connection in data.connections:
		graph.connect_node(
				serialized_connection.from, serialized_connection.from_port,
				serialized_connection.to, serialized_connection.to_port)

	graph.zoom = data.zoom
	graph.scroll_offset = data.scroll_offset * editor_scale


func get_editor_scale() -> float:
	return editor_plugin.get_editor_interface().get_editor_scale()


var last_id:String=""
## This func alteration ensures an id at least different from the last one
## generated.
func get_random_id()->String:
	var id:String=last_id
	while id == last_id:
		randomize()
		seed(Time.get_unix_time_from_system())
		id = str(randi() % 1000000).sha1_text().substr(0, 10)
	last_id = id
	return id


## The "general kind" means "class" or "resource"
## A class is a script we wrote, else it's a built-in resource
func _get_general_kind_from_a_path(pth:String)->String:
	var obj = load(pth)
	var kind:String = "unknown"
	if obj:
		if obj is Script:
			kind = "class"
		elif obj is Resource:
			kind = "resource"
	return kind


func ensure_automade_dir():
	var d = ResoureWranglerSettings.automade_path
	if DirAccess.dir_exists_absolute(d):
		return
	assert(DirAccess.make_dir_absolute(d) != OK,
	"Well, hell. I can't make the directory at %s" % [d])


func _make_a_new_resource_and_thing_node(classname)->Dictionary:
	var id = get_random_id()
	var automade:bool = false
	var paf = Hacks.lookup_script_paf_by_classname(classname)
	var newobj
	if paf == "":
		if ClassDB.can_instantiate(classname):
			# There are a bunch of resources that simply crash Godot
			# Image is one example
			print_debug("***Attempting to instance a:",
			classname, " this may crash Godot.")
			newobj = ClassDB.instantiate(classname)
		else:
			return {status=FAILED}
	else:
		print_debug("Node is a custom resource:", classname)
		newobj = load(paf).new()

	_save_automade_resource(id, newobj)
	automade = true

	var kind:String
	kind = _get_general_kind_from_a_path(newobj.get_path())
	assert(kind!="unknown", "**** That resource class has resulted in a weird sitch.")

	return {status=OK, automade=automade, id=id, new_resource_obj=newobj, kind=kind}


func make_new_resource_from_picker(classname:String, position:Vector2=Vector2.ZERO):
	var result = _make_a_new_resource_and_thing_node(classname)
	if result.status == FAILED:
		return

	var fake_dbat_data:= {
		files=[result.new_resource_obj.get_path()],
		automade=result.automade
	}

	if position == Vector2.ZERO:
		position = _center_window_calc()

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", result.id, {
		position_offset = position,
		dbat_data=fake_dbat_data
	})

	undo_redo.add_undo_method(self, "_delete_thing", result.id)
	undo_redo.commit_action()


func _something_was_dropped(dropped_data):
	# When there is no "files" key, it's usually a drop from the
	# inspector (some resource slot there) into the graph
	#print("  dropped_data:", dropped_data)
	if not dropped_data.has("files"):
		var res = dropped_data.get("resource",null)
		if res:
			#print("res.get_path():", res.get_path())
			# find the file and poke it in
			dropped_data["files"] = [res.get_path()]
		else:
			return

	# continue as if files is there
	# Use the general 'kind' to filter what we will accept
	var kind:String = _get_general_kind_from_a_path(dropped_data.files[0])
	#print(kind)
	if kind != "unknown":
		dropped_data.kind = kind
		add_thing_where_dropped(dropped_data)


func _save_automade_resource(id, res):
	if not res is Resource:
		print_debug("%s is not a Resource" % res)
		return
	var classname = Hacks.get_classname_from_a_resource(res)
	if classname.is_empty():
		classname="unknownclass"
	res.resource_path = "%s/%s_%s.tres" % \
			[ResoureWranglerSettings.automade_path, classname, id]
	ensure_automade_dir()
	assert(ResourceSaver.save(res) == OK, "Saving that object failed")


func add_thing_where_dropped(dropped_data)->void:
	var id = get_random_id()
	var resource_path:String
	var automade
	if dropped_data.kind == "class":
		#print("Dropped:", dropped_data.files[0])
		var tmp = load(dropped_data.files[0])
		#print("tmp:", tmp)
		var new_res_obj = load(dropped_data.files[0]).new()
		_save_automade_resource(id, new_res_obj)
		automade=true
		if "resource_path" in new_res_obj:
			resource_path = new_res_obj.resource_path
	else:
		# it's a resource file
		automade=false
		resource_path = dropped_data.files[0]

	_initial_add_thing_pattern(
		resource_path,
		automade,
		id,
		_drop_pos_calc(dropped_data.drop_pos),
		null, #to thing not needed here
		null, #to port not needed
		null, #from thing not needed
		false #no noodles needed either
	)


func duplicate_things(thing_list):
	# Duplicate means make a new DbatResourceNode and put the same
	# insides into it/them.
	# Position them a little to one side
	# Select all the new duplicates
	var dupes=[]
	undo_redo.create_action("Duplicate")

	for orig_thing in thing_list:
		var id:String=""
		id = get_random_id()
		var d : Dictionary
		d = orig_thing.dbat_data.duplicate()
		d.erase("state") #ensure a create mode
		_initial_add_thing_pattern(
			d.files[0],
			false, #not automades
			id,
			orig_thing.position_offset + Vector2(50,100),
			null, #to thing not needed here
			null, #to port not needed
			null, #from thing not needed
			false #no noodles needed either
		)
		dupes.append(id)

	undo_redo.commit_action()

	for id in dupes:
		things[id].selected = true


func make_unique(thing_list):
	## Loop and make each res unique.
	var dupes=[]
	undo_redo.create_action("Uniquify")

	for orig_thing in thing_list:
		var id:String=""
		id = get_random_id()

		## Docs say: For custom resources, duplicate() will fail
		## if Object._init() has been defined with required parameters.
		## Eek... :O TODO
		var new_res_obj = orig_thing.res.duplicate()
		_save_automade_resource(id, new_res_obj)
		_initial_add_thing_pattern(
				new_res_obj.get_path(),
				true, # automade!
				id,
				orig_thing.position_offset + Vector2(50,100),
				null, #to thing not needed here
				null, #to port not needed
				null, #from thing not needed
				false #no noodles needed either
				)
		dupes.append(id)

	undo_redo.commit_action()

	for id in dupes:
		things[id].selected = true


## Func called by the undo_redo methods
func _add_thing(id: String, data: Dictionary = {}) -> void:
	#print("id:", id, " data:", data)
	var editor_scale: float = get_editor_scale()
	var thing = BASE_NODE_SCENE.instantiate()

	assert(thing != null, "ARRRGH!")

	thing.size = THING_SIZE * editor_scale

	thing.board = self
	graph.add_child(thing)

	thing.name = id
	thing.from_serialized(data, editor_scale)

	graph.set_selected(thing)

	thing.selection_request.connect(_on_thing_selection_request.bind(thing))
	thing.popup_menu_request.connect(_on_thing_popup_menu_request.bind(thing))
	thing.delete_request.connect(_on_thing_delete_request.bind(thing))

	inspect_node(thing)

	#print("THING SIZE:", thing.size)

	things[id] = thing


## TODO: Weird system from Puzzle addon. I have not looked into it
## Am assuming that the DbatResourceNode calls this in order to get a
## call_deferred due to some good reason.
func set_thing_comment_text_deferred(id: String, text: String) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_comment_text", text)


func set_thing_size(id: String, size: Vector2) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_size", size)


func set_thing_position_offset(id: String, offset: Vector2) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.call_deferred("set_position_offset", offset)


func get_selected_things() -> Array:
	var selected_things: Array = []
	for thing in things.values():
		if thing.selected:
			selected_things.append(thing)
	if selected_things.is_empty(): _selected_thing = null
	return selected_things


## Runs when I use del key
func delete_selected_things() -> void:
	var things = get_selected_things()

	if things.size() == 0: return

	undo_redo.create_action("Delete things")
	for thing in things:
		var id = thing.name
		for connection in graph.get_connection_list():
			if connection.from == id or connection.to == id:
				var from_port = connection.from_port
				var to_port = connection.to_port
				undo_redo.add_do_method(graph, "disconnect_node",
				connection.from, from_port, connection.to, to_port)
				undo_redo.add_undo_method(graph, "connect_node",
				connection.from, from_port, connection.to, to_port)
		undo_redo.add_do_method(self, "_delete_thing", id)
		undo_redo.add_undo_method(self, "_add_thing", id, thing.to_serialized(get_editor_scale()))
	undo_redo.commit_action()


## Runs when a graph node is closed with the X button
## Kind of awkward. This comes from an emit() in thing.gd
func delete_thing(id: String) -> void:
	undo_redo.create_action("Delete thing")
	for connection in graph.get_connection_list():
		if connection.from == id or connection.to == id:
			var from_port = connection.from_port
			var to_port = connection.to_port
			undo_redo.add_do_method(graph, "disconnect_node",
			connection.from, from_port, connection.to, to_port)
			undo_redo.add_undo_method(graph, "connect_node",
			connection.from, from_port, connection.to, to_port)
	undo_redo.add_do_method(self, "_delete_thing", id)
	undo_redo.add_undo_method(self, "_add_thing", id, things.get(id).to_serialized(get_editor_scale()))
	undo_redo.commit_action()


func _delete_thing(id: String) -> void:
	var thing = things.get(id)
	if is_instance_valid(thing):
		thing.free()
		things.erase(id)


func _drop_pos_calc(pos)->Vector2:
	return (graph.scroll_offset + pos)\
	/ get_editor_scale() / graph.zoom - THING_SIZE * Vector2(1, 0.5)


func _center_window_calc()->Vector2:
	var editor_scale: float = get_editor_scale()
	return (graph.scroll_offset / editor_scale + size /
	editor_scale * 0.5 - THING_SIZE * 0.5) / graph.zoom


var inspect:EditorInspector
## Open the selected thing in the Inspector
## and connect a signal for proper_edited
func inspect_node(thing):
	if thing.res:
		var ei = editor_plugin.get_editor_interface()
		inspect = ei.get_inspector()
		if not inspect.is_connected("property_edited",_inspector_prop_edited):
			inspect.property_edited.connect(_inspector_prop_edited)
		ei.inspect_object(thing.res)


## Called from a signal handler in thing
func show_in_filesystem(thing):
	var ei = editor_plugin.get_editor_interface()
	var fsd:FileSystemDock=ei.get_file_system_dock()
	fsd.navigate_to_path(thing.res.resource_path)


## Event fired when stuff in the inspector was changed.
## We want to update the slots array[dict] in the thing selected
## so that it resembles the actual resource (res) which has changed.
func _inspector_prop_edited(p:String):
	# All we get is the name of something that changed.
	# So, an Array that has had element n removed, well, you can't
	# see what happened...
	# We *do* still have the old value in the slot_value ...

	if _selected_thing:
		var value = _selected_thing.res.get(p) # get value of property p in the resource
		#print("   p:", p)
		# find in the slots where that property is mentioned (if at all)
		var seek:Array = _selected_thing.slots.filter(func(d): return d.slot_name == p)
		if not seek.is_empty() and seek.size() == 1:
			var found = seek[0]
			# ** found:{ "is_array": true, "slot_name": "many_resources", "slot_type": "Resource",
			# "slot_value": [<Animation#-9223370448421460022>,
			# <ArrayOccluder3D#-9223370448656341050>,
			# InputEventMouseMotion: ...
			#], "data_slot_scene": ..., "slot_index": 3 }
			# Disconnect <ArrayOccluder3D#-9223370448656341050>

			if found.is_array:
				var old_list = found.slot_value
				var new_list = value
				for res in old_list:
					if res not in new_list:
						var thething = things.values().filter(func(i):return i.res == res)
						if not thething.is_empty():
							# Okay, we have found the Thing that was removed in the Inspector
							var from = thething[0].name
							var conn_list = graph.get_connection_list().filter(
								func(i):return i.from == from)
							if not conn_list.is_empty():
								# Okay, we have found a connection. If not ... Panic?
								var conn = conn_list.back()
								if not conn.is_empty():
									graph.disconnect_node(conn.from, conn.from_port, conn.to, conn.to_port)
									# TODO: Undo here is problematic.
									# Something to do with the Inspector. Not sure.
									#undo_redo.create_action("Disconnect thing")
									#undo_redo.add_do_method(graph, "disconnect_node",
									# conn.from, conn.from_port, conn.to, conn.to_port)
									#undo_redo.add_undo_method(graph, "connect_node",
									#  conn.from, conn.from_port, conn.to, conn.to_port)
									#undo_redo.commit_action()
			# Now assign the value to the slot_value
			#for s in seek:
			seek[0].slot_value = value #update that dict, so the thing is fresh
		else:
			#print_debug("Something is wrong with the property %s in selected %s" % \
			#		[p, _selected_thing.res])
			#_selected_thing.refresh_from_resource()
			return
		# Go refresh upstream (and myself)
		_selected_thing.cascade_update()


## Open the resource's script in the editor
func edit(thing):
	var s:Script = thing.res.get_script()
	var ei = editor_plugin.get_editor_interface()
	ei.edit_script(s)
	ei.set_main_screen_editor("Script")


var current_chooser:ChooserThing # holds the single chooser 'dialog'
var _chooser_situation = {} # preserves data across an event-gap (between funcs)

##Abstracted-out some common code involved in making a graph DbatResourceNode node
func _initial_add_thing_pattern(
	resource_path,
	automade,
	id,
	_position,
	to,
	to_port,
	from_thing,
	noodle_flag:bool):

	var fake_dbat_data:= {
		files=[resource_path],
		automade=automade
	}

	undo_redo.create_action("Add thing")
	undo_redo.add_do_method(self, "_add_thing", id,
	{
		position_offset = _position,
		dbat_data = fake_dbat_data
	}
	)
	undo_redo.add_undo_method(self, "_delete_thing", id)

	# If we have noodles we want to draw them
	if noodle_flag:
		undo_redo.add_do_method(graph,   "connect_node"   , id, 0, to, to_port)
		undo_redo.add_undo_method(graph, "disconnect_node", id, 0, to, to_port)

	undo_redo.commit_action()

	# if noodles, update the chain too
	if noodle_flag:
		from_thing.slot_changed.emit()


enum CHOOSER_KIND {NONE, MAKE_FROM_POPUP, MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY}
var kind : CHOOSER_KIND

## RMB on the GraphEdit happened.
func _on_graph_popup_request(at_position: Vector2) -> void:
	if current_chooser:
		graph.remove_child(current_chooser)
		current_chooser.queue_free()
		current_chooser = null

	#var chooser_thing: ChooserThing = ChooserThing.new()
	var chooser_thing: ChooserThing = ChooserThingScene.instantiate()
	graph.add_child(chooser_thing)
	chooser_thing.new_resource_class_chosen.connect(_new_resource_chosen)
	chooser_thing.kind1_setup(
			self,
			_drop_pos_calc(at_position)
		)
	current_chooser = chooser_thing


## Part 1 of making a new DbatResourceNode and its resource from an INPUT SLOT DROP
func make_from_input_port_drop_part1(classname, t, slot, release_position, to, to_port):
	# 1. Get a list of related resource types
	# 2. Make a new node type that lists them as choices
	# 3. clicking one will then proceed to replace this node
	#    with the new thing node.
	# I only want one chooser at any time
	if current_chooser:
		graph.remove_child(current_chooser)
		current_chooser.queue_free()
		current_chooser = null

	#var chooser_thing: ChooserThing = ChooserThing.new()
	var chooser_thing: ChooserThing = ChooserThingScene.instantiate()
	graph.add_child(chooser_thing)
	chooser_thing.new_resource_class_chosen.connect(_new_resource_chosen)
	#(_board, _thing, _classname, _posoff, _slot, _to, _to_port)
	chooser_thing.kind2_setup(
			self,
			t,
			classname,
			_drop_pos_calc(release_position),
			slot,
			to,
			to_port
		)
	current_chooser = chooser_thing


## Part 2 of making a new DbatResourceNode and its resource after a Chooser Button was pressed.
func make_from_input_port_drop_part2(classname, _chooser_situation):
	#print("part2 Make a:", classname, " details:", _chooser_situation)

	#Go make a new resource etc.
	var result = _make_a_new_resource_and_thing_node(classname)
	if result.status == FAILED:
		print_debug("Could not instance that resource.")
		return

	# Update the slot_value
	if _chooser_situation["from_slot"].is_array:
		_chooser_situation["from_slot"].slot_value.append(result.new_resource_obj)
	else:
		_chooser_situation["from_slot"].slot_value = result.new_resource_obj

	_initial_add_thing_pattern(
		result.new_resource_obj.get_path(),
		result.automade,
		result.id,
		_chooser_situation["release_position"],
		_chooser_situation["to"],
		_chooser_situation["to_port"],
		_chooser_situation["from_thing"],
		true #make the noodles too
	)


### Signals


var _selected_thing : GraphNode
func _on_thing_selection_request(thing: GraphNode):
	if get_selected_things().size() > 1:
		graph.grab_focus()
	else:
		graph.set_selected(thing)
		_selected_thing = thing
		if false:
			# Brute forcing all thing nodes to redraw when one
			# is selected because changes in resources via the
			# inspector are proving quite hard to reflect in the graph.
			for t in things.values():
				t.refresh_from_resource()
		_selected_thing.refresh_from_resource()
		inspect_node(thing)


## Offers Duplicate and Make Unique options on a node
func _on_thing_popup_menu_request(at_position: Vector2, thing: GraphNode):
	thing_menu.selected_things = get_selected_things()
	if thing_menu.selected_things.is_empty(): return
	thing_menu.popup_at(DisplayServer.mouse_get_position())


func _on_thing_delete_request(thing: GraphNode):
	call_deferred("delete_thing", thing.name)


func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Delete":
				accept_event()
				delete_selected_things()
			"Escape":
				# close the chooser if it's there.
				if current_chooser:
					_close_chooser_thing()


## A noodle has been dropped on a port
func _on_graph_connection_request(from: StringName, from_port: int, to: StringName, to_port: int) -> void:
	# to is me, the graphnode DROPPED ON
	# to_port is my port
	var to_node = things.get(to)
	var to_slot_dict = to_node.slots[to_node.get_connection_input_slot(to_port)]

	var from_node = things.get(from)
	var from_resource = from_node.res

	if to_slot_dict.is_array:
		# Make sure this Thing is not *already* plugged in
		for con in graph.get_connection_list():
			if from == con.from and to == con.to and to_port == con.to_port:
				print_debug("Already connected")
				return
		# Also make sure this thing is not already in the array!
		if to_slot_dict.slot_value == null:
			to_slot_dict.slot_value = []
		if from_resource not in to_slot_dict.slot_value:
			# Append the value to the array
			to_slot_dict.slot_value.append(from_resource)
		else:
			# Moan, but do allow the noodle connection to happen
			print_debug("That resource is already in the array.")
	else: # not an array
		# Don't connect to input that is already connected
		for con in graph.get_connection_list():
			if to == con.to and to_port == con.to_port:
				return
		# Put the value into the slot
		to_slot_dict.slot_value = from_resource

	undo_redo.create_action("Connect things")
	undo_redo.add_do_method(graph, "connect_node", from, from_port, to, to_port)
	undo_redo.add_undo_method(graph, "disconnect_node", from, from_port, to, to_port)
	undo_redo.commit_action()

	to_node.slot_changed.emit()


## DROP from an INPUT SLOT (to) out to the GraphEdit(board)
## Will remake that slot into a graph node (if there is a resource, i.e. not null)
## Else will open a list of choices (buttons) to choose a resource to make.
func _on_connection_from_input_port_to_empty(
	to: StringName, to_port: int, release_position: Vector2) -> void:
	# to : is the graph node draggin from.
	var classname:String
	var drag_from_thing : DbatBaseGraphNode = things.get(to)
	var drag_from_port : int = drag_from_thing.get_connection_input_slot(to_port)
	var slot = drag_from_thing.slots[drag_from_port]
	#print("slot?", slot)
	# What kind of drop is this?
	# Dragging out from any ARRAY slot should always start the New Resource. process
	# TODO WEIRD SITCH:
	# I once had a case where slot_value was actually nil (vs null)...
	if slot.is_array or slot.slot_value == null:
		# We are dragging from a NULL input: i.e. make a new resource
		# Or we are dragging out from an Array slot.
		classname = slot.slot_type
		if classname == "": classname = "Resource"
		make_from_input_port_drop_part1(classname, drag_from_thing, slot, release_position, to, to_port)
		# part2 is run after a chooser button press release, if any.
	else:
	# We are dropping an exisiting resource.
		var dropped_resource = slot.slot_value
		var id = get_random_id()
		var automade:bool = false
		var resource_path = slot.slot_value.get_path()
		
		_initial_add_thing_pattern(
			resource_path,
			automade,
			id,
			_drop_pos_calc(release_position),
			to,
			to_port,
			drag_from_thing,
			true # make the noodles too
		)


### A resource classname was chosen from a picker.
func _new_resource_chosen(kind:int, classname:String):
	var dict = current_chooser.get_meta("situation", {})
	_close_chooser_thing()
	match kind:
		CHOOSER_KIND.MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY:
			make_from_input_port_drop_part2(classname, dict)
		CHOOSER_KIND.MAKE_FROM_POPUP:
			make_new_resource_from_picker(classname)


func _chooser_all_resources_button_pressed(classname:String):
	make_new_resource_from_picker(classname)


## weird func. We don't need the param because there's only one
## chooser graphnode to close.
func _close_chooser_thing():
	if is_instance_valid(current_chooser):
		graph.remove_child(current_chooser)
		current_chooser.queue_free()
		current_chooser = null


## Drag from an OUTPUT to empty space
func _on_graph_connection_to_empty(from: StringName, from_port: int, release_position: Vector2) -> void:
	return


func _on_graph_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	undo_redo.create_action("Disconnect things")
	undo_redo.add_do_method(graph, "disconnect_node", from_node, from_port, to_node, to_port)
	undo_redo.add_undo_method(graph, "connect_node",  from_node, from_port, to_node, to_port)
	undo_redo.commit_action()


## Move a resource tres file from the automade dir to some other place.
func _on_filedialogue_file_selected(path: String) -> void:
	accept_event()
	var thing = file_dialogue.get_meta("thing",null)
	var res:Resource = thing.res

	if res == null: return

	file_dialogue.remove_meta("thing")

	#print("Moving ", res.resource_path, " to:", path)
	if "::" not in res.resource_path:
		#i.e. NOT res://somefile.res::Something_c4x6m
		var err = DirAccess.rename_absolute(res.resource_path, path)
		#print("err:", err)
		assert(err==OK, "Problem moving %s to %s" % [res.resource_path, path])

	res.take_over_path(path)
	res.resource_name = path.get_file()
	thing.dbat_data.files = [path]
	thing.dbat_data.erase("automade")
	
	#var main_view = get_parent().get_parent().get_parent()
	#main_view.save_board()

	# Replace all such paths in the database file.
	var our_db_tres_file = FileAccess.open(
			ResoureWranglerSettings.database_path,
			FileAccess.READ_WRITE)
	var dbf_string:String = our_db_tres_file.get_as_text()
	if path in dbf_string:
		dbf_string = dbf_string.replace(res.resource_path,path)
		our_db_tres_file.store_string(dbf_string)
	our_db_tres_file.close()


	thing.refresh_from_resource()

	file_dialogue.visible = false

