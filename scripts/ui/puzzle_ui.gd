extends Control

## PuzzleUI — 游戏主界面控制器
## 管理拼字盘、答案槽、提示、插图、过关判定

# 常量
const MAX_HINTS := 3

# 节点引用
@onready var puzzle_label: Label = $PuzzleLabel
@onready var candidates_container: GridContainer = $CandidatesContainer
@onready var slots_container: HBoxContainer = $AnswerSection/SlotsContainer
@onready var confirm_btn: Button = $ConfirmBtn
@onready var hint_btn: Button = $TopBar/HintBtn
@onready var hint_label: Label = $TopBar/HintLabel
@onready var level_title: Label = $TopBar/LevelTitle
@onready var illustration: TextureRect = $IllustrationArea/IllustrationBefore
@onready var illustration_after: TextureRect = $IllustrationArea/IllustrationAfter

# 状态
var level_data: Dictionary = {}
var answer_slots: Array[Button] = []
var candidate_tiles: Array = []           # Array[Tile]
var slot_filled: Array[bool] = []          # 每个槽是否已填
var hint_count: int = MAX_HINTS
var hint_remove_queue: Array[String] = []  # 待移除的干扰字队列
var hint_index: int = 0


func _ready() -> void:
	load_level(GameManager.current_level)


func load_level(level_id: int) -> void:
	level_data = LevelData.get_level(level_id)
	if level_data.is_empty():
		push_error("PuzzleUI: 无法加载关卡 ", level_id)
		return

	# 重置状态
	_reset_state()

	# 设置 UI
	level_title.text = "第 %d 关" % level_id
	puzzle_label.text = level_data["puzzle"]
	hint_count = MAX_HINTS
	hint_label.text = "💡 × %d" % hint_count
	hint_remove_queue = level_data.get("hint_remove", []).duplicate()
	hint_index = 0

	# 构建答案槽
	_build_slots()

	# 构建候选字池
	_build_candidates()

	# 加载插图（如果有的话）
	_load_illustrations()

	# 确认按钮初始不可用
	_update_confirm_button()


func _reset_state() -> void:
	# 清理候选字
	for tile in candidate_tiles:
		if is_instance_valid(tile):
			tile.queue_free()
	candidate_tiles.clear()
	for child in candidates_container.get_children():
		child.queue_free()

	# 清理答案槽
	answer_slots.clear()
	for child in slots_container.get_children():
		child.queue_free()

	slot_filled.clear()


func _build_slots() -> void:
	var answer: Array = level_data["answer"]
	for _i in answer.size():
		var slot := Button.new()
		slot.text = "？"
		slot.custom_minimum_size = Vector2(80, 80)
		slot.theme_type_variation = "AnswerSlot"
		slot.pressed.connect(_on_slot_clicked.bind(_i))
		slots_container.add_child(slot)
		answer_slots.append(slot)
		slot_filled.append(false)


func _build_candidates() -> void:
	var candidates: Array = level_data["candidates"]
	candidates = candidates.duplicate()
	candidates.shuffle()  # 随机打乱

	for i in candidates.size():
		var tile := _create_tile(candidates[i], i)
		candidates_container.add_child(tile)
		candidate_tiles.append(tile)


func _create_tile(char: String, idx: int):
	var tile_scene := load("res://scenes/tile.tscn") as PackedScene
	var tile: Node
	if tile_scene:
		tile = tile_scene.instantiate()
	else:
		# 回退：代码创建
		tile = Button.new()
		tile.set_script(load("res://scripts/ui/tile.gd"))
		tile.custom_minimum_size = Vector2(72, 72)

	tile.setup(char, idx)
	tile.pressed.connect(_on_tile_clicked.bind(tile))
	return tile


func _load_illustrations() -> void:
	var before_path: String = level_data.get("illustration_before", "")
	var after_path: String = level_data.get("illustration_after", "")

	if not before_path.is_empty() and ResourceLoader.exists("res://assets/illustrations/" + before_path):
		illustration.texture = load("res://assets/illustrations/" + before_path)
	else:
		# 占位：显示纯色块
		illustration.texture = _create_placeholder(Color(0.8, 0.85, 0.9))

	if not after_path.is_empty() and ResourceLoader.exists("res://assets/illustrations/" + after_path):
		illustration_after.texture = load("res://assets/illustrations/" + after_path)

	illustration.show()
	illustration_after.hide()


