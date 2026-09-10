extends RefCounted
## Quiet, authored expression changes. No random timing or dialogue advancement.


static func apply(person: Node3D, emotion: StringName, elapsed: float, enabled: bool) -> void:
	if not is_instance_valid(person):
		return
	# A brief blink every four seconds, not repeated at every dialogue boundary.
	var phase := fposmod(maxf(elapsed, 0.0), 4.0)
	var blink := 1.0
	if enabled and phase >= 3.8:
		blink = maxf(0.12, absf(phase - 3.9) / 0.1)
	var lid := 0.7 if enabled and emotion == &"reserved" else 1.0
	for eye_name: String in ["EyeLeft", "EyeRight"]:
		var eye := person.get_node_or_null(eye_name) as Node3D
		if eye != null:
			eye.scale.y = 0.045 * blink * lid
	var mouth := person.get_node_or_null("Mouth") as Node3D
	if mouth != null:
		mouth.scale = Vector3.ONE
		if enabled and emotion == &"warm":
			mouth.scale = Vector3(1.35, 1.0, 1.0)
		elif enabled and emotion == &"reserved":
			mouth.scale.x = 0.7
