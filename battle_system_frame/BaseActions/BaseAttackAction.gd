class_name AttackAction
extends ActionData
#基础攻击动作
@export var damage: int = 10
@export var ignore_dodge: bool = false # 轻松实现“无法闪避”的新特性！

func execute(user: CombatEntity, target: CombatEntity, target_action: ActionData) -> void:
	# 检查对方是不是在闪避
	var target_dodged = target_action != null and target_action.is_dodging()
	
	if target_dodged and not ignore_dodge:
		print("💨 %s 释放了【%s】，但是被 %s 闪避了！" % [user.entity_name, action_name, target.entity_name])
	else:
		print("🔥 %s 释放了【%s】，造成了 %d 点伤害！" % [user.entity_name, action_name, damage])
		target.take_damage(damage)
		
	if source_tile != null and source_tile.has_method("play_fire_anim"):
		source_tile.play_fire_anim()
