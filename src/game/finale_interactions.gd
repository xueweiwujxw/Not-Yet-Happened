extends RefCounted
## Spatial access only. Narrative legality and all observations stay in FinaleSession.

const ZONES := {
	3: [
		{ "id": &"admission", "at": Vector2(-3.2, -1.7), "actions": [&"admission"] },
		{ "id": &"equipment", "at": Vector2(0, -1.7), "actions": [&"equipment", &"stretcher"] },
		{ "id": &"report", "at": Vector2(3.2, -1.7), "actions": [&"report", &"patrol", &"forgive", &"withhold"] },
		{ "id": &"diagram", "at": Vector2(-3.2, 0.7), "actions": [&"diagram", &"match_cabinet"] },
		{ "id": &"ask_audio", "at": Vector2(3.2, 0.7), "actions": [&"ask_audio", &"respect", &"play_anyway"] },
		{ "id": &"next", "at": Vector2(-2.4, 2.8), "actions": [&"next"] },
	],
	4: [
		{ "id": &"revisit", "at": Vector2(-2.4, 2.8), "actions": [&"revisit", &"next"] },
		{ "id": &"connect_light", "at": Vector2(-3.2, -1.7), "actions": [&"connect_light"] },
		{ "id": &"boarding", "at": Vector2(0, -1.7), "actions": [&"boarding", &"lower_ladder"] },
		{ "id": &"confirm_platform", "at": Vector2(3.2, -1.7), "actions": [&"confirm_platform"] },
		{ "id": &"leave_blank", "at": Vector2(3.2, 0.7), "actions": [&"leave_blank"] },
	],
	5: [
		{ "id": &"records", "at": Vector2(-3.2, -1.7), "actions": [&"records", &"verify", &"seal"] },
		{ "id": &"invite", "at": Vector2(0, -1.7), "actions": [&"invite", &"no_invite"] },
		{ "id": &"correction", "at": Vector2(3.2, -1.7), "actions": [&"correction"] },
		{ "id": &"dinner", "at": Vector2(3.2, 0.7), "actions": [&"dinner"] },
		{ "id": &"next", "at": Vector2(-2.4, 2.8), "actions": [&"next"] },
	],
	6: [
		{ "id": &"memorial", "at": Vector2(-3.2, -1.7), "actions": [&"memorial"] },
		{ "id": &"portrait_join", "at": Vector2(0, -1.7), "actions": [&"portrait_join", &"portrait_decline"] },
		{ "id": &"departure", "at": Vector2(3.2, 0.7), "actions": [&"departure"] },
	],
}


static func nearby(position: Vector3, session: RefCounted) -> Dictionary:
	var result: Dictionary = {}
	var distance := 1.2
	for zone: Dictionary in ZONES.get(session.view()["chapter"], []):
		var actions: Array[StringName] = []
		for action: StringName in zone["actions"]:
			if session.can_act(action):
				actions.append(action)
		var gap := Vector2(position.x, position.z).distance_to(zone["at"])
		if not actions.is_empty() and gap < distance:
			distance = gap
			result = {"id": zone["id"], "at": zone["at"], "actions": actions}
	return result


static func constrain(position: Vector3) -> Vector3:
	return Vector3(clampf(position.x, -4.55, 4.55), position.y, clampf(position.z, -3.4, 3.4))
