class_name ActionButton
extends Button

# 绑定的动作数据
var action_data: ActionData
var is_in_queue: bool = false # 标记这个按钮是在“待选池”里，还是在“已选队列”里
var queue_index: int = -1     # 如果在已选队列里，它排第几？

# 自定义信号，向上传递给动作管理器
signal pool_action_clicked(action: ActionData)
signal queue_action_clicked(index: int)

# 初始化方法
func setup(data: ActionData, current_ap: int, cooldown_turns: int, in_queue: bool, q_index: int = -1) -> void:
	action_data = data
	is_in_queue = in_queue
	queue_index = q_index
	
	# --- 表现层更新 ---
	var btn_text = data.action_name
	
	if not is_in_queue:
		# 如果是在下方的待选池中
		btn_text += " (AP: %d)" % data.ap_cost
		if cooldown_turns > 0:
			btn_text += " [冷却中: %d]" % cooldown_turns
			disabled = true # 冷却中禁用
		elif current_ap < data.ap_cost:
			disabled = true # AP不够禁用
		else:
			disabled = false # 可用！
	else:
		# 如果是在上方的已选队列中
		btn_text = "[撤销] " + btn_text
		disabled = false # 队列中的动作永远可以点击（为了撤销）
		
	text = btn_text
	
	# 如果你有图标节点，可以在这里赋值
	# if $IconRect and data.action_icon:
	# 	$IconRect.texture = data.action_icon

# 当按钮被玩家点击时（Godot内置的 pressed 信号连接到这里）
func _on_pressed() -> void:
	if is_in_queue:
		queue_action_clicked.emit(queue_index)
	else:
		pool_action_clicked.emit(action_data)