func _create_placeholder(color: Color) -> ImageTexture:
	var img := Image.create(400, 250, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# 绘制提示文字（简单边框表示占位）
	for x in range(5, 395):
		for y in range(5, 10):
			img.set_pixel(x, y, Color.BLACK)
		for y in range(240, 245):
			img.set_pixel(x, y, Color.BLACK)
	return ImageTexture.create_from_image(img)


# ===== 交互逻辑 =====

func _on_tile_clicked(tile) -> void:
	if tile.is_placed or tile.disabled:
		return

	# 找到第一个空槽
	var target_slot_idx := -1
	for i in slot_filled.size():
		if not slot_filled[i]:
			target_slot_idx = i
			break

	if target_slot_idx == -1:
		return  # 所有槽都满了

	# 填入
	tile.place()
	answer_slots[target_slot_idx].text = tile.character
	slot_filled[target_slot_idx] = true
	# 关联 tile 到槽（通过 metadata）
	answer_slots[target_slot_idx].set_meta("tile", tile)
	answer_slots[target_slot_idx].theme_type_variation = "AnswerSlotFilled"

	_update_confirm_button()


func _on_slot_clicked(slot_idx: int) -> void:
	# 如果槽已填，退回 tile
	if not slot_filled[slot_idx]:
		return

	var tile = answer_slots[slot_idx].get_meta("tile")
	if tile and is_instance_valid(tile):
		tile.unplace()

	answer_slots[slot_idx].text = "？"
	answer_slots[slot_idx].set_meta("tile", null)
	answer_slots[slot_idx].theme_type_variation = "AnswerSlot"
	slot_filled[slot_idx] = false

	_update_confirm_button()


func _on_confirm_pressed() -> void:
	if not _all_slots_filled():
		return

	var player_answer := ""
	for i in answer_slots.size():
		player_answer += answer_slots[i].text

	var correct_answer := ""
	for ch in level_data["answer"]:
		correct_answer += ch

	if player_answer == correct_answer:
		_on_correct_answer()
	else:
		_on_wrong_answer()


func _on_correct_answer() -> void:
	# 禁用交互
	confirm_btn.disabled = true
	hint_btn.disabled = true

	# 插图动画
	_play_transform_animation()

	# 延迟弹出过关弹窗
	await get_tree().create_timer(1.8).timeout
	_show_victory_popup()


func _on_wrong_answer() -> void:
	# 抖动反馈
	var tween := create_tween()
	tween.tween_property(slots_container, "position:x", slots_container.position.x - 10, 0.05)
	tween.tween_property(slots_container, "position:x", slots_container.position.x + 10, 0.05)
	tween.tween_property(slots_container, "position:x", slots_container.position.x - 10, 0.05)
	tween.tween_property(slots_container, "position:x", slots_container.position.x + 10, 0.05)
	tween.tween_property(slots_container, "position:x", slots_container.position.x, 0.05)

	# TODO: 播放错误音效


func _on_hint_pressed() -> void:
	if hint_count <= 0:
		return

	# 从移除队列取 1-2 个干扰字
	var removed := 0
	while removed < 2 and hint_index < hint_remove_queue.size():
		var target_char := hint_remove_queue[hint_index]
		hint_index += 1

		# 找到对应的 tile 并移除
		for tile in candidate_tiles:
			if is_instance_valid(tile) and tile.character == target_char and not tile.is_placed and not tile.disabled:
				tile.remove_with_hint()
				removed += 1
				break

	hint_count -= 1
	hint_label.text = "💡 × %d" % hint_count

	if hint_count <= 0:
		hint_btn.disabled = true


# ===== 辅助方法 =====

func _all_slots_filled() -> bool:
	for filled in slot_filled:
		if not filled:
			return false
	return true


func _update_confirm_button() -> void:
	confirm_btn.disabled = not _all_slots_filled()


func _play_transform_animation() -> void:
	# Before → After 插图过渡
	if illustration_after.texture:
		illustration.show()
		illustration_after.hide()

		# Before 缩小 + 淡出
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(illustration, "scale", Vector2(0.5, 0.5), 0.4)
		tween.tween_property(illustration, "modulate:a", 0.0, 0.4)

		# After 正常大小 + 淡入
		illustration_after.scale = Vector2(0.5, 0.5)
		illustration_after.modulate = Color(1, 1, 1, 0)
		illustration_after.show()
		var tween2 := create_tween()
		tween2.set_parallel(true)
		tween2.tween_property(illustration_after, "scale", Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_delay(0.35)
		tween2.tween_property(illustration_after, "modulate:a", 1.0, 0.5).set_delay(0.35)


func _show_victory_popup() -> void:
	var popup := AcceptDialog.new()
	popup.title = "🎉 恭喜通关！"
	popup.dialog_text = "你太厉害了！"
	popup.confirmed.connect(_on_victory_confirmed)
	add_child(popup)
	popup.popup_centered()


func _on_victory_confirmed() -> void:
	GameManager.complete_level(GameManager.current_level)

	if GameManager.has_next_level():
		GameManager.go_to_next_level()
		get_tree().reload_current_scene()
	else:
		# 全部通关！
		var popup := AcceptDialog.new()
		popup.title = "🏆 全部通关！"
		popup.dialog_text = "你是真正的解谜大师！"
		popup.confirmed.connect(_on_all_clear)
		add_child(popup)
		popup.popup_centered()


func _on_all_clear() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
