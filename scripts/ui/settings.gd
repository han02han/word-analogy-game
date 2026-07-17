extends Control

## Settings — 设置画面
## 音量调节、重置存档、返回标题

@onready var master_slider: HSlider = $VBoxContainer/MasterSlider
@onready var reset_btn: Button = $VBoxContainer/ResetBtn


func _ready() -> void:
	# 读取当前音量
	var bus_idx := AudioServer.get_bus_index("Master")
	var volume_db := AudioServer.get_bus_volume_db(bus_idx)
	master_slider.value = db_to_linear(volume_db) * 100.0


func _on_master_slider_value_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	var volume_db := linear_to_db(value / 100.0)
	AudioServer.set_bus_volume_db(bus_idx, volume_db)


func _on_reset_pressed() -> void:
	# 确认对话框
	var confirm := ConfirmationDialog.new()
	confirm.title = "确认重置"
	confirm.dialog_text = "确定要清除所有进度吗？此操作不可撤销。"
	confirm.confirmed.connect(_do_reset)
	add_child(confirm)
	confirm.popup_centered()


func _do_reset() -> void:
	GameManager.reset_progress()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
