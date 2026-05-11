class_name ActionData
extends Resource

var source_tile = null
# ==========================================
# 定义动作的类型枚举（极其重要）
# 以后结算器就是靠这个枚举来判断动作克制关系的（比如闪避躲避攻击）
# ==========================================
enum ActionType {
	ATTACK,     # 攻击类（如：加农炮、臼炮）
	DODGE,      # 闪避类（如：潜水锚）
	SUPPORT,    # 辅助类（如：高能电池、治疗）
	BOARDING    # 跳帮类（如：钩锁）
}

# ==========================================
# 表现层数据 (UI 显示用)
# ==========================================
@export var action_name: String = "新动作"
@export var action_icon: Texture2D # 动作的图标
@export_multiline var description: String = "这里填写动作的介绍文字..."

# ==========================================
# 机制层数据 (系统逻辑用)
# ==========================================
@export var action_type: ActionType = ActionType.ATTACK
@export var ap_cost: int = 1       # 消耗的 AP 值
@export var base_cooldown: int = 0 # 基础冷却回合数（0代表没有冷却，每回合都能用）

# ==========================================
# 数值层数据 (结算器计算用)
# ==========================================
# 这是一个通用数值。
# 如果是攻击，它代表伤害值；如果是治疗，它代表回血量；如果是提供护甲，就是护甲值。
@export var power_value: int = 0 

# 可选：如果有些技能带有一些特殊标签，可以用数组存起来方便后续扩展
# 比如：["ignore_dodge"] (无法被闪避的攻击)
@export var special_tags: Array[String] = []
