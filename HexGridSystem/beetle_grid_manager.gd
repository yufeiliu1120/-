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
	var all_tiles = _get_all_placed_tiles()
	
	# 1. 【重置阶段】让所有地块准备好干净的副本作战数据
	for tile in all_tiles:
		tile.clear_buffs()
		
	# 2. 【Buff结算阶段】让所有地块发挥自己的相邻/全局效果
	for coords in hex_grid.keys():
		var slot = hex_grid[coords]
		if not slot.is_empty():
			var tile = slot.get_tile()
			
			# 传入真正的邻居地块数组，触发地块自身的逻辑！
			var neighbors = _get_occupied_neighbor_tiles(coords)
			tile.apply_adjacent_buff(neighbors)
			tile.apply_global_buff(all_tiles) # 全局效果也可以紧接着触发
			
	# 3. 【汇总阶段】收集所有地块最终的 combat_xxx 数据
	var total_actions: Array[ActionData] = []
	var total_hp: int = 0
	var total_ap: int = 0
	
	for tile in all_tiles:
		if tile.combat_action != null:
			total_actions.append(tile.combat_action)
		total_hp += tile.combat_bonus_hp
		total_ap += tile.combat_bonus_ap
		
	# 推送给实体（切记 CombatEntity 里直接接收 action_pool = grid_actions 即可，不需要再 duplicate 了）
	if player_entity != null:
		player_entity.update_from_grid(total_actions, total_hp, total_ap)


func get_adjacent_slots(coords: Vector2i) -> Array[HexSlot]:
	var neighbors: Array[HexSlot] = []
	
	# NEIGHBOR_OFFSETS 是你在代码里写好的 6 个方向的偏移量
	for offset in NEIGHBOR_OFFSETS:
		var target_coord = coords + offset
		
		# hex_grid 是你存所有槽位的字典，这行实现了 O(1) 复杂度的瞬间查找！
		if hex_grid.has(target_coord):
			neighbors.append(hex_grid[target_coord])
			
	return neighbors
