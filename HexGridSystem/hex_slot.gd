class_name HexSlot
extends Node2D

# 挂点的自定义轴向坐标 (Q, R)
@export var axial_coords: Vector2i

# 内部变量，记录当前放置的地块
var _current_tile: Node2D = null

# 接口 1：放置地块
# 接口 1：放置地块 (升级版)
func place_tile(tile_node: Node2D) -> void:
	_current_tile = tile_node
	var current_parent = tile_node.get_parent()
	# 【健壮性修复】：分情况处理
	if current_parent == self:
		pass # 已经在自己下面了，什么都不用做
	elif current_parent == null:
		# 情况 A：这是后台代码刚刚 instantiate() 出来的，直接 add_child
		add_child(tile_node)
	else:
		# 情况 B：这是从其他地方（比如拼装界面）拖过来的，安全剥离并转移
		tile_node.reparent(self)
	# 归零局部坐标，完美吸附
	tile_node.position = Vector2.ZERO
	# 顺便在这里帮地块认领它的“家”，外部连这行代码都省了！
	if "current_slot" in tile_node:
		tile_node.current_slot = self
	
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
