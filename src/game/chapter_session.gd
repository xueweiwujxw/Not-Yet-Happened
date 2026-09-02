extends RefCounted

const Content := preload("res://src/content/chapter_one.gd")
const World := preload("res://src/core/world_state.gd")

var _world := World.new()
var _done: Dictionary = {}
var _people_present: bool = false
var _switch_on: bool = true
var _repaired: bool = false
var _completed: bool = false
var _leaving: bool = false
var _pending_facts: Dictionary = {}
var _dialogue: Array[String] = []
var _cursor: int = 0


func _init() -> void:
	_world.confirm_fact(&"children_survived", true)
	_world.confirm_fact(&"sister_missing", true)
	_dialogue = Content.lines(&"opening")


func advance() -> bool:
	if not speaking():
		return false
	_cursor += 1
	if not speaking():
		for key: StringName in _pending_facts:
			_world.confirm_fact(key, _pending_facts[key])
		_pending_facts.clear()
	if not speaking() and _leaving:
		_completed = true
		_switch_on = false
	return true


func speaking() -> bool:
	return _cursor < _dialogue.size()


func can_act(action: StringName) -> bool:
	if speaking() or _completed or not Content.LABELS.has(action):
		return false
	if action in [&"letter", &"portrait", &"melted", &"eat"] and not _people_present:
		return false
	if action in [&"melted", &"eat"] and _done.has(&"icecream"):
		return false
	if action == &"portrait" and _done.has(action):
		return false
	return true


func act(action: StringName) -> bool:
	if not can_act(action):
		return false
	_dialogue.clear()
	_cursor = 0
	match action:
		&"notice":
			_pending_facts[&"notice_text"] = "旧防波堤拆除前，最后一次集体追思。"
			_append(&"notice")
		&"switch":
			_switch_on = not _switch_on
			_dialogue.append(lamp_text())
		&"repair":
			_repair()
		&"recording":
			_pending_facts[&"recording_words"] = Content.RECORDING
			_done[action] = true
			_dialogue.append_array(Content.RECORDING)
			_arrive()
		&"photo":
			_pending_facts[&"photo_front"] = "林澈、林遥、栞在防波堤；栞穿红鞋。"
			_pending_facts[&"photo_back"] = "开学前最后一个夏天。"
			_done[action] = true
			_append(&"photo_together" if _people_present else &"photo_alone")
			_arrive()
		&"melted", &"eat":
			_done[&"icecream"] = true
			_append(action)
		&"portrait":
			_done[action] = true
			_pending_facts[&"portrait"] = "栞同意留下吃冰棒时的照片。"
			_append(action)
		&"letter":
			_done[action] = true
			_pending_facts[&"letter_words"] = Content.LETTER
			_dialogue.append(Content.LETTER)
			_append(&"letter_end" if _done.has(&"photo") else &"letter_without_photo")
		&"leave":
			var missing := missing_clues()
			if not missing.is_empty():
				_dialogue.append(Content.MISSING + "、".join(missing))
			else:
				_leaving = true
				if _repaired:
					_append(&"leave_repaired" if _switch_on else &"leave_repaired_off")
				else:
					_append(&"leave_dark")
	return true


func missing_clues() -> Array[String]:
	var result: Array[String] = []
	for key: StringName in Content.REQUIREMENTS:
		if not _done.has(key):
			result.append(Content.REQUIREMENTS[key])
	return result


func lamp_text() -> String:
	if not _switch_on:
		return Content.LAMP_OFF
	return Content.LAMP_ON if _repaired else Content.LAMP_BROKEN


func view() -> Dictionary:
	var confirmed: Array[String] = []
	for key: StringName in Content.FACT_NOTES:
		if _world.has_fact(key):
			confirmed.append(Content.FACT_NOTES[key])
	var claims: Array[String] = []
	if _world.has_fact(&"letter_words"):
		claims.append(Content.SHEN_CLAIM)
	return {
		"line": _dialogue[_cursor] if speaking() else Content.FINISHED if _completed else Content.IDLE,
		"speaking": speaking(), "completed": _completed,
		"people_present": _people_present, "repaired": _repaired,
		"lamp": lamp_text(), "done": _done.duplicate(true),
		"facts": _world.snapshot(), "confirmed": confirmed, "claims": claims,
	}


func _append(id: StringName) -> void:
	_dialogue.append_array(Content.lines(id))


func _arrive() -> void:
	if _people_present:
		return
	_people_present = true
	_dialogue.append_array(Content.ARRIVAL)
	if _done.has(&"photo"):
		_append(&"photo_followup")
	if _repaired:
		_append(&"lamp_memory")


func _repair() -> void:
	if _repaired:
		_append(&"already_repaired")
	elif _switch_on:
		_append(&"unsafe_repair")
	else:
		_repaired = true
		_append(&"repair")
		if _people_present:
			_append(&"lamp_memory")
