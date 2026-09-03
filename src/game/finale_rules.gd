extends RefCounted
## Explicit route rules, independent of UI and random-number generators.

const Third := preload("res://src/content/chapter_three.gd")
const Fourth := preload("res://src/content/chapter_four.gd")
const Fifth := preload("res://src/content/chapter_five.gd")
const Sixth := preload("res://src/content/chapter_six.gd")


static func can_act(chapter: int, action: StringName, facts: Dictionary) -> bool:
	match chapter:
		3: return _chapter_three(action, facts)
		4: return _chapter_four(action, facts)
		5: return _chapter_five(action, facts)
		6: return _chapter_six(action, facts)
	return false


static func _chapter_four(action: StringName, f: Dictionary) -> bool:
	if action == &"next":
		return f.has(&"c4_closed")
	if f.has(&"c4_closed"):
		return false
	if action == &"revisit":
		return not f.has(&"c4_entered") and f.get(&"rescue_instructions", false) and (f.has(&"c2_cabinet_known") or f.has(&"cabinet_matched"))
	if not f.has(&"c4_entered"):
		return false
	match action:
		&"connect_light": return not f.has(&"c4_boarding") and not f.has(&"backup_connected")
		&"boarding": return not f.has(&"c4_boarding")
		&"lower_ladder": return f.has(&"c4_boarding") and not f.has(&"ladder_lowered")
		&"confirm_platform", &"leave_blank": return true
	return false


static func _chapter_five(action: StringName, f: Dictionary) -> bool:
	match action:
		&"records": return not f.has(&"identity_sources_reviewed")
		&"verify": return f.has(&"identity_sources_reviewed") and not f.has(&"sister_fate") and f.get(&"platform_route", "") in ["safe", "fall"]
		&"seal": return f.has(&"identity_sources_reviewed") and not f.has(&"sister_fate")
		&"invite", &"no_invite": return f.get(&"sister_fate", "") == "alive" and not f.has(&"invitation_sent")
		&"dinner": return not f.has(&"family_conversation")
		&"correction": return not f.has(&"report_correction")
		&"next": return f.has(&"sister_fate") and f.has(&"family_conversation") and f.has(&"report_correction") and (f[&"sister_fate"] != "alive" or f.has(&"invitation_sent"))
	return false


static func _chapter_six(action: StringName, f: Dictionary) -> bool:
	if f.has(&"ending_id") or ending(f).is_empty():
		return false
	match action:
		&"memorial": return not f.has(&"memorial_wording")
		&"portrait_join", &"portrait_decline": return f.has(&"memorial_wording") and not f.has(&"farewell_portrait")
		&"departure": return f.has(&"memorial_wording") and f.has(&"farewell_portrait") and not ending(f).is_empty()
	return false


static func ending(f: Dictionary) -> String:
	match f.get(&"sister_fate", ""):
		"alive":
			if f.get(&"platform_route", "") != "safe" or not f.get(&"invitation_sent") is bool:
				return ""
			return "kitchen" if f[&"invitation_sent"] else "distance"
		"dead":
			return "name" if f.get(&"platform_route", "") == "fall" and not f.has(&"invitation_sent") else ""
		"unconfirmed":
			return "blank" if not f.has(&"invitation_sent") else ""
	return ""


static func content(chapter: int) -> GDScript:
	return {3: Third, 4: Fourth, 5: Fifth, 6: Sixth}.get(chapter)


static func outcome(chapter: int, action: StringName, f: Dictionary) -> Dictionary:
	if not can_act(chapter, action, f):
		return {}
	var source := content(chapter)
	var effects: Dictionary = source.FACTS.get(action, {}).duplicate(true)
	var line_id := action
	if chapter == 4:
		if action == &"boarding" and not f.has(&"backup_connected"):
			effects[&"backup_connected"] = false
		if action == &"confirm_platform":
			for key: StringName in [&"backup_connected", &"ladder_lowered"]:
				if not f.has(key):
					effects[key] = false
			var safe: bool = f.get(&"backup_connected", false) and f.get(&"ladder_lowered", false)
			line_id = &"safe" if safe else &"fall"
			effects.merge({&"c4_closed": true, &"platform_route": String(line_id)})
	if chapter == 5:
		match action:
			&"records": line_id = StringName("records_" + String(f.get(&"platform_route", "blank")))
			&"verify":
				var fate := "alive" if f.get(&"platform_route") == "safe" else "dead"
				line_id = StringName("verify_" + fate)
				effects[&"sister_fate"] = fate
	if chapter == 6:
		match action:
			&"memorial":
				line_id = StringName("memorial_" + String(f[&"sister_fate"]))
				effects[&"memorial_wording"] = Sixth.WORDING[f[&"sister_fate"]]
			&"portrait_join", &"portrait_decline":
				var together: bool = f.get(&"shiori_boundary_respected", false)
				line_id = StringName(("join_" if action == &"portrait_join" else "decline_") + ("together" if together else "alone"))
				effects[&"farewell_portrait"] = String(line_id)
			&"departure":
				line_id = StringName(ending(f))
				effects[&"ending_id"] = String(line_id)
	var lines: Array[String] = []
	lines.assign(source.LINES[line_id])
	return {"facts": effects, "lines": lines, "next_chapter": chapter + 1 if action == &"next" else chapter}


static func _chapter_three(action: StringName, f: Dictionary) -> bool:
	match action:
		&"admission": return not f.has(&"admission_letter")
		&"equipment": return not f.has(&"equipment_model")
		&"stretcher": return not f.has(&"stretcher_image")
		&"report": return not f.has(&"report_text")
		&"patrol": return f.has(&"report_text") and not f.has(&"patrol_map_scope")
		&"diagram": return f.has(&"equipment_model") and f.has(&"patrol_map_scope") and not f.has(&"rescue_instructions")
		&"match_cabinet": return f.has(&"rescue_instructions") and not f.has(&"c2_cabinet_known") and not f.has(&"cabinet_matched")
		&"forgive", &"withhold": return f.has(&"patrol_map_scope") and not f.has(&"keeper_forgiven")
		&"ask_audio": return f.has(&"admission_letter") and not f.has(&"shiori_refused_audio")
		&"respect", &"play_anyway": return f.has(&"shiori_refused_audio") and not f.has(&"shiori_boundary_respected")
		&"next": return f.has(&"admission_letter") and f.has(&"rescue_instructions") and f.has(&"shiori_boundary_respected") and (f.has(&"c2_cabinet_known") or f.has(&"cabinet_matched"))
	return false
