class_name ActionData
extends Resource

var source_tile = null

@export var action_name: String = "新动作"
@export var action_icon: Texture2D 
@export_multiline var description: String = ""
@export var ap_cost: int = 1
@export var base_cooldown: int = 0
@export var anim_duration = 1.0
# 【核心重构】：删掉 action_type 枚举和 power_value！
# 增加一个供子类重写的执行函数
# 我们把对方的动作 (target_action) 也传进来，方便做复杂的判定
func execute(user: CombatEntity, target: CombatEntity, target_action: ActionData) -> void:
	push_error("基础 ActionData 的 execute 方法不应被直接调用，请使用子类！")

# 增加一个获取动作意图的函数（用来代替以前的 action_type 检查）
func is_dodging() -> bool:
	return false
