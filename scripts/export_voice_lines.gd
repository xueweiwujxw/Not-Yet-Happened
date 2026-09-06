extends SceneTree
## Export exact display blocks, preserving source attribution and stable content hashes.

const Voice := preload("res://src/art/dialogue_voice.gd")
const SOURCES := ["chapter_one", "chapter_two", "chapter_three", "chapter_four", "chapter_five", "chapter_six"]
var rows: Array[PackedStringArray] = []
var seen: Dictionary = {}


func _initialize() -> void:
	for source: String in SOURCES:
		var script := load("res://src/content/" + source + ".gd") as GDScript
		var constants := script.get_script_constant_map()
		for group: String in ["OPENING", "LINES", "DIALOGUE", "RECORDING", "ARRIVAL", "LETTER"]:
			if constants.has(group):
				collect(constants[group], source + "." + group)
	DirAccess.make_dir_recursive_absolute("res://build/voice")
	var file := FileAccess.open("res://build/voice/lines.csv", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_csv_line(PackedStringArray(["sha256", "source", "text", "take_path"]))
	for row: PackedStringArray in rows:
		file.store_csv_line(row)
	file.close()
	print("Exported %d unique dialogue blocks to build/voice/lines.csv" % rows.size())
	quit(0)


func collect(value: Variant, source: String) -> void:
	if value is Dictionary:
		for key: Variant in value:
			collect(value[key], source + "." + String(key))
	elif value is Array:
		for i: int in range(value.size()):
			collect(value[i], source + "." + str(i))
	elif value is String and not value.is_empty():
		var key := Voice.key_for(value)
		if not seen.has(key):
			seen[key] = true
			rows.append(PackedStringArray([key, source, value, ""]))
