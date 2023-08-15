@tool #make sure this is used
class_name ExtendedResourceNode
extends DbatResourceBase #and then extend this class

## TIP: If you get weird errors like Resource has no method "show_node_gui"
## then restart the project. Godot is iffy like that.

#-- exports --#

@export_group("Meshes")
@export var my_meshes:Array[Mesh]

#-- code --#

## My gui
const SCENE_PRELOAD = preload("sample_extended_ui.tscn")

## Now implement this func:
## Calls parent which handles adding the gui
## Then does the necc to show the data in the gui
func show_node_gui(graphnode:GraphNode, data: Dictionary, _nop) -> void:
	super.show_node_gui(graphnode, data, SCENE_PRELOAD)
	
	var list : ItemList = SLOT_SCENE.get_node("slotvalue")
	list.clear()
	
	for m in my_meshes:
		list.add_item( str( (m as Mesh).get_faces()[0] ) )
