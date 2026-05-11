# BeetleWarship.gd
extends Node2D
class_name BeelteWarship
@onready var grid_manager = $BeetleGridManager
@onready var combat_entity = $CombatEntity

func _ready() -> void:
	# 核心连接：网格管理器算完账后，直接告诉实体更新
	# 这样拼装和战斗两个系统就彻底打通了
	grid_manager.player_entity = combat_entity
	# 如果你的网格里已经预设了地块，初始化一次
	grid_manager.recalculate_all_buffs()

# 提供给外部（如 CombatManager）获取实体的接口
func get_entity() -> CombatEntity:
	return combat_entity
