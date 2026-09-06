extends RefCounted
## Spatial affordances only; chapter two owns all time-window and evidence rules.

const Bounds := preload("res://src/game/kitchen_interactions.gd")
const ZONES := [
	{"id": &"telephone", "at": Vector2(-3.4, -1.2), "actions": [&"telephone", &"call"]},
	{"id": &"tape", "at": Vector2(-0.7, -1.2), "actions": [&"tape", &"enter", &"review"]},
	{"id": &"door", "at": Vector2(2.5, -1.6), "actions": [&"listen", &"open", &"return"]},
	{"id": &"exit", "at": Vector2(-3.8, 2.5), "actions": [&"leave"]},
]


static func nearby(position: Vector3, session: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	var distance := 1.7
	for zone: Dictionary in ZONES:
		var actions: Array[StringName] = []
		for action: StringName in zone["actions"]:
			if session.can_act(action):
				actions.append(action)
		var current := Vector2(position.x, position.z).distance_to(zone["at"])
		if not actions.is_empty() and current < distance:
			distance = current
			result = {"id": zone["id"], "at": zone["at"], "actions": actions}
	return result


static func constrain(position: Vector3) -> Vector3:
	return Bounds.constrain(position)
