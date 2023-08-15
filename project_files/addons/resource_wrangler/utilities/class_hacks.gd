@tool
extends RefCounted

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

## Various desperate functions to handle GDscript's weird class name crap
## Also ways to get icons and such. Just general mayhem.

const DefaultGodotIcon:Texture2D = preload("res://addons/resource_wrangler/assets/icon.png")

static func smallhash(classname:String)->int:
	return abs(classname.hash() % 512) # hopefully not more than 512 resource types!
	
	
## Reach down into the source code of a resource and 
## pluck-out any reference to the @icon
static func get_script_icon_paf(res:Resource)->String:
	if not res: return ""
	var s:Script
	# sometimes I call this with a basic load of a resource
	# which means res is already a GDScript:
	if res is GDScript:
		s = res
	else:
		# else we need to do more work to find the 
		# actual script
		var scrpt = res.get_script()
		if not scrpt: return ""
		s = load(scrpt.get_path())
	var src:String = s.source_code
	var regex = RegEx.new()
	regex.compile("@icon\\(\"(.*)\"\\)")
	var result = regex.search(src)
	if result:
		return result.get_string(1)
	return ""


## Get an icon for a resource class, by hook or by crook.
## Hardwired to 16x16.
#static func get_icon_for(res_class_name, editor_plugin)->Texture2D:
#	var icon:Texture2D
#	var iconpaf:=""
#	if not is_class_custom(res_class_name):
#		var ei = editor_plugin.get_editor_interface()
#		var godot_theme = ei.get_base_control().theme
#		if godot_theme.has_icon(res_class_name, 'EditorIcons'):
#			icon = godot_theme.get_icon(res_class_name, 'EditorIcons')
#	else:
#		var respaf = lookup_script_paf_by_classname(res_class_name)
#		var res = load(respaf)
#		iconpaf = get_script_icon_paf(res)
#
#	if icon : return icon
#
#	if iconpaf == "":
#		iconpaf = "res://addons/resource_wrangler/assets/icon.png"
#
#	var image:Image = Image.load_from_file(iconpaf)
#	icon = ImageTexture.create_from_image(image)
#	icon.set_size_override(Vector2i(16,16))
#
#	return icon


static var default_icon_as_texture2d:Texture2D
## Get an icon for a resource class, by hook or by crook.
## Hardwired to 16x16.
static func get_icon_for(res_class_name, editor_plugin)->Texture2D:
	var icon:Texture2D
	# it's not a custom class
	var iconpaf:=""
	if not is_class_custom(res_class_name):
		var ei = editor_plugin.get_editor_interface()
		var godot_theme = ei.get_base_control().theme
		if godot_theme.has_icon(res_class_name, 'EditorIcons'):
			icon = godot_theme.get_icon(res_class_name, 'EditorIcons')
	#it is a custom class
	else:
		var respaf = lookup_script_paf_by_classname(res_class_name)
		var res = load(respaf)
		iconpaf = get_script_icon_paf(res)

	if icon : return icon #early out

	var image:Image
	if iconpaf.is_empty():
		# Try to get the godot icon from a cache, else make it and resize it.
		if not default_icon_as_texture2d:
			icon = DefaultGodotIcon
			image = icon.get_image()
			default_icon_as_texture2d = ImageTexture.create_from_image(image)
			default_icon_as_texture2d.set_size_override(Vector2i(16,16))
		icon = default_icon_as_texture2d
	else:
		image = Image.load_from_file(iconpaf)
		icon = ImageTexture.create_from_image(image)
		icon.set_size_override(Vector2i(16,16))
	return icon
	
	

static func lookup_script_paf_by_classname(classname:String)->String:
	var a = ProjectSettings.get_global_class_list()
	var find = a.filter(func(d): return StringName(classname) == d["class"])
	var ret : String = ""
	if not find.is_empty():
		ret = find[0]["path"]
	return ret


## If all you have is a script path and you want the class_name
## Custom resource scripts that DO NOT have a class_name statement
## get a blank classname, which causes trouble upstream.
static func lookup_class_name_by_script(paf:String)->String:
	var a = ProjectSettings.get_global_class_list()
	var find = a.filter(func(d): return paf in d["path"])
	var ret : String = ""
	if not find.is_empty():
		ret = find[0]["class"]
	return ret


## If all you have is a path to a resource, and you want the class_name
## of the script that built it:
static func lookup_class_name_by_paf(trespaf:String)->String:
	var res := load(trespaf)
	if not res:
		print_debug("%s path does not point to a resource file. Check orphans perhaps?" \
				% [trespaf])
		return ""
	var graph_main_classname:String=""
	if res.script:
		var res_script : String=res.script.get_path()
		# Note: If the script has no class_name keyword then the
		# res_script is not matched in the lookup test below:
		graph_main_classname=lookup_class_name_by_script(res_script)
		# Therefore it comes back as empty. So we make sure to id it:
		if graph_main_classname == "":
			graph_main_classname="NO_CLASS_NAME"
			push_warning("Please make sure your script has a class_name:%s" % res_script)
		return graph_main_classname
	if res.get_class():
		graph_main_classname = res.get_class()
		#print("used get_class to find:", graph_main_classname)
	return graph_main_classname


