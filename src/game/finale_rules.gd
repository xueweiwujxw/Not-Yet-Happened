extends RefCounted
## Explicit route rules, independent of UI and random-number generators.


static func can_act(chapter: int, action: StringName, facts: Dictionary) -> bool:
	match chapter:
		3: return _chapter_three(action, facts)
	return false


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
