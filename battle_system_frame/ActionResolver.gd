class_name ActionResolver
extends Node

# 这个信号只在内部使用，当所有人的动画都播完时触发
signal round_visuals_finished

# 记录当前轮次还在播放动画的实体数量
var pending_animations: int = 0

func resolve_turn(player: CombatEntity, enemy: CombatEntity) -> void:
	print("\n=========== 💥 结算阶段开始 💥 ===========")
	
	# 1. 在结算前，先连接双方的动画完成信号
	# 使用 is_connected 检查，防止多回合重复连接导致 Bug
	if not player.action_animation_finished.is_connected(_on_entity_animation_finished):
		player.action_animation_finished.connect(_on_entity_animation_finished)
	if not enemy.action_animation_finished.is_connected(_on_entity_animation_finished):
		enemy.action_animation_finished.connect(_on_entity_animation_finished)
	
	var p_queue = player.current_action_queue
	var e_queue = enemy.current_action_queue
	var max_actions = max(p_queue.size(), e_queue.size())
	
	for i in range(max_actions):
		print("\n--- ⚔️ 动作轮次 %d ---" % (i + 1))
		
		var p_action: ActionData = null
		var e_action: ActionData = null
		if i < p_queue.size(): p_action = p_queue[i]
		if i < e_queue.size(): e_action = e_queue[i]
		
		var p_dodging = (p_action != null and p_action.action_type == ActionData.ActionType.DODGE)
		var e_dodging = (e_action != null and e_action.action_type == ActionData.ActionType.DODGE)
		
		# 2. 重置这一个轮次的动画计数器
		pending_animations = 0
		
		# 3. 结算玩家，并触发动画
		if p_action != null:
			_execute_action(p_action, player, enemy, e_dodging)
			player.start_cooldown(p_action)
			
			pending_animations += 1 # 计数器 +1
			player.play_action_visual(p_action) # 开始播动画（异步执行，不会卡住后续代码）
			
		# 4. 结算敌人，并触发动画
		if e_action != null:
			_execute_action(e_action, enemy, player, p_dodging)
			enemy.start_cooldown(e_action)
			
			pending_animations += 1 # 计数器 +1
			enemy.play_action_visual(e_action)
			
		# 5. 【核心精髓】：如果这回合有人出招了，就死死卡在这里等待！
		if pending_animations > 0:
			await round_visuals_finished
			
		# 动画彻底播完了，检查有没有人死掉
		if player.current_hp <= 0 or enemy.current_hp <= 0:
			print("🚨 战舰被击毁，战斗提前结束！")
			break

	print("=========== 🏁 结算阶段结束 🏁 ===========\n")

# 当任何一个实体（玩家或敌人）播完动画时，都会调用这里
func _on_entity_animation_finished() -> void:
	pending_animations -= 1 # 划掉一个
	
	# 如果计数器归零，说明双方的动画都播完了！
	if pending_animations <= 0:
		round_visuals_finished.emit() # 发出信号，解开上面第 5 步的 await 卡扣！

# --------------------------------------------------
# 下面的 _execute_action 逻辑保持完全不变
# --------------------------------------------------
func _execute_action(action: ActionData, user: CombatEntity, target: CombatEntity, target_is_dodging: bool) -> void:
	match action.action_type:
		ActionData.ActionType.ATTACK: 
			if target_is_dodging:
				print("💨 %s 释放了【%s】，但是被 %s 灵巧地闪避了！" % [user.entity_name, action.action_name, target.entity_name])
			else:
				print("🔥 %s 释放了【%s】，对 %s 造成了 %d 点伤害！" % [user.entity_name, action.action_name, target.entity_name, action.power_value])
				target.take_damage(action.power_value)
		ActionData.ActionType.DODGE: 
			print("🛡️ %s 使用了【%s】，进入防御躲避姿态！" % [user.entity_name, action.action_name])
		ActionData.ActionType.SUPPORT: 
			print("✨ %s 使用了辅助技能【%s】！" % [user.entity_name, action.action_name])
		ActionData.ActionType.BOARDING:
			print("⚓ %s 发起了跳帮动作【%s】！" % [user.entity_name, action.action_name])
