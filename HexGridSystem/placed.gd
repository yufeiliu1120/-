extends StateMachine.State

@export var state_name: String = "Placed"
var allow_to_move:bool
func enter() -> void:
	actor.z_index = 10 # 恢复正常层级

func _input(event: InputEvent) -> void:
	if fsm.current_state != self: return
	
	# 监听【按下】鼠标左键
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not allow_to_move:
			return
		# 检查鼠标是否点在了本块地块上（50像素半径，可根据素材大小修改）
		if actor.global_position.distance_to(actor.get_global_mouse_position()) < 50:
			# 只要发出切换信号，进入 Dragging 状态时，它会自动处理挂点脱离和 Buff 重新计算！
			state_finished.emit("Dragging")
