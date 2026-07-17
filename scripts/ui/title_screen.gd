extends Control

## TitleScreen — 标题画面
## 开始游戏 / 继续游戏 / 设置 / 退出

@onready var continue_btn: Button = $VBoxContainer/ContinueBtn


func _ready() -> void:
	continue_btn.visible = SaveSystem.save_exists()


func _on_start_pressed() -> void:
	# 新游戏：从第1关开始
	GameManager.current_level = 1
	get_tree().change_scene_to_file("res://scenes/level_play.tscn")


func _on_continue_pressed() -> void:
	# 继续游戏：跳到最后未完成的关卡
	var next_level := GameManager.unlocked_count
	# 找到第一个未完成的
	var total := LevelData.get_level_count()
	for i in range(1, total + 1):
		if not GameManager.is_completed(i) and GameManager.is_unlocked(i):
			next_level = i
			break
	GameManager.current_level = next_level
	get_tree().change_scene_to_file("res://scenes/level_play.tscn")


func _on_level_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
