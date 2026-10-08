extends RefCounted

const Four := preload("res://src/content/chapter_four.gd")

static func historical(state: Dictionary) -> bool:
	var facts: Dictionary = state["facts"]
	var returning: bool = state["speaking"] and state["line"] in [Four.LINES[&"safe"][2], Four.LINES[&"fall"][2]]
	return facts.has(&"c4_entered") and not facts.has(&"c4_closed") and not returning
