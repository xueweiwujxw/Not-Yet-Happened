extends RefCounted

const Five := preload("res://src/content/chapter_five.gd")
const Six := preload("res://src/content/chapter_six.gd")
const Voice := preload("res://src/art/dialogue_voice.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/manifest.json"))
	var lines: Array = [Five.OPENING[1], Five.LINES[&"dinner"][0], Five.LINES[&"dinner"][1], Six.LINES[&"memorial_dead"][0], Six.LINES[&"join_together"][0], Six.LINES[&"decline_together"][0]]
	for line: String in lines:
		var path: String = manifest.get(Voice.key_for(line), "")
		if not path.begins_with("res://assets/voice/") or ".." in path or not FileAccess.file_exists(path):
			failures.append("Farewell voice missing for exact subtitle: " + line)
			continue
		var stream := AudioStreamOggVorbis.load_from_file(path)
		if stream == null or stream.get_length() <= 0.5 or stream.get_length() > 30:
			failures.append("Farewell voice cannot decode complete short block: " + path)
	for line: String in [Six.LINES[&"join_alone"][0], Six.LINES[&"decline_alone"][0]]:
		if manifest.has(Voice.key_for(line)):
			failures.append("Absent Shiori must not reuse together-portrait voice")
	return failures
