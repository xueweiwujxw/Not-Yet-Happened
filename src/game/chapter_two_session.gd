extends RefCounted
## Canon revisit: only authored telephone/door histories, never random child safety.

const Content := preload("res://src/content/chapter_two.gd")
const First := preload("res://src/game/chapter_session.gd")
const World := preload("res://src/core/world_state.gd")
const Candidate := preload("res://src/core/possibility.gd")
const ObservationModel := preload("res://src/core/observation.gd")
const SAVE_VERSION := 1
const CONTENT_REVISION := "keeper-room-v1"
const MAX_SAVE_EVENTS := 8192
enum Phase { PRESENT, BEFORE_OUTAGE, AFTER_OUTAGE, OBSERVED, RETURNED, COMPLETE }

var _world := World.new()
var _phase := Phase.PRESENT
var _dialogue: Array[String] = []
var _cursor := 0
var _events: Array[String] = []
var _prologue: Dictionary = {}
var _pending: Dictionary = {}
var _pending_id: StringName = &""
var _ending := false


func start_after(first: First) -> bool:
	if not _prologue.is_empty() or first == null or not first.view()["completed"]:
		return false
	# Validate a copy; never trust/inject an arbitrary facts dictionary.
	var validated := First.new().restore_save(first.save_data())
	if validated == null or not validated.view()["completed"]:
		return false
	_prologue = validated.save_data()
	var inherited_facts: Dictionary = validated.view()["facts"]
	for key: StringName in inherited_facts:
		_world.confirm_fact(key, inherited_facts[key])
	_world.add_possibility(Candidate.new(&"keeper", {
		&"children_survived": true, &"c2_called": true, &"c2_escort": "keeper",
	}))
	_world.add_possibility(Candidate.new(&"sister", {
		&"children_survived": true, &"c2_called": false, &"c2_escort": "sister",
	}))
	_dialogue = Content.chapter_lines(&"opening")
	return true


func speaking() -> bool:
	return _cursor < _dialogue.size()


func advance() -> bool:
	if not speaking():
		return false
	if _cursor + 1 == _dialogue.size() and not _pending.is_empty():
		var observation := ObservationModel.new(_pending_id, &"lin-che", _pending)
		if _world.apply_observation(observation) != World.ObservationResult.ACCEPTED:
			# Keep the pending line and input log intact on an invalid authored transition.
			return false
		_pending.clear()
	_events.append("advance")
	_cursor += 1
	if not speaking() and _ending:
		_phase = Phase.COMPLETE
	return true


func can_act(action: StringName) -> bool:
	if _prologue.is_empty() or speaking() or _phase == Phase.COMPLETE:
		return false
	match action:
		&"telephone": return _phase == Phase.PRESENT and not _world.has_fact(&"c2_outage_record")
		&"tape": return _phase == Phase.PRESENT and not _world.has_fact(&"c2_tape_prefix")
		&"enter": return _phase == Phase.PRESENT and _world.has_fact(&"c2_outage_record") and _world.has_fact(&"c2_tape_prefix")
		&"call": return _phase == Phase.BEFORE_OUTAGE and not _world.has_fact(&"c2_called")
		&"listen": return _phase in [Phase.BEFORE_OUTAGE, Phase.AFTER_OUTAGE] and not _world.has_fact(&"c2_steps")
		&"open": return _phase in [Phase.BEFORE_OUTAGE, Phase.AFTER_OUTAGE]
		&"return": return _phase == Phase.OBSERVED
		&"review", &"leave": return _phase == Phase.RETURNED
	return false


