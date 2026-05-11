extends Node

@onready var player_warship = $BeetleWarship
@onready var enemy_warship = $EnemyWarship # 同样的模板，只是动作池不同
@onready var combat_manager = $CombatManager
@onready var combat_ui = $CanvasLayer/ActionUIManager
@onready var assembly_hub = $CanvasLayer/AssemblyHub

func _ready() -> void:
	# 1. 初始化拼装系统
	# 告诉拼装中枢，地块要往哪艘船上放
	assembly_hub.grid_manager = player_warship.grid_manager
	
	# 2. 初始化战斗 UI
	# 绑定玩家和敌人的实体数据
	combat_ui.bind_entities(
		player_warship.get_entity(), 
		enemy_warship.get_entity()
	)
	
	# 3. 按钮连接
	$CanvasLayer/StartCombatButton.pressed.connect(_on_start_combat_pressed)

func _on_start_combat_pressed() -> void:
	print("进入战斗模式！")
	# 隐藏拼装UI，锁定网格
	assembly_hub.hide()
	
	# 启动回合管理器，开始战斗循环
	combat_manager.change_state(combat_manager.CombatState.TURN_START)
