class_name CombatManager
extends Node

# 战斗的五个核心状态
enum CombatState {
	TURN_START,      # 回合开始
	ENEMY_THINKING,  # 敌人思考
	PLAYER_PHASE,    # 玩家回合
	RESOLUTION,      # 回合结算
	TURN_END         # 回合结束
}

var current_state: CombatState = CombatState.TURN_START

# ==========================================
# 核心部件引用
# ==========================================
var player_entity: CombatEntity
var enemy_entity: CombatEntity

@export var ui_manager: ActionUIManager
@export var action_resolver: ActionResolver

signal battle_ended

# ==========================================
# 【核心修改】：手动启动战斗的入口
# ==========================================
func start_battle() -> void:
	print("🚀 CombatManager: 正在手动启动战斗...")
	
	# 1. 自动寻找并初始化战斗实体
	_initialize_battle_entities()
	
	# 2. 验证实体是否找全
	if player_entity == null or enemy_entity == null:
		push_error("错误：CombatManager 无法在场景中找到完整的玩家或敌人战舰！")
		return

	# 3. 绑定 UI 和玩家/敌人实体
	# 确保此时 CombatEntity 的 action_pool 已经由网格系统填充完毕
	ui_manager.bind_entities(player_entity, enemy_entity)
	
	# 防止重复连接信号
	if not ui_manager.turn_submitted.is_connected(_on_player_turn_submitted):
		ui_manager.turn_submitted.connect(_on_player_turn_submitted)
	
	print("⚔️ 战斗系统就绪，正式开始第一回合！")
	change_state(CombatState.TURN_START)

# ==========================================
# 动态获取实体的逻辑
# ==========================================
func _initialize_battle_entities() -> void:
	var all_ships = get_tree().get_nodes_in_group("Ships")

	for ship in all_ships:
		if ship.get("is_player") == true:
			player_entity = ship.get_node("CombatEntity") 
			print("✅ 已定位玩家战舰实体: ", ship.name)
		else:
			enemy_entity = ship.get_node("CombatEntity")
			print("✅ 已定位敌方战舰实体: ", ship.name)

# ==========================================
# 状态机核心控制逻辑 (保持不变)
# ==========================================
func change_state(new_state: CombatState) -> void:
	current_state = new_state
	match current_state:
		CombatState.TURN_START: _state_turn_start()
		CombatState.ENEMY_THINKING: _state_enemy_thinking()
		CombatState.PLAYER_PHASE: _state_player_phase()
		CombatState.RESOLUTION: _state_resolution()
		CombatState.TURN_END: _state_turn_end()

func _state_turn_start() -> void:
	print("\n========== 第 新 回 合 ==========")
	player_entity.on_turn_start()
	enemy_entity.on_turn_start()
	change_state(CombatState.ENEMY_THINKING)

func _state_enemy_thinking() -> void:
	print("🤖 敌方 AI 正在思考...")
	var available_actions = []
	for action in enemy_entity.action_pool:
		if enemy_entity.is_action_available(action):
			available_actions.append(action)
			
	while available_actions.size() > 0 and enemy_entity.current_ap > 0:
		var random_action = available_actions.pick_random()
		if enemy_entity.current_ap >= random_action.ap_cost:
			enemy_entity.use_action(random_action)
		else:
			break
		available_actions.clear()
		for action in enemy_entity.action_pool:
			if enemy_entity.is_action_available(action):
				available_actions.append(action)
				
	change_state(CombatState.PLAYER_PHASE)

func _state_player_phase() -> void:
	print("🎮 等待玩家操作...")
	ui_manager.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_player_turn_submitted(final_queue: Array[ActionData]) -> void:
	if current_state == CombatState.PLAYER_PHASE:
		ui_manager.mouse_filter = Control.MOUSE_FILTER_STOP
		change_state(CombatState.RESOLUTION)

func _state_resolution() -> void:
	await action_resolver.resolve_turn(player_entity, enemy_entity)
	change_state(CombatState.TURN_END)

func _state_turn_end() -> void:
	if player_entity.current_hp <= 0 or enemy_entity.current_hp <= 0:
		_handle_battle_end()
	else:
		await get_tree().create_timer(1.0).timeout
		change_state(CombatState.TURN_START)

func _handle_battle_end() -> void:
	if player_entity.current_hp <= 0 and enemy_entity.current_hp <= 0:
		print("💀 同归于尽！")
	elif player_entity.current_hp <= 0:
		print("💀 玩家战败！")
	else:
		print("🏆 玩家胜利！")
	battle_ended.emit()
