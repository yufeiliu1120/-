extends Node2D
class_name BaseTile
signal tile_successfully_placed(data_id: String)

var grid_manager: BeetleGridManager = null
var current_slot: HexSlot = null
var is_new_from_ui: bool = true
var data_id: String = "" 

@export var granted_action: ActionData
@export var bonus_max_hp: int = 0  
@export var bonus_max_ap: int = 0  

# ==========================================
# 【新增】战斗临时数据（用于接收相邻加成的修改，防止污染原资源）
# ==========================================
var combat_action: ActionData = null
var combat_bonus_hp: int = 0
var combat_bonus_ap: int = 0

func _ready() -> void:
	if grid_manager == null:
		grid_manager = get_tree().current_scene.find_child("BeetleGridManager", true, false)

# 初始化/清除自身的加成（在每次重新计算前第一步调用）
func clear_buffs() -> void:
	combat_bonus_hp = bonus_max_hp
	combat_bonus_ap = bonus_max_ap
	
	if granted_action != null:
		# 1. 复制出独立的肉体
		combat_action = granted_action.duplicate()
		# 2. 【核心修复】：将这个动作与本地块永久绑定！
		combat_action.source_tile = self 
	else:
		combat_action = null
		
func apply_adjacent_buff(neighbors: Array) -> void:
	pass

func apply_global_buff(all_tiles: Array) -> void:
	pass
