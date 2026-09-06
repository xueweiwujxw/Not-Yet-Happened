extends Node
## Optional recorded dialogue. Absence of a take is silent, never a fabricated voice.

var output: AudioStreamPlayer
var current_key := ""
var muted := false
var clips: Dictionary = {}
var resolve_stream: Callable = _resolve_stream
var _ticket := 0


func _ready() -> void:
	output = AudioStreamPlayer.new()
	output.volume_db = -3.0
	add_child(output)
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/voice/manifest.json"))
	if manifest is Dictionary:
		clips = manifest


static func key_for(text: String) -> String:
	return text.sha256_text()


func present(text: String, speaking: bool) -> void:
	var key := key_for(text) if speaking else ""
	if key == current_key:
		return
	stop()
	current_key = key
	if muted or not clips.has(key):
		return
	var path: Variant = clips[key]
	if not path is String or not path.begins_with("res://assets/voice/") or ".." in path:
		return
	output.stream = resolve_stream.call(path)
	if output.stream != null:
		_start_take.call_deferred(_ticket)


func _start_take(ticket: int) -> void:
	if ticket == _ticket and not muted and is_inside_tree() and output.stream != null:
		output.play()


func _resolve_stream(path: String) -> AudioStream:
	if path.ends_with(".ogg") and FileAccess.file_exists(path):
		return AudioStreamOggVorbis.load_from_file(path)
	return load(path) as AudioStream if ResourceLoader.exists(path, "AudioStream") else null


func stop() -> void:
	_ticket += 1
	if output != null:
		output.stop()
		output.stream = null
	current_key = ""


func set_muted(value: bool) -> void:
	muted = value
	if muted:
		_ticket += 1
		# Do not replay a line when unmuted; the next line starts normally.
		output.stop()


func _exit_tree() -> void:
	stop()
