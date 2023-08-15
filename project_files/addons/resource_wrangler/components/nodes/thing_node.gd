@tool
class_name DbatBaseGraphNode
extends GraphNode

# MIT License
#
# Original Work Copyright (c) 2022 Nathan Hoad
# Modified work Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
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


## This entire file controls the node which reflects a Resource.


signal selection_request()
signal popup_menu_request(position: Vector2)
signal delete_request()
signal slot_changed


const DataSlotScene = preload("res://addons/resource_wrangler/components/slot.tscn")
const DataSlotScript = preload("res://addons/resource_wrangler/components/slot.gd")

const ResoureWranglerSettings = preload("res://addons/resource_wrangler/utilities/settings.gd")
const Hacks = preload("res://addons/resource_wrangler/utilities/class_hacks.gd")

const array_porticon:Texture2D = preload("res://addons/resource_wrangler/assets/array_port_icon_cleaned.svg")


var board:Control

var comment_text: String = "":
	get:
		return comment_text

## A packet of info about this thing. For serializing etc.
## TODO: This is a bit silly.
var dbat_data: Dictionary:
	get:
		return dbat_data

var classname_label: String = "":
	get: return classname_label

# slots array needs element 0 to be filled. It won't be used, so it's a null dict
var slots:Array[Dictionary] = [{slot_name=null}]
var res : Resource
var resource_previews:Array


@onready var frame_style: StyleBoxFlat = get("theme_override_styles/frame")
@onready var frame_automade_style: StyleBoxFlat = preload("res://addons/resource_wrangler/assets/graphnode_automade.stylebox")
@onready var frame_missing_resource_style: StyleBoxFlat = preload("res://addons/resource_wrangler/assets/graphnode_missing_resource_file.stylebox")
@onready var selected_style: StyleBoxFlat = get("theme_override_styles/selected_frame")

@onready var comment_text_control: TextEdit = %comment_text
@onready var thing_classname_label := %classname
@onready var edit_script_button := %editscript
@onready var thing_icon := %icon
@onready var preview_texrect := %preview



func _ready() -> void:
	#print_debug("_ready on:", name)
	call_deferred("apply_theme")
	comment_text_control.set("theme_override_styles/focus",
	comment_text_control.get("theme_override_styles/normal"))
	slot_changed.connect(_slot_changed)


func apply_theme() -> void:
	#edit_script_button.visible = false #complains all the time
	if edit_script_button:
		edit_script_button.icon = get_theme_icon("GDScript", "EditorIcons")

	if is_instance_valid(comment_text):
		comment_text_control.add_theme_font_override("font", get_theme_font("bold", "EditorFonts"))


func _format_underscores(s:String)->String:
	#return s.replace("_","/")
	#return s.replace("_"," ")
	return s


func set_comment_text(next_text: String) -> void:
	comment_text = next_text


func to_serialized(scale: float) -> Dictionary:
	return {
		id = name,
		comment_text = comment_text,
		position_offset = position_offset / scale,
		size = size / scale,
		dbat_data = dbat_data,
		updown = updown
	}


## I want automatic "slot type" ints for the graph ports
## I will try to make them from the hash
## of the string of a class_name.
func _get_slot_type(classname:String)->int:#obj:Resource)->int:
	#print("                                slot type:", classname)
	return Hacks.smallhash(_get_slot_type_name(classname,{}))


func _get_slot_type_name(classname, prop_dict:Dictionary)->String:
	if classname == "Array":
		if prop_dict:
		#{ "name": "many_resources", "class_name": &"", "type": 28,
		#"hint": 23, "hint_string": "24/17:Resource", "usage": 6 } <-- real Array[Resource]
		#{ "name": "vague_array", "class_name": &"", "type": 28,
		#"hint": 0, "hint_string": "Array", "usage": 6 } <-- Variant Array of who knows what.
			if "24/17:" in prop_dict.hint_string:
				classname = prop_dict.hint_string.replace("24/17:","")
		else:
			classname = "BAD_PROPERTY_ARRAY_TYPE"

		return classname
	
	if classname == "" or classname == "NO_CLASS_NAME":
		push_warning("There is no class name for this object")
		return "NO_CLASS_NAME"
		
	if classname in board.editor_plugin.blocked_resource_classes:
		return "BLACKLISTED_CLASS"
	
	#print("classname:", classname)

	if ClassDB.class_exists(classname): #it's a built-in resource
		var bc = Hacks.get_base_class_name_of_builtin_resources(classname)
		return bc

	var base_class_name:String = Hacks.get_base_class_name_of_custom_resources(classname)
	
	return base_class_name


