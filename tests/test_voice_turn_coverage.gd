extends RefCounted
## Coverage alone cannot certify acting quality; it can prevent wrong/missing lines and casts.

const Catalog := preload("res://scripts/export_voice_lines.gd")
const Beats := preload("res://src/game/dialogue_beats.gd")
var expected: Dictionary = {}


func run() -> Array[String]:
	var failures: Array[String] = []
	for source: String in Catalog.SOURCES:
		var constants: Dictionary = load("res://src/content/" + source + ".gd").get_script_constant_map()
		for group: String in ["OPENING", "LINES", "DIALOGUE", "RECORDING", "ARRIVAL", "LETTER"]:
			if constants.has(group):
				collect(constants[group])
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/turn-manifest.json"))
	var provenance: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/mandarin-provenance.json"))
	if not manifest is Dictionary or not provenance is Dictionary:
		return ["Turn voice: missing/invalid catalog or provenance"]
	var takes: Dictionary = {}
	for take: Dictionary in provenance["takes"]:
		if takes.has(take["key"]):
			failures.append("Turn voice: duplicate provenance entry")
		takes[take["key"]] = take
	for key: String in expected:
		if not manifest.has(key) or not takes.has(key):
			failures.append("Turn voice: missing exact spoken turn " + key)
			continue
		var path: String = manifest[key]
		if not path.begins_with("res://assets/voice/mandarin-") or ".." in path or not FileAccess.file_exists(path):
			failures.append("Turn voice: invalid take path " + path)
			continue
		var take: Dictionary = takes[key]
		if take["speaker"] != expected[key]["speaker"] or take["text"] != expected[key]["text"] or not take["voice"].begins_with("zh-CN-"):
			failures.append("Turn voice: mismatched text or Mandarin cast " + key)
		if FileAccess.get_sha256(path) != take["asset_sha256"]:
			failures.append("Turn voice: asset/provenance checksum differs " + key)
		var stream := AudioStreamOggVorbis.load_from_file(path)
		if stream == null or stream.get_length() < 0.2 or stream.get_length() > 60:
			failures.append("Turn voice: undecodable or incomplete take " + key)
	if manifest.size() != expected.size() or takes.size() != expected.size():
		failures.append("Turn voice: stale/missing catalog entries")
	return failures


func collect(value: Variant) -> void:
	if value is Dictionary:
		for child: Variant in value.values():
			collect(child)
	elif value is Array:
		for child: Variant in value:
			collect(child)
	elif value is String:
		for turn: Dictionary in Beats.split(value):
			if not turn["speaker"].is_empty():
				expected[turn["voice_key"]] = turn
