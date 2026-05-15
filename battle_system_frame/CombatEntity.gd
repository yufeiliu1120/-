class_name CombatEntity
extends Node2D

# ==========================================
# 基础属性
# ==========================================
@export var entity_name: String = "甲虫战舰"
@export var max_hp: int = 100
var current_hp: int

@export var max_ap: int = 3
var current_ap: int

# 裸机基础属性
@export var base_max_hp: int = 50
@export var base_max_ap: int = 2

# ==========================================
# 动作相关
# ==========================================
var action_pool: Array[ActionData] = []
var cooldown_tracker: Dictionary = {}
var current_action_queue: Array[ActionData] = []
@export var inherent_actions: Array[ActionData] = []
var _runtime_inherent_actions: Array[ActionData] = []
# 信号
signal stats_changed
signal died
signal action_animation_finished

func _ready() -> void:
	current_hp = max_hp
	current_ap = max_ap
	
	# 核心步骤：将编辑器配好的自带动作克隆一份，防止多个同类敌人共享资源
	for action in inherent_actions:
		var cloned_action = action.duplicate()
		# 对于自带动作，因为没有地块，source_tile 默认为 null 即可，或者你也可以将其绑定为实体自己
		_runtime_inherent_actions.append(cloned_action) 
		
	# 初始状态下（如果还没有被网格更新），动作池里只有底盘自带动作
	action_pool = _runtime_inherent_actions.duplicate()
	
	_initialize_cooldowns()

func _initialize_cooldowns() -> void:
	for action in action_pool:
		cooldown_tracker[action] = 0

# ==========================================
# 回合逻辑与动作校验
# ==========================================
func on_turn_start() -> void:
	current_ap = max_ap
	for action in cooldown_tracker.keys():
		if cooldown_tracker[action] > 0:
			cooldown_tracker[action] -= 1
	current_action_queue.clear()
	stats_changed.emit()

func is_action_available(action: ActionData) -> bool:
	var not_in_cooldown = cooldown_tracker.get(action, 0) == 0
	var has_enough_ap = current_ap >= action.ap_cost
	var not_already_queued = not current_action_queue.has(action) 
	return not_in_cooldown and has_enough_ap and not_already_queued

func use_action(action: ActionData) -> void:
	if is_action_available(action):
		current_ap -= action.ap_cost
		current_action_queue.append(action)
		stats_changed.emit()

func cancel_action(index: int) -> void:
	if index < current_action_queue.size():
		var action = current_action_queue[index]
		current_ap += action.ap_cost
		current_action_queue.remove_at(index)
		stats_changed.emit()

func start_cooldown(action: ActionData) -> void:
	if action.base_cooldown > 0:
		cooldown_tracker[action] = action.base_cooldown + 1
	else:
		cooldown_tracker[action] = 0

# ==========================================
# 战斗反馈与表现接口
# ==========================================
func take_damage(amount: int) -> void:
	current_hp = clampi(current_hp - amount, 0, max_hp)
	stats_changed.emit()
	
	if current_hp <= 0:
		died.emit()
		print(entity_name, " 被击沉了！")

# 【核心修改区：多态动画处理】
func play_action_visual(action: ActionData) -> void:
	# 默认的保底动画等待时间
	var anim_time: float = 1.0
	
	# 【动态属性读取】：如果你的子类里（比如 AttackAction.gd）定义了特定的动画时间，
	# 实体会自动读取那个时间！彻底解耦！
	if "anim_duration" in action:
		anim_time = action.get("anim_duration")
		
	# 以后如果接了真正的动画系统，可以直接读取名字：
	# if "anim_name" in action:
	#     $AnimationPlayer.play(action.get("anim_name"))
	#     await $AnimationPlayer.animation_finished
	# else:
	
	await get_tree().create_timer(anim_time).timeout
	
	# 动画播完后发信号
	action_animation_finished.emit()

# ==========================================
# 与地块系统的对接接口
# ==========================================
func update_from_grid(grid_actions: Array[ActionData], bonus_hp: int, bonus_ap: int) -> void:
	max_hp = base_max_hp + bonus_hp
	max_ap = base_max_ap + bonus_ap
	current_hp = min(current_hp, max_hp)
	current_ap = max_ap 
	
	# 【完全按照你的思路】：直接用“底盘动作”加上“地块动作”
	var new_pool: Array[ActionData] = []
	new_pool.append_array(_runtime_inherent_actions) 
	new_pool.append_array(grid_actions)     
	action_pool = new_pool
	_initialize_cooldowns()
	stats_changed.emit()
