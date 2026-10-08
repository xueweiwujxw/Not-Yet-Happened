extends RefCounted
## Live presentation memory shared by notebook and 3D views. Never serialized as history.

var voice_muted := false
var camera_enabled := true
var progress_key := ""
var snapshot: Dictionary = {}

static func key(session: RefCounted) -> String:
	return str(session.get_instance_id()) + ":" + JSON.stringify(session.save_data()).sha256_text()
