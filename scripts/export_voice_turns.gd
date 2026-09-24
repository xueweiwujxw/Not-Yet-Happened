extends SceneTree
## Exact speech-only catalog for offline production; speaker/directions never enter TTS text.

const Catalog := preload("res://scripts/export_voice_lines.gd")
const Beats := preload("res://src/game/dialogue_beats.gd")
var turns: Dictionary = {}


func _initialize() -> void:
	for source: String in Catalog.SOURCES:
		var constants: Dictionary = load("res://src/content/" + source + ".gd").get_script_constant_map()
		for group: String in ["OPENING", "LINES", "DIALOGUE", "RECORDING", "ARRIVAL", "LETTER"]:
			if constants.has(group):
				collect(constants[group], source + "." + group)
	DirAccess.make_dir_recursive_absolute("res://build/voice")
	var file := FileAccess.open("res://build/voice/turns.json", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_string(JSON.stringify(turns.values(), "\t"))
	file.close()
	print("Exported %d unique spoken turns" % turns.size())
	quit(0)


func collect(value: Variant, source: String) -> void:
	if value is Dictionary:
		for key: Variant in value:
			collect(value[key], source + "." + String(key))
	elif value is Array:
		for i: int in range(value.size()):
			collect(value[i], source + "." + str(i))
	elif value is String:
		for turn: Dictionary in Beats.split(value):
			if turn["speaker"].is_empty():
				continue
			var key: String = turn["voice_key"]
			if not turns.has(key):
				turns[key] = turn.duplicate()
				turns[key]["sources"] = []
			turns[key]["sources"].append(source)