## A very sloppy way to try and get a constant color
## via random, from a class name as a string.
var rn = RandomNumberGenerator.new()
func _get_port_col(classname:String)->Color:
	var c:Color = Color.BLACK
	var num:int = Hacks.smallhash(classname)
	rn.seed = num # this is the key to getting same values for each classname
	var floatynum:float = float(num) * rn.randf()
	var x = remap(floatynum, 0., 512.0 , 0., 1.)
	c = c.from_ok_hsl(x, 0.6, 0.6)
	return c


## Ask the resource if it has a "preview_this" method
## and return what it supplies, or just the obj.
## This makes-use of a special method in custom classes.
func _get_preview_resource(obj):#:Resource):
	if not obj: return
	if obj is Array: return
	if obj.has_method("preview_this"):
		#print("preview_this on obj:", obj, " ==", obj.preview_this())
		return obj.preview_this()
	#print("obj ", obj, " has no method")
	return obj


## TODO: I can't get this to work well. Many resource previews
## simply refuse to update or are out of synch. I also need a
## better way to display custom resource class previews which
## may mean multiple preview icons or some chosen main one.
func _set_preview():

	var prev
	# if we are not one of my custom classes:
	#if res and not res.has_method("preview_this"):
	if not res.has_method("preview_this"):
		prev = res # we will just pass resource entirely
		# Notes/Quirks:
		# FastNoiseLite simply will not draw a texture. yay.
		# NoiseTexture2D seems to be one out of step with the
		# actual settings. E.g "as_normap_map" will show the opposite
		# image to what you'd expect.

	# otherwise it is one of my resource classes
	else:
		if resource_previews.is_empty():
			return
		# Find anything at all to show in the properties
		for r in resource_previews:
			if r:
				prev = r
				#print("previewing r:", r)
				break
	if board and board.editor_plugin:
		var rp:EditorResourcePreview=\
		board.editor_plugin.get_editor_interface().get_resource_previewer()
		#print(" res sent for preview:", res)
		rp.queue_edited_resource_preview( prev, self, "_resource_preview_ready", prev)
		#wierd:  rp.queue_resource_preview( prev.get_path(), ...)


## Call-back for the queue_edited_resource_preview command
func _resource_preview_ready(path:String, texture:Texture2D, thumbnail_preview:Texture2D, prev):
	#path is string like this : "ID:-9223370458538119925" huh?
	#print(path, "  ", prev, " ",  texture, thumbnail_preview)
	preview_texrect.texture = null

	# Trying to ensure that big dumps of binary data don't get saved into the
	# thing_node.tscn file...
	preview_texrect.owner = null

	if thumbnail_preview:
		preview_texrect.texture = thumbnail_preview
		preview_texrect.custom_minimum_size = Vector2(64,64)
		preview_texrect.visible = true
		return

	if texture:
		preview_texrect.texture = texture
		preview_texrect.custom_minimum_size = Vector2(64,64)
		preview_texrect.visible = true
		return

	preview_texrect.visible = false
	preview_texrect.custom_minimum_size = Vector2(0,0)


## Only allow is Object through. Disallow Scripts.
func _allow_through(dict:Dictionary)->bool:
	var obj = res.get(dict.name)
	if dict.name == "script":
		return false
	match dict.type:
		24 : return true #Object
		28 : #Array
			#24/17:BoxMesh == Array[BoxMesh] etc.
			# Ensure an Array[<Resource>]
			if "24/17:" in dict.hint_string:
				return true

	return false


# Welcome, random enum, to life!
enum mode {NONE, CREATE, UPDATE, MISSING}


func refresh_from_resource():
	#print("refreshing thing:", self, " res:", self.res)
	#from_serialized({state=mode.UPDATE}, 0)
	#await get_tree().process_frame
	call_deferred("from_serialized",{state=mode.UPDATE}, 0)


## Recursive chain upstream from graph to the rhs output to next graph etc.
func cascade_update():
	# refresh me
	self.refresh_from_resource()
	# Now, who do i connect to?
	var who_i_connect_to : Array = board.graph.get_connection_list().filter(
		func(d):return d.from == self.name)
	# tell each of them to also refresh.
	for graph in who_i_connect_to:
		var other_graph = board.things.get(graph.to)
		if other_graph:
			other_graph.cascade_update()


