extends RefCounted
## Device presentation preferences are separate from replayable narrative saves.

var path := "user://presentation.cfg"
var voice_enabled := false
var camera_enabled := true


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return
	var voice: Variant = config.get_value("presentation", "voice", false)
	var camera: Variant = config.get_value("presentation", "camera", true)
	voice_enabled = voice if voice is bool else false
	camera_enabled = camera if camera is bool else true


func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("presentation", "voice", voice_enabled)
	config.set_value("presentation", "camera", camera_enabled)
	return config.save(path)
