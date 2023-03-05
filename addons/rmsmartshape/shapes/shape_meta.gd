@tool
@icon("../assets/meta_shape.png")
extends SS2D_Shape_Base
class_name SS2D_Shape_Meta

"""
This shape will set the point_array data of all children shapes
"""

@export var press_to_update_cached_children: bool = false : set = _on_update_children
var _cached_shape_children: Array = []


#############
# OVERRIDES #
#############
func _init():
	super._init()
	_is_instantiable = true


func _ready():
	for s in _get_shapes(self):
		_add_to_meta(s)
	call_deferred("_update_cached_children")
	super._ready()


func _draw():
	pass


func remove_child(node: Node):
	_remove_from_meta(node)
	call_deferred("_update_cached_children")
	super.remove_child(node)


func add_child(node: Node, force_readable_name: bool = false, internal: InternalMode = 0):
	_add_to_meta(node)
	call_deferred("_update_cached_children")
	super.add_child(node, force_readable_name, internal)


func add_sibling(sibling: Node, force_readable_name: bool = false):
	_add_to_meta(sibling)
	call_deferred("_update_cached_children")
	super.add_sibling(sibling, force_readable_name)


func _on_dirty_update():
	pass


func set_as_dirty():
	_update_shapes()

########
# META #
########
func _on_update_children(ignore: bool):
	#print("Updating Cached Children...")
	_update_cached_children()
	#print("...Updated")


func _update_cached_children():
	# TODO, need to be made aware when cached children's children change!
	_cached_shape_children = _get_shapes(self)
	if treat_as_closed():
		can_edit = false
		if editor_debug:
			print ("META Shape contains Closed shapes, edit the meta shape using the child closed shape; DO NOT EDIT META DIRECTLY")
	else:
		can_edit = true
		if editor_debug:
			print ("META Shape contains no Closed shapes, can edit META shape directly")


func _get_shapes(n: Node, a: Array = []) -> Array:
	for c in n.get_children():
		if c is SS2D_Shape_Base:
			a.push_back(c)
		_get_shapes(c, a)
	return a


func _add_to_meta(n: Node):
	if not n is SS2D_Shape_Base:
		return
	# Assign node to have the same point array data as this meta shape
	n.set_point_array(_points, false)
	n.connect("points_modified",Callable(self,"_update_shapes").bind(n))


func _update_shapes(except: Array = []):
	_update_curve(_points)
	for s in _cached_shape_children:
		if not except.has(s):
			s.set_as_dirty()
			s._update_curve(s.get_point_array())


func _remove_from_meta(n: Node):
	if not n is SS2D_Shape_Base:
		return
	# Make Point Data Unique
	n.set_point_array(n.get_point_array(), true)
	n.disconnect("points_modified",Callable(self,"_update_shapes"))

func treat_as_closed()->bool:
	var has_closed = false
	for c in _cached_shape_children:
		if c is SS2D_Shape_Closed:
			has_closed = true
			break
	if has_closed:
		return true
	return false
