extends Node

## LevelDataLoader — 关卡数据加载器
## 从 JSON 文件加载所有关卡数据

const DATA_PATH := "res://data/levels.json"

var _levels: Array[Dictionary] = []
var _loaded := false


func _ready() -> void:
	_load_levels()


func _load_levels() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("LevelDataLoader: 无法读取 ", DATA_PATH)
		return
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_error("LevelDataLoader: JSON 解析失败")
		return
	_levels.assign(json.data.get("levels", []))
	_loaded = true


func get_level(level_id: int) -> Dictionary:
	if not _loaded:
		_load_levels()
	for lv in _levels:
		if lv.get("id") == level_id:
			return lv
	push_error("LevelDataLoader: 关卡 ", level_id, " 不存在")
	return {}


func get_level_count() -> int:
	if not _loaded:
		_load_levels()
	return _levels.size()


func get_all_levels() -> Array[Dictionary]:
	if not _loaded:
		_load_levels()
	return _levels
