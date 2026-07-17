extends Node

## SaveSystem — 本地存档管理 (Autoload)
## 使用 JSON 文件持久化游戏进度

const SAVE_PATH := "user://save_data.json"


func save_progress(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: 无法写入存档文件 ", SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_progress() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(content)
	if err != OK:
		push_error("SaveSystem: 存档解析失败")
		return {}
	return json.data


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
