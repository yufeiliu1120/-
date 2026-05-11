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
# 核心部件引用（在编辑器里把对应的节点拖进来）
# ==========================================
@export var player_entity: CombatEntity
@export var enemy_entity: CombatEntity
@export var ui_manager: ActionUIManager
@export var action_resolver: ActionResolver

func _ready() -> void:
	# 【修改这行】：将同时传入玩家和敌人实体
	ui_manager.bind_entities(player_entity, enemy_entity)
	
	ui_manager.turn_submitted.connect(_on_player_turn_submitted)
	
	print("⚔️ 战斗开始！")
	change_state(CombatState.TURN_START)

# ==========================================
# 状态机核心控制逻辑
# ==========================================
func change_state(new_state: CombatState) -> void:
	current_state = new_state
	
	match current_state:
		CombatState.TURN_START:
			_state_turn_start()
		CombatState.ENEMY_THINKING:
			_state_enemy_thinking()
		CombatState.PLAYER_PHASE:
			_state_player_phase()
		CombatState.RESOLUTION:
			_state_resolution()
		CombatState.TURN_END:
			_state_turn_end()

# --- 状态 1：回合开始 ---
func _state_turn_start() -> void:
	print("\n========== 第 新 回 合 ==========")
	# 触发双方战舰的回合重置逻辑（回满AP、冷却-1、清空旧队列）
	player_entity.on_turn_start()
	enemy_entity.on_turn_start()
	
	# 跨回合技能/Buff的数据处理未来可以在这里加上
	
	# 瞬间完成，自动进入下一阶段
	change_state(CombatState.ENEMY_THINKING)

# --- 状态 2：敌人动作计算 ---
func _state_enemy_thinking() -> void:
	print("🤖 敌方 AI 正在思考...")
	
	# 这是一个简单的贪心算法AI模板：只要AP够且有技能不在冷却，就随便塞进队列
	var available_actions = []
	for action in enemy_entity.action_pool:
		if enemy_entity.is_action_available(action):
			available_actions.append(action)
			
	while available_actions.size() > 0 and enemy_entity.current_ap > 0:
		# 随机挑一个能用的动作
		var random_action = available_actions.pick_random()
		if enemy_entity.current_ap >= random_action.ap_cost:
			enemy_entity.use_action(random_action)
		else:
			break # 剩下的AP不够放这个技能了
			
		# 重新检查还有哪些技能可用
		available_actions.clear()
		for action in enemy_entity.action_pool:
			if enemy_entity.is_action_available(action):
				available_actions.append(action)
				
	print("🤖 敌方准备完毕，本回合排布了 %d 个动作。" % enemy_entity.current_action_queue.size())
	
	# 敌人思考完毕，交接给玩家
	change_state(CombatState.PLAYER_PHASE)

# --- 状态 3：玩家回合 ---
func _state_player_phase() -> void:
	print("🎮 等待玩家操作...")
	# 激活 UI，允许玩家点击（可以通过显示/隐藏遮罩，或者启用/禁用整体鼠标拦截来实现）
	ui_manager.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 这个状态不需要自动 change_state。
	# 系统会一直停在这里，直到玩家点击了 UI 上的“结束回合”按钮，触发 _on_player_turn_submitted。

# --- 当玩家点击“结束回合”时触发 ---
func _on_player_turn_submitted(final_queue: Array[ActionData]) -> void:
	if current_state == CombatState.PLAYER_PHASE:
		# 禁用 UI，防止结算时玩家乱点
		ui_manager.mouse_filter = Control.MOUSE_FILTER_STOP
		# 进入结算！
		change_state(CombatState.RESOLUTION)

# --- 状态 4：回合结算 ---
func _state_resolution() -> void:
	# 因为 resolve_turn 内部用了 await 做了动画停顿，所以这里也要加上 await
	await action_resolver.resolve_turn(player_entity, enemy_entity)
	
	# 结算动画播完了，进入回合结束判定
	change_state(CombatState.TURN_END)

# --- 状态 5：回合结束 ---
func _state_turn_end() -> void:
	# 判定双方生死
	if player_entity.current_hp <= 0 and enemy_entity.current_hp <= 0:
		print("💀 同归于尽！")
	elif player_entity.current_hp <= 0:
		print("💀 玩家战败！")
	elif enemy_entity.current_hp <= 0:
		print("🏆 玩家胜利！")
	else:
		print("🔄 双方存活，准备进入下一回合...")
		# 重点：等待一小会儿，再进入下一个回合，手感更好
		await get_tree().create_timer(1.0).timeout
		change_state(CombatState.TURN_START)
