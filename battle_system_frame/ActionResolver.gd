class_name ActionResolver
extends Node

# 这个信号只在内部使用，当所有人的动画都播完时触发
signal round_visuals_finished

# 记录当前轮次还在播放动画的实体数量
var pending_animations: int = 0

func resolve_turn(player: CombatEntity, enemy: CombatEntity) -> void:
	print("\n=========== 💥 结算阶段开始 💥 ===========")
	
	# 1. 在结算前，先连接双方的动画完成信号
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
		
		# 重置这一个轮次的动画计数器
		pending_animations = 0
		
		# ==========================================
		# 【核心重构：多态执行】
		# 结算器不再关心动作类型，直接让动作资源“自己去执行自己的逻辑”
		# 并且把对方出的招 (e_action / p_action) 传进去作为参考
		# ==========================================
		
		# 2. 结算玩家的动作
		if p_action != null:
			p_action.execute(player, enemy, e_action)
			player.start_cooldown(p_action)
			
			pending_animations += 1
			player.play_action_visual(p_action)
			
		# 3. 结算敌人的动作
		if e_action != null:
			e_action.execute(enemy, player, p_action)
			enemy.start_cooldown(e_action)
			
			pending_animations += 1
			enemy.play_action_visual(e_action)
			
		# ==========================================
		
		# 4. 如果这回合有人出招了，死死卡在这里等待双方动画播完
		if pending_animations > 0:
			await round_visuals_finished
			
		# 5. 动画彻底播完了，检查有没有人死掉
		if player.current_hp <= 0 or enemy.current_hp <= 0:
			print("🚨 战舰被击毁，战斗提前结束！")
			break

	print("=========== 🏁 结算阶段结束 🏁 ===========\n")

# 当任何一个实体（玩家或敌人）播完动画时，都会调用这里
func _on_entity_animation_finished() -> void:
	pending_animations -= 1 
	
	# 如果计数器归零，说明双方的动画都播完了
	if pending_animations <= 0:
		round_visuals_finished.emit() # 发出信号，解开上面的 await 卡扣！
