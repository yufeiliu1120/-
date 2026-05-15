extends Node

# ==========================================
# 核心系统引用（请在检查器中拖入对应的节点）
# ==========================================
@export var combat_manager: CombatManager
@export var start_battle_button: Button # 你的“出击”按钮
var test_enemy = preload("res://scenes/beetles/beetle_base.tscn")

func _ready() -> void:
	combat_manager.ui_manager.hide()
	print("🌟 测试场景加载完毕，正在准备流程...")
	# 1. 绑定出击按钮
	if start_battle_button:
		start_battle_button.pressed.connect(_on_start_battle_pressed)
	else:
		push_error("未绑定出击按钮！")
	


# ==========================================
# 流程交接：拼装 -> 战斗
# ==========================================
func _on_start_battle_pressed() -> void:
	print("\n>>> 🚀 玩家点击了出击，正在交接系统！ <<<")
	var enemy = test_enemy.instantiate()
	add_child(enemy)
	var player_war_ship = PlayerBlueprintManager.build_ship(load("res://scenes/beetles/beetle_base.tscn"),true)
	player_war_ship.global_position = Vector2(950,550)
	
	if player_war_ship:
		print("玩家战舰初始化成功")
	else:
		push_error("玩家战舰初始化失败")
	# 1. 隐藏拼装阶段的 UI
	if start_battle_button:
		start_battle_button.hide()
		
	# 3. 正式把控制权交给战斗系统！
	if combat_manager:
		combat_manager.start_battle()
		combat_manager.ui_manager.show()
		