# holds the class that may (or may not) be an extension of this node
var node_extension : DbatResourceBase

## Painfully recnstruct the entire graph node (me) to represent the
## latest info.
var state:int
func from_serialized(data: Dictionary, scale: float) -> void:
	#print("from ser:", data)
	# Just pull out the state, if not there we assume CREATE
	state = data.get("state", mode.CREATE)
	if state == mode.CREATE:
		if data.has("comment_text"): set("comment_text", data.comment_text)
		if data.has("position_offset"): set("position_offset", data.position_offset * scale)
		if data.has("size"): set("size", data.size * scale)
		if data.has("dbat_data"): set("dbat_data", data.dbat_data)

		updown = data.get("updown",false)
		updown_state = int(updown) + 1

	# The files string will be some kind of resource target.
	# either a .tres/res file or someother file::BoxMesh_hts6 etc.
	res = load(dbat_data.files[0])
	if not res: #oh shit..the resource file is bad!
		state = mode.MISSING

	# If this file is in automade_path, make sure it's flagged such.
	dbat_data["automade"] = res.get_path().begins_with(
			ResoureWranglerSettings.automade_path)

	var tit:String
	var graph_main_classname:String
	if state != mode.MISSING:

		var slotidx:int=1
		graph_main_classname = Hacks.lookup_class_name_by_paf(dbat_data.files[0])
		#print("dbat_data.files[0]:", dbat_data.files[0])
		#print("graph_main_classname:",graph_main_classname)
		resource_previews.clear()
		dbat_data.classname = "NO CLASS YET"
		if graph_main_classname:
			dbat_data.classname = graph_main_classname

			var properties = res.get_property_list()
			#print("   p:", properties)

			for i in range(properties.size()):
				if _allow_through(properties[i]):
					# this next call returns "Array" if any kind of array
					var property_classname =\
					Hacks.get_class_name_from_resource_property(properties[i])

					if property_classname:
						var DATA_SLOT_SCENE
						var prop_var_value
						match state:
							mode.CREATE:
								DATA_SLOT_SCENE = DataSlotScene.instantiate()
								add_child(DATA_SLOT_SCENE) # do now to get ready to run early
								# look up the property in the actual resource to get the value
								# i.e if there's a var called "BOO" in res, then
								# we are getting res.BOO
								prop_var_value = res.get(properties[i]["name"])
								#print("prop_var_value:", prop_var_value)
							mode.UPDATE:
								DATA_SLOT_SCENE = slots[slotidx].data_slot_scene
								prop_var_value = slots[slotidx].slot_value
								# make sure to put the updated value into the
								# actual resource's variable
								#print("ALTERING RESOURCE:", properties[i].name)
								res.set(properties[i].name, prop_var_value)
						var slot_dict = {}

						slot_dict["is_array"] = property_classname == "Array"
						slot_dict["slot_name"] = properties[i].name
						var slot_typename:String
						slot_typename = _get_slot_type_name(
								property_classname, properties[i])
						slot_dict["slot_type"] = slot_typename
						slot_dict["slot_value"] = prop_var_value
						slot_dict["data_slot_scene"] = DATA_SLOT_SCENE
						slot_dict["slot_index"] = slotidx

						if state == mode.CREATE:
							slots.append(slot_dict)

						# Set slot label
						var dsc = slot_dict.data_slot_scene
						dsc.slot_label.text = "%s:" % [slot_dict.slot_name]
						var stypename:String = slot_dict.slot_type
						if slot_dict["is_array"]:
							stypename = "Array[%s]" % slot_dict.slot_type
						dsc.slot_value.text ="(%s) %s" % \
							[ stypename,
							_shorten_resource_id(slot_dict.slot_value) ]

						# Set slot INPUT port
						var slot_type:int
						var slot_icon = null
						var port_color: Color
						if slot_dict["is_array"]:
							# Array of type <slot_type>
							#print("classname:", graph_main_classname, " 
							#port in is array:", slot_dict.slot_type)
							slot_icon = array_porticon
							slot_type = _get_slot_type(slot_dict.slot_type)
							var tmp = Hacks.get_base_class(slot_dict.slot_type)
							#print("  :", graph_main_classname, " I am:", slot_type
							#, " IN type:", tmp)
							port_color = _get_port_col(tmp)
						else:
							# Anything else
							slot_type = _get_slot_type(property_classname)
							#print("  :", graph_main_classname, " I am:", slot_type
							#, " IN type:", property_classname)
							port_color = _get_port_col(property_classname)
							#	Hacks.get_base_class(property_classname))

						set_slot(slotidx,
							true, slot_type, port_color,
							false,0, Color(0,1,0),
							slot_icon, # left icon
							null,
							true
						)

						if state == mode.CREATE:
							DATA_SLOT_SCENE.clear_button.pressed.connect(
								_slot_clear_button_pressed.bind(slotidx)
							)

						# RESOURCE PREVIEW
						resource_previews.append(
								_get_preview_resource(
										prop_var_value))

						slotidx += 1

			# Class Icon
			var icon:Texture2D = Hacks.get_icon_for(
					graph_main_classname,
					board.editor_plugin)
			if icon:
				thing_icon.texture = icon

			# Style of frame
			if dbat_data.get("automade",null):
				self.set("theme_override_styles/frame", frame_automade_style)
				tit = "AUTOMADE %s"
			else:
				self.set("theme_override_styles/frame", frame_style)

			classname_label = graph_main_classname
			
			## Get a better name from the Resource's @group_export
			## command, if any.
			#This does not work as I had hoped...
