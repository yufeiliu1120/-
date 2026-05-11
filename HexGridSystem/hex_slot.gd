class_name HexSlot
extends Node2D

# 挂点的自定义轴向坐标 (Q, R)
@export var axial_coords: Vector2i

# 内部变量，记录当前放置的地块
var _current_tile: Node2D = null

# 接口 1：放置地块
func place_tile(tile_node: Node2D) -> void:
	_current_tile = tile_node
	
	# 【核心修复】：不要用 add_child
	# 使用 reparent 可以安全地将它从原来的父节点剥离，并转移到挂点下
	if tile_node.get_parent() != self:
		tile_node.reparent(self)
		
	# 转移父节点后，归零局部坐标，它就会完美吸附在挂点中心
	tile_node.position = Vector2.ZERO

# 接口 2：去除地块
func remove_tile() -> Node2D:
	var tile = _current_tile
	if tile:
		remove_child(tile)
		_current_tile = null
	return tile

# 接口 3：返回挂点下的地块
func get_tile() -> Node2D:
	return _current_tile

# 辅助接口：检查是否为空
func is_empty() -> bool:
	return _current_tile == null
