class_name CombatEntity
extends Node2D

# --- 基础属性 ---
@export var entity_name: String = "甲虫战舰"
@export var max_hp: int = 10
var current_hp: int

@export var max_ap: int = 3
var current_ap: int

@export var base_max_hp: int = 50
@export var base_max_ap: int = 2
# --- 动作相关 ---
# 动作池：存放 ActionData 资源
var action_pool: Array[ActionData] = []
# 冷却追踪：键为 ActionData，值为当前剩余冷却回合数
var cooldown_tracker: Dictionary = {}
# 当前回合排布的动作队列
var current_action_queue: Array[ActionData] = []

# 信号：当属性变化时通知 UI 刷新
signal stats_changed
signal died
signal action_animation_finished

func _ready() -> void:
	current_hp = max_hp
	current_ap = max_ap
	
	# 【核心修复】：为每一个动作资源生成独一无二的副本
	# 这样即使玩家带了两个“臼炮”，它们在系统里也是两个互不干扰的独立对象
	var unique_pool: Array[ActionData] = []
	for action in action_pool:
		# duplicate() 会在内存中克隆出一个全新的对象
		unique_pool.append(action.duplicate()) 
		
	# 用全新的独立动作池替换原本的动作池
	action_pool = unique_pool
	
	_initialize_cooldowns()

# 初始化所有动作的冷却状态为 0
func _initialize_cooldowns() -> void:
	for action in action_pool:
		cooldown_tracker[action] = 0

# ==========================================
# 回合逻辑接口
# ==========================================

# 回合开始时的重置逻辑
func on_turn_start() -> void:
	# 1. 重置 AP
	current_ap = max_ap
	
	# 2. 减少所有动作的冷却时间
	for action in cooldown_tracker.keys():
		if cooldown_tracker[action] > 0:
			cooldown_tracker[action] -= 1
	
	# 3. 清空上一回合的动作队列
	current_action_queue.clear()
	
	stats_changed.emit()
	print(entity_name, " 回合开始：AP 已重置，冷却已更新")

# 检查某个动作是否可用
func is_action_available(action: ActionData) -> bool:
	# 条件1：不在冷却中
	var not_in_cooldown = cooldown_tracker.get(action, 0) == 0
	# 条件2：AP 足够
	var has_enough_ap = current_ap >= action.ap_cost
	# 条件3：【新增】不在当前回合的动作队列中
	var not_already_queued = not current_action_queue.has(action) 
	
	return not_in_cooldown and has_enough_ap and not_already_queued

# 使用动作（排入队列时调用）
func use_action(action: ActionData) -> void:
	if is_action_available(action):
		current_ap -= action.ap_cost
		current_action_queue.append(action)
		stats_changed.emit()

# 撤销动作（从队列移除时调用）
func cancel_action(index: int) -> void:
	if index < current_action_queue.size():
		var action = current_action_queue[index]
		current_ap += action.ap_cost
		current_action_queue.remove_at(index)
		stats_changed.emit()

# 正式进入冷却（在结算阶段动作触发时调用）
func start_cooldown(action: ActionData) -> void:
	# 核心修正：+1 是为了抵消“下回合开始时立刻触发的 -1”
	if action.base_cooldown > 0:
		cooldown_tracker[action] = action.base_cooldown + 1
	else:
		# 如果 base_cooldown 是 0，代表每回合都能用，不需要进入冷却追踪
		cooldown_tracker[action] = 0
# ==========================================
# 战斗反馈接口
# ==========================================

func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)
	stats_changed.emit()
	
	if current_hp <= 0:
		died.emit()
		print(entity_name, " 被击沉了！")
		
func play_action_visual(action: ActionData) -> void:
	# 以后这里会替换成： $AnimationPlayer.play(action.anim_name) 或者 await tween.finished
	
	# 目前我们用不同的等待时间，来模拟不同长度的动画，方便你测试效果
	var anim_time = 1.0
	if action.action_type == ActionData.ActionType.ATTACK:
		anim_time = 1.5 # 攻击动画比较重，设为 1.5 秒
	elif action.action_type == ActionData.ActionType.DODGE:
		anim_time = 0.5 # 闪避动画很灵敏，设为 0.5 秒
		
	await get_tree().create_timer(anim_time).timeout
	
	# 动画播完后，告诉外界“我播完了！”
	action_animation_finished.emit()
	
func update_from_grid(grid_actions: Array[ActionData], bonus_hp: int, bonus_ap: int) -> void:
	# 1. 重新计算最大属性
	max_hp = base_max_hp + bonus_hp
	max_ap = base_max_ap + bonus_ap
	
	# 如果当前血量超出了新的最大血量（比如拆了装甲），则扣除多余血量
	current_hp = min(current_hp, max_hp)
	# 如果是在非战斗/回合初始阶段，AP也跟着上限走
	current_ap = max_ap 
	
	# 2. 重新洗牌动作池！
	# 注意：这里运用了我们之前讲过的 duplicate() 机制，生成全新的独立动作！
	var new_action_pool: Array[ActionData] = []
	for action in grid_actions:
		if action != null:
			action.duplicate()
			new_action_pool.append(action.duplicate())
			
	action_pool = new_action_pool
	_initialize_cooldowns() # 重置冷却字典
	
	# 3. 发出信号，通知 UI 刷新！
	stats_changed.emit()
	print("战舰属性已更新！最大HP: %d, 最大AP: %d, 获得动作数: %d" % [max_hp, max_ap, action_pool.size()])