#			var eg = properties.filter(func(i): return i.usage == 64)#@group==64
#			print("classname:", classname_label,  " eg:", eg)
#			if eg:
#				var tmp = eg.back().name
#				if not tmp.is_empty() and tmp != "Resource":
#					classname_label = tmp
			#print("classname_label:", classname_label)

			# Display the classname
			thing_classname_label.text = classname_label
			%classname_as_title.text = classname_label

			#Comment
			comment_text_control.text = comment_text

			# Draw any extra extension gui stuff on the end
			if res.has_method("show_node_gui"):
				## we are a special resource
				res.show_node_gui(self, data, false)

		#Set the graph node 'window' title at the top
		tit = dbat_data.files[0].get_file().get_basename()
		var refc = "0"
		if res:
			refc = str(res.get_reference_count())

		if state != mode.MISSING:
			%title.text ="%s\nResource %s [count:%s]" % [tit, _shorten_resource_id(res),refc]
		else:
			%title.text = "%s" % tit

		# set the main out node
		var tmp = graph_main_classname #Hacks.get_base_class(graph_main_classname)
		#print("MAIN NODE:", graph_main_classname, " OUT:", tmp)
		var graph_slot_type = _get_slot_type(graph_main_classname)
		var out_port_color: Color = _get_port_col(tmp)#graph_main_classname)
		set_slot(0,
			false, 0, Color(0,1,0),
			true, graph_slot_type, out_port_color,
			null, null, true
		)
	# else MISSING : No class name
	else:
		tit = "MISSING/BAD RESOURCE FILE\n%s" % str(res)
		%classname_as_title.text = tit

	if state != mode.MISSING:
		call_deferred("_set_preview")

	# Go hide/show controls to 'render' this node
	call_deferred("render_node_gui")

	if state == mode.UPDATE:
		board.inspect_node(self)


## This is where we do all ths hide/show stuff for the roll
## up or down or missing guis.
var updown:bool = false
enum rolledstate {DUNNO, UP,DOWN}
var updown_state = rolledstate.DUNNO
func render_node_gui():
	match updown_state:
		rolledstate.DOWN:
			if updown: #told to go up
				updown_state = rolledstate.UP
		rolledstate.UP:
			if updown == false: #told to go down
				updown_state = rolledstate.DOWN

	match updown_state:
		rolledstate.DOWN:
			if state != mode.MISSING:
				$VBox.propagate_call("set_visible",[true])
				$VBox.propagate_call("set_visible",[true])
				%classname_as_title.visible = false
				%comment_text.visible = true
				%moveto.visible = true
				for s in get_children():
					s.set_size(Vector2(s.get_size().x,32))
				set("size",0) #seems to work out the actual size !
			else:
				self.set("theme_override_styles/frame", frame_missing_resource_style)
				%moveto.visible = false
				%comment_text.visible = false
				%classname_as_title.visible = true

		rolledstate.UP:
			$VBox.propagate_call("set_visible",[true])
			# hide it all
			$VBox.propagate_call("set_visible",[false])
			# then start showing certain things
			%title_and_x.visible = true #propagate_call("set_visible",[true])
			%classname_as_title.visible = true
			%comment_text.visible = false
			$VBox.visible = true
			for s in get_children():
				s.set_size(Vector2(s.get_size().x,23))
			$VBox.size.y = 64
			set("size",64)


