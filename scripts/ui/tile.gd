extends Button

## Tile — 可拖拽/点击的单字拼块
## 两种状态：在候选池中(可选中) / 已填入槽位(显示在答案槽)

var character: String = ""        # 显示的中文字
var is_placed: bool = false       # 是否已填入答案槽
var tile_index: int = -1           # 在 candidates 数组中的索引
var original_pos: Vector2          # 在候选池中的原始位置（用于回退动画）


func setup(char: String, idx: int) -> void:
	character = char
	tile_index = idx
	text = char
	is_placed = false
	custom_minimum_size = Vector2(72, 72)


func place() -> void:
	"""被填入答案槽"""
	is_placed = true
	disabled = true
	modulate = Color(1, 1, 1, 0.4)


func unplace() -> void:
	"""从答案槽退回候选池"""
	is_placed = false
	disabled = false
	modulate = Color(1, 1, 1, 1.0)


func remove_with_hint() -> void:
	"""提示消除此干扰项"""
	if not is_placed:
		# 播放缩小+淡出动画
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(0.0, 0.0), 0.3)
		tween.tween_property(self, "modulate:a", 0.0, 0.3)
		tween.finished.connect(_on_removed)


func _on_removed() -> void:
	disabled = true
	visible = false
	scale = Vector2(1, 1)
	modulate = Color(1, 1, 1, 1)
