extends Node2D



func _on_assumble_hub_pressed() -> void:
	var player_war_ship = PlayerBlueprintManager.build_ship(load("res://scenes/beetles/beetle_base.tscn"),true)
	player_war_ship.global_position = Vector2(950,550)
	if player_war_ship:
		print("玩家战舰初始化成功")
	else:
		push_error("玩家战舰初始化失败")
	$CanvasLayer/AssumblyHub.start_assembly()


func _on_to_battle_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test.tscn")
