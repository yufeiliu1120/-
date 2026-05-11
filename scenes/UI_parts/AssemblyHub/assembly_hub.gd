extends Control

@export var slot_container: VBoxContainer # 指向你用来垂直排列所有Slot的容器
@export var grid_manager: BeetleGridManager # 将场景里的网格管理器拖进来！

const CardSlotScene = preload("res://scenes/UI_parts/AssemblyHub/card_slot.tscn") # 替换为你的Slot场景路径

var card_counts: Dictionary = {} # 记录：{"res://.../MortarCard.tscn": 3}
var active_slots: Dictionary = {} # 记录：{"res://.../MortarCard.tscn": 对应的Slot节点实例}

func _ready() -> void:
	refresh_assembly_ui()

func refresh_assembly_ui() -> void:
	# 1. 清理旧数据和旧UI
	for child in slot_container.get_children():
		child.queue_free()
	card_counts.clear()
	active_slots.clear()
	
	# 2. 从玩家背包全局单例中读取并统计数量
	for path in PlayerInventoryManager.card_backpack:
		card_counts[path] = card_counts.get(path, 0) + 1
		
	# 3. 实例化并配置 Slot
	for path in card_counts:
		var slot = CardSlotScene.instantiate()
		slot_container.add_child(slot)
		slot.setup(path, card_counts[path])
		
		# 监听Slot发出的拖拽请求
		slot.request_drag.connect(_on_slot_request_drag)
		active_slots[path] = slot

# 接收拖拽请求并正式把地块放入世界
func _on_slot_request_drag(new_tile: BaseTile, card_path: String) -> void:
	# 1. 注入数据和依赖
	new_tile.data_id = card_path
	new_tile.grid_manager = grid_manager
	
	# 2. 【核心】添加到最外层的世界场景中，防止被UI限制移动范围
	get_tree().current_scene.add_child(new_tile)
	new_tile.global_position = get_global_mouse_position()
	
	# 3. 监听这个地块被“成功放置”的信号
	new_tile.tile_successfully_placed.connect(_on_tile_placed)
	
	# 4. 强制启动地块的状态机进入拖拽模式（假设你的地块里有StateMachine节点）
	if new_tile.has_node("StateMachine"):
		new_tile.get_node("StateMachine").change_state("Dragging")

# 当地块在网格上真正放置成功时触发
func _on_tile_placed(card_path: String) -> void:
	if card_counts.has(card_path):
		# 1. 字典数量 -1
		card_counts[card_path] -= 1
		
		# 2. 真实背包数据扣减（假设你在 PlayerInventoryManager 里写了这个方法）
		var index = PlayerInventoryManager.card_backpack.find(card_path)
		if index != -1:
			PlayerInventoryManager.card_backpack.remove_at(index)
		
		# 3. 更新UI
		var current_slot = active_slots[card_path]
		if card_counts[card_path] > 0:
			# 如果还有剩余，只更新数字
			current_slot.update_count(card_counts[card_path])
		else:
			# 如果抽干了，销毁这个槽位并清理字典
			current_slot.queue_free()
			active_slots.erase(card_path)
			card_counts.erase(card_path)