## If all you have is a property name from some resource, gets
## the classname of that property.
## Slightly dodgy...
static func get_class_name_from_resource_property(propsdict):
	#print("  propsdict:", propsdict)
	# var properties = res.get_property_list()
	#[0]:DataResource_Plants_Fruits_Printerplants from:{
	# "name": "single_scene_bundle_resource",
	# "class_name": &"", "type": 24, "hint": 17,
	# "hint_string": "GraphicsBundle", "usage": 4102 }
	#  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	#[1]:DataResource_Plants_Fruits_Printerplants from:{
	# "name": "multiscene_resource",
	# "class_name": &"", "type": 24, "hint": 17,
	# "hint_string": "MultisceneResource", "usage": 4102 }
	#  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	# :D \o/
	#
	# Ah, also possible to get this kind of string too:
	# "hint_string": "BaseMaterial3D,ShaderMaterial"
	
	# More weird:
	# When a property is an Array, we get this kind of thing:
	# @export var many_resources : Array[Resource]
	# { "name": "many_resources", "class_name": &"", "type": 28,
	# "hint": 23, "hint_string": "24/17:Resource", "usage": 4102 }]
	#
	# @export var vague_array : Array
	# { "name": "vague_array", "class_name": &"", "type": 28,
	# "hint": 0, "hint_string": "Array", "usage": 4102 }]
	#
	
	var hs:String = propsdict.hint_string
	
	if propsdict.type == 28: #Array
		return "Array"
		
	# works ok with one, or, more, csv, strings
	var reths:PackedStringArray = hs.split(",",false)
	
	
	#print("       hs:", hs)
	#print("        reths:", reths)
	# e.g. we use an extension class and it has no slots of its own
	if reths.is_empty() : return ""
	
	var ret = String(reths[0])
	
	return ret


## Returns the base of either builtin or custom classname
static func get_base_class(classname)->String:
	#print("   classname:", classname, "->")
	if is_class_custom(classname):
		#print("        ", get_base_class_name_of_custom_resources(classname))
		return get_base_class_name_of_custom_resources(classname)
	#print("        ", get_base_class_name_of_builtin_resources(classname))
	return get_base_class_name_of_builtin_resources(classname)
		

## Given a BUILTIN classname like "mesh", this will return a string of
## a class name one up from Resource. 
static func get_base_class_name_of_builtin_resources(classname)->String:
	var parentclass = ClassDB.get_parent_class(classname)
	if parentclass=="Resource":
		return classname
	if parentclass=="":
		return "Resource"
	return get_base_class_name_of_builtin_resources(parentclass)


## I want to know *how* related this CUSTOM class is to a basic resource.
## I need a way to walk down the chain until the one that extends Resource
static func get_base_class_name_of_custom_resources(classname)->String:
	if classname != "NO_CLASS_NAME":
		#**:[{ "class": &"MultisceneResource", "language": &"GDScript",
		# "path": "res://resources/database/data_resources/sub_resources/base_class/multisceneresource.gd",
		# "base": &"Resource", "icon": "" }]
		#**:[{ "class": &"MultisceneResource_Plant", "language": &"GDScript",
		# "path": "res://resources/database/data_resources/sub_resources/base_class/multisceneresource_plant.gd",
		# "base": &"MultisceneResource", "icon": "" }]
		var a = ProjectSettings.get_global_class_list() #expensive!!!
		
		var find = a.filter(
			func(d):
			return classname == d["class"]
			).back()
			
		#print("Found base for:", classname, " ===> ", find)
		
		if find.base == &"Resource":
			return classname
			
		return get_base_class_name_of_custom_resources(find.base)
	return "NO_CLASS_NAME"

## Is the given classname a custom class?
static func is_class_custom(classname)->bool:
	return not ClassDB.class_exists(classname)


## Can we actually instantiate the given classname?
static func can_we_instantiate(classname)->bool:
	if is_class_custom(classname):
		return true
	return ClassDB.can_instantiate(classname)


##Given some random Resource, attempt to get the class name
static func get_classname_from_a_resource(res:Resource):#->String:
	var got_script = res.get_script()
	if got_script:
		var script_paf = res.get_script().get_path()
		return lookup_class_name_by_script(script_paf)
	var res_file = res.resource_path
	if res_file:
		return lookup_class_name_by_paf(res_file)
	var hope = res.get_class()
	if hope: 
		return hope
	return "unknown"
	
