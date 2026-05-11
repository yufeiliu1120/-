class_name TileCard
extends Control 

@export var tile_scene: PackedScene # 在检查器中，把对应的地块场景(如臼炮.tscn)拖进来

var my_card_path: String = "" # 记录自己的数据路径（由Slot赋予）

# 信号：当自己被点击时，把生成好的地块和自己的路径交出去
signal card_clicked(new_tile: BaseTile, card_path: String)

func instantiate_tile() -> BaseTile:
	if tile_scene != null:
		return tile_scene.instantiate() as BaseTile
	return null

# 核心逻辑：卡牌自己处理点击
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var new_tile = instantiate_tile()
		if new_tile:
			# 发出信号
			card_clicked.emit(new_tile, my_card_path)
			
		# 拦截鼠标事件，防止穿透到下层UI
		accept_event()
