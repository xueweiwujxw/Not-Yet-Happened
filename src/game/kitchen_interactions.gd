extends RefCounted
## Spatial affordances only. The existing chapter session still owns every narrative rule.

const RADIUS := 1.6
const ZONES := [
	{"id": &"door", "at": Vector2(-3.75, 2.45), "actions": [&"notice", &"leave"]},
	{"id": &"switch", "at": Vector2(-4.2, 0.5), "actions": [&"switch"]},
	{"id": &"lamp", "at": Vector2(-1.35, 1.1), "actions": [&"repair"]},
	{"id": &"table", "at": Vector2(0.65, 0.1), "actions": [&"recording", &"letter"]},
	{"id": &"photo", "at": Vector2(3.95, 1.6), "actions": [&"photo"]},
	{"id": &"shiori", "at": Vector2(2.3, -1.45), "actions": [&"melted", &"eat", &"portrait"]},
]


static func nearby(position: Vector3, session: RefCounted) -> Dictionary:
	var closest: Dictionary = {}
	var distance := RADIUS
	for zone: Dictionary in ZONES:
		var available: Array[StringName] = []
		for action: StringName in zone["actions"]:
			if session.can_act(action):
				available.append(action)
		if available.is_empty():
			continue
		var current := Vector2(position.x, position.z).distance_to(zone["at"])
		if current < distance:
			distance = current
			closest = {"id": zone["id"], "at": zone["at"], "actions": available}
	return closest


static func constrain(position: Vector3) -> Vector3:
	return Vector3(clampf(position.x, -4.55, 4.55), position.y, clampf(position.z, -3.4, 3.4))
