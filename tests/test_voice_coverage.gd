extends RefCounted
## Every explicit spoken block must retain a decodable take after subtitle changes.

const Catalog := preload("res://scripts/export_voice_lines.gd")
const Voice := preload("res://src/art/dialogue_voice.gd")
const Two := preload("res://src/content/chapter_two.gd")
var manifest: Dictionary
var failures: Array[String] = []
var seen: Dictionary = {}
var speech := RegEx.new()


func run() -> Array[String]:
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/manifest.json"))
	speech.compile("(?m)^(年幼的林澈|林澈|林遥|栞|许岚|沈琴|周启明)：")
	for source: String in Catalog.SOURCES:
		var script := load("res://src/content/" + source + ".gd") as GDScript
		var constants := script.get_script_constant_map()
		for group: String in ["OPENING", "LINES", "DIALOGUE", "RECORDING", "ARRIVAL", "LETTER"]:
			if constants.has(group):
				check_blocks(constants[group], source + "." + group)
	for key: String in manifest:
		if not seen.has(key):
			failures.append("Voice manifest references stale or unknown subtitle: " + key)
		var path: String = manifest[key]
		if not path.begins_with("res://assets/voice/") or ".." in path or not FileAccess.file_exists(path):
			failures.append("Invalid voice asset path: " + path)
			continue
		var stream := AudioStreamOggVorbis.load_from_file(path)
		if stream == null or stream.get_length() < 0.25 or stream.get_length() > 60:
			failures.append("Voice asset cannot decode as a complete short block: " + path)
	return failures


func check_blocks(value: Variant, source: String) -> void:
	if value is Dictionary:
		for key: Variant in value:
			check_blocks(value[key], source + "." + String(key))
	elif value is Array:
		for i: int in range(value.size()):
			check_blocks(value[i], source + "." + str(i))
	elif value is String:
		var key := Voice.key_for(value)
		seen[key] = true
		if (speech.search(value) != null or value == Two.TAPE_PREFIX) and not manifest.has(key):
			failures.append("Spoken dialogue has no exact-text voice mapping: " + source)