func _shorten_resource_id(r)->String:
	# because r is an Object/Array, stringifying it will add
	# the <...> brackets. I redact the start and assume the end.
	if r is Array:
		if r.is_empty():
			return "<empty array>"
		return "<%s>" % r.size()
	if r:
		var s = str(r)
		return "<RES%s  " % s.right(6)
	return "<null>"


### Signals

func _slot_changed():
	accept_event()
	cascade_update()


func _on_thing_theme_changed() -> void:
	apply_theme()


func _on_thing_dragged(from: Vector2, to: Vector2) -> void:
	board.undo_redo.create_action("Move thing")
	board.undo_redo.add_do_method(board, "set_thing_position_offset", name, to)
	board.undo_redo.add_undo_method(board, "set_thing_position_offset", name, from)
	board.undo_redo.commit_action()


func _on_text_edit_focus_entered() -> void:
	emit_signal("selection_request")


func _on_text_edit_focus_exited() -> void:
	if comment_text_control.text != comment_text:
		board.undo_redo.create_action("Set thing text")
		board.undo_redo.add_do_method(board, "set_thing_comment_text_deferred",
		 name, comment_text_control.text)
		board.undo_redo.add_undo_method(board, "set_thing_comment_text_deferred",
		 name, comment_text)
		board.undo_redo.commit_action()


func _on_thing_gui_input(event: InputEvent) -> void:
	#print("thing event:", event)
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 2:
		emit_signal("popup_menu_request", event.global_position)
		accept_event()

	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.graph.grab_focus()

	if event is InputEventMouseButton and event.double_click:
		updown = !updown
		render_node_gui()
		accept_event()


func _on_node_selected() -> void:
	emit_signal("selection_request")


func _on_editscript_pressed() -> void:
	board.edit(self)


## Clear the slot's name and value
## Also remove any noodle going into it.
func _slot_clear_button_pressed(idx):
	var val = slots[idx].slot_value

	board.undo_redo.create_action("Clear slot")

	if slots[idx].is_array:
		board.undo_redo.add_do_method(self, "_clear_slot_array", idx)
		board.undo_redo.add_undo_method(self, "_set_slot_value", idx, val)
	else:
		board.undo_redo.add_do_method(self, "_set_slot_value", idx, null)
		board.undo_redo.add_undo_method(self, "_set_slot_value", idx, val)

	var cl = board.graph.get_connection_list()
	idx = idx - 1
	# find myself in the list, also narrow it down to the exact to_port
	# should return only one element (or none) in cl:
	cl = cl.filter(func(i):return i.to == self.name and i.to_port == idx)

	if not cl.is_empty():
		for d in cl:
			var from_port = d.from_port
			var to_port = d.to_port
			var from_node = d.from
			var to_node = self.name
			#print("from_node:",from_node," from_port:",
			#from_port," to_node:", to_node, " to_port:", to_port)
			board.undo_redo.add_do_method(
					board.graph, "disconnect_node", from_node, from_port, to_node, to_port)
			board.undo_redo.add_undo_method(
					board.graph, "connect_node",  from_node, from_port, to_node, to_port)

	board.undo_redo.commit_action()
	accept_event()


func _clear_slot_array(idx):
	slots[idx].slot_value.clear()
	#print("clearing:", slots[idx].slot_value)
	refresh_from_resource()
	# works here, but not in refresh_from_resource() ... timing?
	board.inspect_node(self)


## Used from an undoredo
func _set_slot_value(idx, val):
	slots[idx].slot_value = val
	refresh_from_resource()


func _on_moveto_pressed() -> void:
	var fd:FileDialog = board.file_dialogue
	fd.set_filters(PackedStringArray(["*.tres"]))
	fd.set_meta("thing",self) # using the meta to store the thing ref
	fd.visible = true


func _on_close_pressed() -> void:
	emit_signal("delete_request")


func _on_showinfs_pressed() -> void:
	board.show_in_filesystem(self)

