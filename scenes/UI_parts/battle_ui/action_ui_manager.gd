class_name ActionUIManager
extends Control

# --- 预加载组件 ---
# 在检查器中，把你做好的 ActionButton.tscn 拖到这里！
@export var action_button_scene: PackedScene 

# --- UI 节点引用 ---
@onready var ap_label: Label = $APLabel
@onready var timeline_container: HBoxContainer = $TimelineContainer # 时间轴容器
@onready var pool_container: Container = $PoolContainer             # 待选动作池
@onready var submit_button: Button = $SubmitButton                  # 结束回合按钮

# --- 数据引用 ---
var player_entity: CombatEntity
var enemy_entity: CombatEntity

# --- 信号 ---
# 提交回合信号，把最终的动作序列发给战斗管理器/结算器
signal turn_submitted(final_queue: Array[ActionData])

func _ready() -> void:
	submit_button.pressed.connect(_on_submit_pressed)

# ==========================================
# 核心接口：绑定双方实体
# ==========================================
func bind_entities(p_entity: CombatEntity, e_entity: CombatEntity) -> void:
	# 断开旧的连接（防止重新绑定时重复触发）
	if player_entity and player_entity.stats_changed.is_connected(refresh_timeline_ui):
		player_entity.stats_changed.disconnect(refresh_timeline_ui)
	if enemy_entity and enemy_entity.stats_changed.is_connected(refresh_timeline_ui):
		enemy_entity.stats_changed.disconnect(refresh_timeline_ui)
		
	player_entity = p_entity
	enemy_entity = e_entity
	
	# 监听双方战舰的数据变化（任何一方改变队列或AP，都会刷新整条时间轴）
	player_entity.stats_changed.connect(refresh_timeline_ui)
	enemy_entity.stats_changed.connect(refresh_timeline_ui)
	
	# 绑定后立即刷新一次UI
	refresh_timeline_ui()

# ==========================================
# UI 刷新：生成时间轴和动作池
# ==========================================
func refresh_timeline_ui() -> void:
	if player_entity == null or enemy_entity == null: return
	
	# 1. 刷新基础信息
	ap_label.text = "当前 AP: %d / %d" % [player_entity.current_ap, player_entity.max_ap]
	# 如果玩家没选任何动作，就禁用提交按钮（按需保留）
	submit_button.disabled = player_entity.current_action_queue.is_empty()
	
	# 2. 清理旧 UI
	for child in timeline_container.get_children(): 
		child.queue_free()
	for child in pool_container.get_children(): 
		child.queue_free()
		
	# 3. 提取双方队列
	var p_queue = player_entity.current_action_queue
	var e_queue = enemy_entity.current_action_queue
	
	# 决定时间轴显示多少列（取双方最大AP值，或者固定为3列/5列均可）
	var display_columns = max(player_entity.max_ap, enemy_entity.max_ap)
	
	# 4. 逐列生成时间轴 (上下对齐的队列)
	for i in range(display_columns):
		# 新建一列 VBoxContainer
		var col_vbox = VBoxContainer.new()
		col_vbox.add_theme_constant_override("separation", 15) # 设置敌我按钮的上下间距
		timeline_container.add_child(col_vbox)
		
		# ---- 顶层：敌方动作 ----
		if i < e_queue.size():
			var e_btn = action_button_scene.instantiate() as ActionButton
			col_vbox.add_child(e_btn)
			e_btn.setup(e_queue[i], 999, 0, true, i) # 敌方动作只做展示，AP传999
			e_btn.text = "⚠️ " + e_queue[i].action_name
			e_btn.modulate = Color(1, 0.5, 0.5) # 染成红色提示危险
			e_btn.disabled = true # 禁用交互
		else:
			col_vbox.add_child(_create_spacer()) # 敌人没动作，塞入透明垫片
			
		# ---- 底层：玩家动作 ----
		if i < p_queue.size():
			var p_btn = action_button_scene.instantiate() as ActionButton
			col_vbox.add_child(p_btn)
			p_btn.setup(p_queue[i], player_entity.current_ap, 0, true, i)
			p_btn.queue_action_clicked.connect(_on_queue_action_canceled)
		else:
			col_vbox.add_child(_create_spacer()) # 玩家没动作，塞入透明垫片

	# 5. 生成下方的【玩家待选动作池】
	for action in player_entity.action_pool:
		var btn = action_button_scene.instantiate() as ActionButton
		pool_container.add_child(btn)
		
		# 获取该技能的剩余冷却回合数
		var cd = player_entity.cooldown_tracker.get(action, 0)
		btn.setup(action, player_entity.current_ap, cd, false)
		
		# 【新增表现层逻辑】：如果这个动作已经在队列里了，禁用按钮并改名
		if player_entity.current_action_queue.has(action):
			btn.disabled = true
			btn.text += " (已选)"
			
		btn.pool_action_clicked.connect(_on_pool_action_selected)

# ==========================================
# 辅助函数：生成空白垫片
# ==========================================
func _create_spacer() -> Control:
	var spacer = Control.new()
	# 【注意】：请根据你实际的 ActionButton 大小调整这两个数值！
	# 如果不设置，VBox 会把它压成 0 像素高，导致对不齐
	spacer.custom_minimum_size = Vector2(100, 40) 
	return spacer

# ==========================================
# 交互逻辑响应
# ==========================================

# 玩家点击了待选池的动作（添加到队列）
func _on_pool_action_selected(action: ActionData) -> void:
	# CombatEntity 的 use_action 方法会自动校验 AP，扣除 AP 并加入队列
	# 成功后它会发出 stats_changed 信号，从而自动触发上方的 refresh_timeline_ui
	player_entity.use_action(action)

# 玩家点击了时间轴上自己的动作（撤销反悔）
func _on_queue_action_canceled(index: int) -> void:
	# CombatEntity 的 cancel_action 方法会返还 AP 并移出队列
	# 同样会自动触发 refresh_timeline_ui
	player_entity.cancel_action(index)

# 玩家点击了“结束回合”按钮
func _on_submit_pressed() -> void:
	print("玩家点击了结束回合，提交动作数：", player_entity.current_action_queue.size())
	# 使用 duplicate() 防止后续结算时队列引用被意外修改
	turn_submitted.emit(player_entity.current_action_queue.duplicate())
