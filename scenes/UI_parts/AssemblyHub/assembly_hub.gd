extends Control

@export var slot_container: VBoxContainer # 指向你用来垂直排列所有Slot的容器
var grid_manager: BeetleGridManager # 将场景里的网格管理器拖进来！
@export var finish_button: Button
const CardSlotScene = preload("res://scenes/UI_parts/AssemblyHub/card_slot.tscn") # 替换为你的Slot场景路径
signal assembly_finished
var card_counts: Dictionary = {} # 记录：{"res://.../MortarCard.tscn": 3}
var active_slots: Dictionary = {} # 记录：{"res://.../MortarCard.tscn": 对应的Slot节点实例}

func _ready() -> void:
	# 【核心修改】：不再自动刷新 UI，等待外部总控脚本手动调用
	if finish_button:
		finish_button.pressed.connect(_on_finish_button_pressed)
	hide()
# ==========================================
# 【新增】：手动启动拼装系统的入口
# ==========================================
func start_assembly() -> void:
	#寻找玩家网格管理器节点
	print("🔧 AssemblyHub: 正在初始化拼装界面...")
	grid_manager = get_tree().get_first_node_in_group("PlayerShip").grid_manager
	if grid_manager:
		print("找到玩家网格管理器")
	else:
		push_error("玩家战舰网格管理器未发现")
	show() # 确保界面是显示状态
	refresh_assembly_ui()
	print("✅ 拼装界面就绪，等待玩家操作。")

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
func _on_tile_placed(data_id: String) -> void:
	print("地块放置成功，从背包中扣除: ", data_id)
	# 从背包中移除
	if PlayerInventoryManager.card_backpack.has(data_id):
		PlayerInventoryManager.card_backpack.erase(data_id)
	refresh_assembly_ui()

# 当地块被玩家从网格上拆除（退回）时调用
func _on_tile_removed(data_id: String) -> void:
	print("地块被拆除，退回背包: ", data_id)
	PlayerInventoryManager.card_backpack.append(data_id)
	refresh_assembly_ui()
	
	
func _on_finish_button_pressed() -> void:
	print("💾 玩家点击了完成拼装，正在打包图纸...")
	
	# 1. 呼叫快递驿站，清空上一把的旧图纸
	PlayerBlueprintManager.clear_blueprint()
	
	# 2. 遍历网格管理器中的所有槽位
	for coord in grid_manager.hex_grid:
		var slot = grid_manager.hex_grid[coord]
		
		# 如果槽位里有东西
		if not slot.is_empty():
			var tile = slot.get_tile()
			# 确保地块身上有我们要的 data_id（卡牌场景路径）
			if "data_id" in tile and tile.data_id != "":
				# 写入单例！
				PlayerBlueprintManager.save_tile(coord, tile.data_id)
			else:
				push_warning("⚠️ 警告：位于 %s 的地块缺少 data_id，无法保存！" % str(coord))
	
	# 3. 打印出来确认一下数据对不对
	PlayerBlueprintManager.print_blueprint()
	
	# 4. 发出交接信号，让外面的总控场景知道可以开始战斗（或者切换场景）了
	assembly_finished.emit()
