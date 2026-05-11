extends Node2D
class_name BaseTile
signal tile_successfully_placed(data_id: String)
# 核心引用
var grid_manager: BeetleGridManager = null
var current_slot: HexSlot = null
var is_new_from_ui: bool = true
# 数据引用：用于放置失败时，把对应的卡牌退还给背包
var data_id: String = "" 

@export var granted_action: ActionData
@export var bonus_max_hp: int = 0  # 比如装甲地块提供 +20 最大生命
@export var bonus_max_ap: int = 0  # 比如电池地块提供 +1 最大AP
func _ready() -> void:
	# 防御性编程：如果生成时忘了传网格管理器，尝试自动寻找
	if grid_manager == null:
		grid_manager = get_tree().current_scene.find_child("BeetleGridManager", true, false)

# ==========================================
# Buff 接口 (留给具体的地块子类去覆盖/Override)
# ==========================================

# 清除自身的加成（在重新计算前，或被拆除时调用）
func clear_buffs() -> void:
	pass

# 施加相邻加成
# neighbors: 包含周围所有相邻且有地块的 HexSlot 的数组
func apply_adjacent_buff(neighbors: Array) -> void:
	pass

# 施加全局加成
# all_tiles: 包含网格上所有已放置地块的数组
func apply_global_buff(all_tiles: Array) -> void:
	pass
