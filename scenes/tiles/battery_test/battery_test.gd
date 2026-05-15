extends BaseTile

func apply_adjacent_buff(neighbors: Array) -> void:
	for neighbor in neighbors:
		# 如果邻居有动作，且这个动作是“臼炮”类（可以用 action_name 或你设定的枚举/标签判断）
		if neighbor.combat_action != null:
			if neighbor.combat_action.action_name == "臼炮射击":
			# 精准地给这个臼炮的临时副本增加伤害！
				neighbor.combat_action.damage += 1
				print("📦 弹药箱起效！相邻的臼炮伤害提升至：", neighbor.combat_action.damage)
