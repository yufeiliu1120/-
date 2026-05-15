extends StateMachine.State

@export var state_name: String = "Dragging"

func enter() -> void:
	actor.z_index = 100 # 保证拖拽时显示在最顶层
	
	# 防御性：尝试寻找网格管理器
	if actor.grid_manager == null:
		var found_manager = get_tree().current_scene.find_child("BeetleGridManager", true, false)
		if found_manager:
			actor.grid_manager = found_manager

	# 如果是从挂点上拿起的，剥离父节点并清除Buff
	if actor.get("current_slot") != null:
		actor.current_slot.remove_tile()
		actor.current_slot = null
		if actor.grid_manager:
			actor.grid_manager.recalculate_all_buffs()

	# 确保它的父节点是网格管理器（或者场景根节点），以便能跟随鼠标自由移动
	if actor.grid_manager != null and actor.get_parent() != actor.grid_manager:
		if actor.get_parent() == null:
			actor.grid_manager.add_child(actor)
		else:
			actor.reparent(actor.grid_manager)

func do(delta: float) -> void:
	# 吸附逻辑保持不变
	if actor.grid_manager == null:
		actor.global_position = actor.get_global_mouse_position()
		return

	var mouse_pos = actor.get_global_mouse_position()
	var target_slot = actor.grid_manager.get_closest_slot(mouse_pos)
	
	if target_slot and target_slot.is_empty():
		actor.global_position = target_slot.global_position
	else:
		actor.global_position = mouse_pos

# 【重要更改】：使用 _unhandled_input 代替 _input，防止和 UI 点击冲突
func _unhandled_input(event: InputEvent) -> void:
	if fsm.current_state != self: return
	
	# 监听【按下】鼠标按钮的操作
	if event is InputEventMouseButton and event.pressed:
		
		# ---------------- 左键逻辑 ----------------
		if event.button_index == MOUSE_BUTTON_LEFT:
			if actor.grid_manager == null:
				return
				
			var target_slot = actor.grid_manager.get_closest_slot(actor.get_global_mouse_position())
			
			if target_slot:
				# 找到了挂点，进一步检查是否为空
				if target_slot.is_empty():
				# ======= 放置成功 =======
					actor.current_slot = target_slot
					target_slot.place_tile(actor)
					actor.grid_manager.recalculate_all_buffs()
				
				# 【核心修改】：只对全新的地块发出信号并扣除UI数量！
					if actor.is_new_from_ui:
						if actor.has_signal("tile_successfully_placed"):
							actor.tile_successfully_placed.emit(actor.data_id)
					# 扣除后，标记为“老地块”，以后在甲虫背上搬家就不会再扣钱了
						actor.is_new_from_ui = false 
					print("地块放置成功")
					state_finished.emit("Placed")
				else:
					# ======= 放置失败：挂点已被占用 =======
					# 按照你的需求：无事发生，地块继续粘在鼠标上
					print("放置失败：该位置已有地块！")
					# 可选：这里以后可以播放一个“滴嘟”的错误提示音
			else:
				# ======= 放置失败：没找到挂点 =======
				# 点在了甲虫外面的空白海域，无事发生
				pass
				
			get_viewport().set_input_as_handled()

		# ---------------- 右键逻辑 ----------------
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# ======= 取消放置 =======
			_cancel_drag()
			get_viewport().set_input_as_handled()

# 取消拖拽：退回背包并销毁实体
func _cancel_drag() -> void:
	if "data_id" in actor and actor.data_id != "":
		# 将数据退还给玩家的全局背包
		PlayerInventoryManager.card_backpack.append(actor.data_id)
		# 因为数量退回去了，最好通知拼装中枢刷新一下UI
		# 如果你有一个全局信号，可以像这样调用：
		# EventBus.emit_signal("inventory_updated") 
		
	actor.queue_free()
