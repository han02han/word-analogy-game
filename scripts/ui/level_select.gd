extends Control

## LevelSelect — 关卡选择画面
## 显示关卡网格，支持选中+进入

const LEVELS_PER_ROW := 7

@onready var grid: GridContainer = $LevelGrid
@onready var play_btn: Button = $PlayBtn
@onready var page_label: Label = $TopBar/PageLabel

var selected_level: int = -1


func _ready() -> void:
	_build_grid()
	_update_page_label()


func _build_grid() -> void:
	# 清空旧节点
	for child in grid.get_children():
		child.queue_free()

	var total := LevelData.get_level_count()
	for i in range(1, total + 1):
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(64, 64)
		btn.theme_type_variation = "LevelButton"

		if GameManager.is_completed(i):
			btn.text += "\n✅"
		elif not GameManager.is_unlocked(i):
			btn.text += "\n🔒"
			btn.disabled = true

		btn.pressed.connect(_on_level_btn_pressed.bind(i))
		grid.add_child(btn)

	# 默认选中当前可玩的第一个
	for i in range(1, total + 1):
		if GameManager.is_unlocked(i) and not GameManager.is_completed(i):
			_select_level(i)
			break


func _on_level_btn_pressed(level_id: int) -> void:
	if GameManager.is_unlocked(level_id):
		_select_level(level_id)


func _select_level(level_id: int) -> void:
	selected_level = level_id
	play_btn.disabled = false
	play_btn.text = "进入第 %d 关" % level_id


func _on_play_pressed() -> void:
	if selected_level > 0:
		GameManager.current_level = selected_level
		get_tree().change_scene_to_file("res://scenes/level_play.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _update_page_label() -> void:
	var total := LevelData.get_level_count()
	page_label.text = "共 %d 关  已通关 %d 关" % [total, GameManager.completed_levels.size()]