func act(action: StringName) -> bool:
	if not can_act(action):
		return false
	_events.append(String(action))
	_cursor = 0
	_dialogue = Content.chapter_lines(action)
	_pending_id = StringName("c2-" + String(action))
	match action:
		&"telephone": _pending = {&"c2_outage_record": "18:20"}
		&"tape": _pending = {&"c2_tape_prefix": Content.TAPE_PREFIX}
		&"enter": _phase = Phase.BEFORE_OUTAGE
		&"call":
			# The chosen action is fixed now; unheard words remain pending until read.
			_world.confirm_fact(&"c2_called", true)
			_pending = {&"c2_words": Content.CALLED_WORDS, &"c2_cabinet_known": true}
		&"listen":
			_close_phone()
			_phase = Phase.AFTER_OUTAGE
			_pending = {&"c2_steps": true}
		&"open":
			_close_phone()
			_phase = Phase.OBSERVED
			var called: bool = _world.get_fact(&"c2_called")
			_dialogue = Content.chapter_lines(&"open_called" if called else &"open_alone")
			_pending = {&"c2_escort": "keeper" if called else "sister", &"c2_window_closed": true}
			if not called:
				_pending[&"c2_words"] = Content.UNCALLED_WORDS
		&"return": _phase = Phase.RETURNED
		&"review":
			_dialogue = [Content.TAPE_PREFIX, String(_world.get_fact(&"c2_words"))]
		&"leave": _ending = true
	return true


func _close_phone() -> void:
	if not _world.has_fact(&"c2_called"):
		_world.confirm_fact(&"c2_called", false)


func view() -> Dictionary:
	var confirmed: Array[String] = []
	for notes: Dictionary in [Content.FACT_NOTES, Content.NOTES]:
		for key: StringName in notes:
			if _world.has_fact(key):
				confirmed.append(notes[key])
	if _world.has_fact(&"c2_words"):
		confirmed.append(String(_world.get_fact(&"c2_words")))
	var status := Content.PRESENT
	match _phase:
		Phase.BEFORE_OUTAGE: status = Content.PAST
		Phase.AFTER_OUTAGE: status = Content.STORM
		Phase.OBSERVED: status = Content.RESOLVED
	return {
		"line": _dialogue[_cursor] if speaking() else Content.END_TEXT if _phase == Phase.COMPLETE else Content.PAST_IDLE if _phase in [Phase.BEFORE_OUTAGE, Phase.AFTER_OUTAGE] else Content.IDLE_TEXT,
		"speaking": speaking(), "completed": _phase == Phase.COMPLETE,
		"lamp": status + "\n" + Content.WINDOW, "repaired": false,
		"facts": _world.snapshot(), "confirmed": confirmed, "claims": [Content.SHEN_CLAIM],
		"phase": _phase, "candidates": _world.possibility_ids(),
	}


func new_attempt() -> RefCounted:
	var fresh: RefCounted = get_script().new()
	var first := First.new().restore_save(_prologue)
	if first != null:
		fresh.start_after(first)
	return fresh


func save_data() -> Dictionary:
	return {"version": SAVE_VERSION, "chapter": CONTENT_REVISION, "prologue": _prologue.duplicate(true), "events": _events.duplicate()}


func restore_save(data: Variant) -> RefCounted:
	if not data is Dictionary or data.size() != 4:
		return null
	if not save_header_error(data).is_empty():
		return null
	if not data.get("events") is Array or data["events"].size() > MAX_SAVE_EVENTS:
		return null
	var first := First.new().restore_save(data.get("prologue"))
	var restored: RefCounted = get_script().new()
	if not restored.start_after(first):
		return null
	for event: Variant in data["events"]:
		if not event is String or event.length() > 32:
			return null
		var accepted: bool = restored.advance() if event == "advance" else restored.act(StringName(event))
		if not accepted:
			return null
	return restored


static func save_header_error(data: Dictionary) -> String:
	if typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT] or not data.get("chapter") is String:
		return "invalid"
	if data["version"] != SAVE_VERSION or data["chapter"] != CONTENT_REVISION:
		return "version"
	if not data.get("prologue") is Dictionary:
		return "invalid"
	# An incompatible nested chapter is not corruption that may be overwritten or downgraded.
	return First.save_header_error(data["prologue"])
