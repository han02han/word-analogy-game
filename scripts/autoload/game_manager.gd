extends Node

## GameManager — 全局游戏状态管理 (Autoload)
## 管理关卡解锁进度、当前关卡、场景切换

signal level_completed(level_id: int)
signal progress_reset

var current_level: int = 1
var unlocked_count: int = 1  # 至少第1关解锁
var completed_levels: Array[int] = []


func _ready() -> void:
	# 启动时从存档恢复进度
	if SaveSystem.save_exists():
		load_from_save()


func load_from_save() -> void:
	var data := SaveSystem.load_progress()
	if data.is_empty():
		return
	unlocked_count = data.get("unlocked_count", 1)
	completed_levels = data.get("completed", [])
	# 确保至少第1关解锁
	if unlocked_count < 1:
		unlocked_count = 1


func is_unlocked(level_id: int) -> bool:
	return level_id <= unlocked_count


func is_completed(level_id: int) -> bool:
	return level_id in completed_levels


func complete_level(level_id: int) -> void:
	if level_id in completed_levels:
		return  # 已经通关，不重复记录
	completed_levels.append(level_id)
	# 解锁下一关
	if level_id + 1 > unlocked_count:
		unlocked_count = level_id + 1
	_save()
	level_completed.emit(level_id)


func reset_progress() -> void:
	unlocked_count = 1
	completed_levels.clear()
	SaveSystem.delete_save()
	progress_reset.emit()


func get_total_levels() -> int:
	return LevelDataLoader.get_level_count()


func has_next_level() -> bool:
	return current_level < get_total_levels()


func go_to_next_level() -> void:
	if has_next_level():
		current_level += 1


func _save() -> void:
	SaveSystem.save_progress({
		"unlocked_count": unlocked_count,
		"completed": completed_levels
	})
