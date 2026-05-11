class_name BeetleGridManager
extends Node2D

# 储存所有挂点的字典。键: Vector2i 坐标，值: HexSlot 节点
var hex_grid: Dictionary = {}
@export var player_entity: CombatEntity
# 六边形的六个相邻方向坐标偏移量
const NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
]

func _ready() -> void:
	# 启动时，自动将作为子节点的所有挂点录入字典
	for child in get_children():
		if child is HexSlot:
			hex_grid[child.axial_coords] = child


# ==========================================
# 为地块拖拽提供支持的接口
# ==========================================

# 接口：获取距离鼠标最近的挂点（吸附用）
func get_closest_slot(world_pos: Vector2) -> HexSlot:
	var closest_slot: HexSlot = null
	var min_dist_sq = INF
	
	for slot in hex_grid.values():
		var dist_sq = slot.global_position.distance_squared_to(world_pos)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_slot = slot
			
	# 设定吸附阈值（比如 50 像素的平方 2500）
	if min_dist_sq < 2500:
		return closest_slot
	return null

# ==========================================
# 内部辅助方法
# ==========================================

# 获取网格上所有已经放置的地块实体
func _get_all_placed_tiles() -> Array:
	var tiles = []
	for slot in hex_grid.values():
		if not slot.is_empty():
			tiles.append(slot.get_tile())
	return tiles

# 获取某个坐标周围，所有已经放置了地块的相邻地块实体
func _get_occupied_neighbor_tiles(target_coords: Vector2i) -> Array:
	var neighbors = []
	for offset in NEIGHBOR_OFFSETS:
		var check_coord = target_coords + offset
		if hex_grid.has(check_coord):
			var neighbor_slot = hex_grid[check_coord]
			if not neighbor_slot.is_empty():
				neighbors.append(neighbor_slot.get_tile())
	return neighbors

func show_grid_helpers(is_visible: bool) -> void:
	for slot in get_children():
		if slot is HexSlot:
			# 假设你的 HexSlot 下有一个用于显示的 Sprite2D
			slot.set_helper_visible(is_visible)
			
# ==========================================
# 核心逻辑：全局 Buff 计算调度
# (每次放置或删除地块后，调用此函数即可)
# ==========================================
# 当地块发生变动时，一定要调用这个
func recalculate_all_buffs() -> void:
	var actions: Array[ActionData] = []
	var hp_bonus: int = 0
	var ap_bonus: int = 0
	
	# 遍历所有子节点（HexSlot）
	for slot in get_children():
		if slot.has_method("get_tile"): # 确保是槽位节点
			var tile = slot.get_tile()
			if tile:
				# 累加地块提供的属性
				hp_bonus += tile.bonus_max_hp
				ap_bonus += tile.bonus_max_ap
				if tile.granted_action:
					actions.append(tile.granted_action)
	
	# 将统计结果推送给实体
	if player_entity:
		player_entity.update_from_grid(actions, hp_bonus, ap_bonus)
