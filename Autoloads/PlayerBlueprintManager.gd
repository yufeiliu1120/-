extends Node

# ==========================================
# 核心数据：当前战局的拼装图纸
# Key: Vector2i (地块的网格坐标)
# Value: String (卡牌/地块的场景路径 data_id)
# ==========================================
var current_blueprint: Dictionary = {}

# ==========================================
# 辅助函数
# ==========================================

# 1. 战局重置/开始拼装时调用，清空上一把的残留
func clear_blueprint() -> void:
	current_blueprint.clear()
	print("🗑️ PlayerBlueprintManager: 战舰蓝图已清空")

# 2. 写入单个地块的信息
func save_tile(coord: Vector2i, data_id: String) -> void:
	current_blueprint[coord] = data_id

# 3. 打印当前蓝图数据（专供你在控制台 Debug 使用）
func print_blueprint() -> void:
	print("📜 当前保存的战舰蓝图：")
	if current_blueprint.is_empty():
		print("  (空)")
	else:
		for coord in current_blueprint:
			print("  📍 坐标 %s -> 📦 %s" % [str(coord), current_blueprint[coord]])
			
# ==========================================
# 4. 自动造船厂（核心装配逻辑）
# ==========================================
func build_ship(base_ship_scene: PackedScene,is_player:bool):
	if base_ship_scene == null:
		push_error("⚠️ 组装失败：未提供战舰基底场景 (PackedScene)！")
		return
		
	# 1. 实例化一个纯净的战舰底盘
	var ship_instance = base_ship_scene.instantiate()
	get_tree().get_first_node_in_group("ShipSlot").add_child(ship_instance)
	# 2. 找到这艘船上的网格管理器
	# 使用 true, false 表示递归向下查找，且不限于本身拥有的节点
	var grid_manager = ship_instance.find_child("BeetleGridManager", true, false)
	if grid_manager == null:
		push_error("⚠️ 组装失败：在提供的基底上找不到 BeetleGridManager！")
		return

# 3. 按图纸精准施工
	for coord in current_blueprint:
		var data_id = current_blueprint[coord]
		var tile_scene = load(data_id) as PackedScene
		
		if tile_scene != null:
			var tile_instance = tile_scene.instantiate().instantiate_tile()
			# 注入地块所需的数据依赖
			tile_instance.data_id = data_id
			tile_instance.grid_manager = grid_manager
			tile_instance.is_new_from_ui = false 
			
			if grid_manager.hex_grid.has(coord):
				var slot = grid_manager.hex_grid[coord]
				
				# 1. 放置地块（此时只是搭建物理层级，_ready 还没触发）
				slot.place_tile(tile_instance)
				
			else:
				push_warning("⚠️ 蓝图警告：图纸要求在 %s 放置地块，但这艘船没有这个槽位！" % str(coord))
		else:
			push_error("⚠️ 蓝图警告：无法加载卡牌资源路径 -> " + data_id)
	ship_instance.grid_manager.recalculate_all_buffs()
	if is_player:
		ship_instance.is_player = true
		ship_instance.add_to_group("PlayerShip")
	return ship_instance
