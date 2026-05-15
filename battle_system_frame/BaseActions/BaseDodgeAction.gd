class_name DodgeAction
extends ActionData

func is_dodging() -> bool:
	return true

func execute(user: CombatEntity, target: CombatEntity, target_action: ActionData) -> void:
	print("🛡️ %s 使用了【%s】，进入防御躲避姿态！" % [user.entity_name, action_name])
	# 如果以后有“完美闪避回血”的机制，直接写在这里！
