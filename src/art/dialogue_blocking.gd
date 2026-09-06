extends RefCounted
## Authored visual beats keyed by complete display blocks; never infer story facts.

const Three := preload("res://src/content/chapter_three.gd")
const Five := preload("res://src/content/chapter_five.gd")
const Six := preload("res://src/content/chapter_six.gd")


static func cue(text: String) -> Dictionary:
	if text in Three.OPENING:
		return {"actor": &"shiori", "delay": 0.4, "turn": 0.0}
	if text in Three.LINES[&"ask_audio"]:
		return {"actor": &"shiori", "delay": 0.8, "turn": -1.1}
	if text in Three.LINES[&"respect"]:
		return {"actor": &"shiori", "delay": 0.6, "turn": 0.0}
	if text == Three.LINES[&"admission"][2]:
		return {"actor": &"shen", "delay": 0.3, "turn": 0.0}
	if text in Five.OPENING or text in Five.LINES[&"dinner"]:
		return {"actor": &"xu", "delay": 0.5, "turn": 0.0}
	if text in Six.LINES[&"join_together"] or text in Six.LINES[&"decline_together"]:
		return {"actor": &"shiori", "delay": 0.5, "turn": 0.0}
	return {}
