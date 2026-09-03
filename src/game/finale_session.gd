extends RefCounted
## Chapters 3–6 share one sequential attempt. All saves replay validated input, including chapters 1–2.

const Previous := preload("res://src/game/chapter_two_session.gd")
const Rules := preload("res://src/game/finale_rules.gd")
const Content := preload("res://src/content/finale_content.gd")
const World := preload("res://src/core/world_state.gd")
const Candidate := preload("res://src/core/possibility.gd")
const ObservationModel := preload("res://src/core/observation.gd")
const SAVE_VERSION := 1
const CONTENT_REVISION := "summer-finale-v1"
const MAX_SAVE_EVENTS := 8192

var _world := World.new()
var _prologue: Dictionary = {}
var _chapter := 3
var _dialogue: Array[String] = []
var _cursor := 0
var _events: Array[String] = []
var _pending: Dictionary = {}
var _observation_id: StringName = &""
var _next_chapter := 3


func start_after(previous: Previous) -> bool:
	if not _prologue.is_empty() or previous == null:
		return false
	var checked := Previous.new().restore_save(previous.save_data())
	if checked == null or not checked.view()["completed"]:
		return false
	_prologue = checked.save_data()
	var facts: Dictionary = checked.view()["facts"]
	for key: StringName in facts:
		_world.confirm_fact(key, facts[key])
	# Four finite histories encode both preparations. No arbitrary rescue route or random fate.
	for light: bool in [false, true]:
		for ladder: bool in [false, true]:
			_world.add_possibility(Candidate.new(StringName("route-%s-%s" % [light, ladder]), {
				&"backup_connected": light, &"ladder_lowered": ladder,
				&"platform_route": "safe" if light and ladder else "fall",
				&"children_survived": true,
			}))
	_dialogue.assign(Rules.content(_chapter).OPENING)
	return true


func speaking() -> bool:
	return _cursor < _dialogue.size()


func can_act(action: StringName) -> bool:
	return not _prologue.is_empty() and not speaking() and not _world.has_fact(&"ending_id") and Rules.can_act(_chapter, action, _world.snapshot())


func act(action: StringName) -> bool:
	if not can_act(action):
		return false
	var outcome := Rules.outcome(_chapter, action, _world.snapshot())
	if outcome.is_empty():
		return false
	_pending = outcome["facts"]
	_next_chapter = outcome["next_chapter"]
	_observation_id = StringName("chapter-%d-%s" % [_chapter, action])
	_dialogue = outcome["lines"]
	_cursor = 0
	_events.append(String(action))
	return true


func advance() -> bool:
	if not speaking():
		return false
	if _cursor + 1 == _dialogue.size() and not _pending.is_empty():
		if _world.apply_observation(ObservationModel.new(_observation_id, &"lin-che", _pending)) != World.ObservationResult.ACCEPTED:
			return false
		_pending.clear()
	_events.append("advance")
	_cursor += 1
	if not speaking() and _next_chapter != _chapter:
		_chapter = _next_chapter
		_dialogue.assign(Rules.content(_chapter).OPENING)
		_cursor = 0
	return true


func view() -> Dictionary:
	var f := _world.snapshot()
	var notes: Array[String] = []
	for source: GDScript in [Previous.Content, Rules.Third, Rules.Fourth, Rules.Fifth, Rules.Sixth]:
		var entries: Dictionary = source.NOTES
		for key: StringName in entries:
			if f.has(key):
				notes.append(entries[key])
	# First-chapter photos and letter remain visible, not only retained in storage.
	for key: StringName in Previous.Content.FACT_NOTES:
		if f.has(key):
			notes.append(Previous.Content.FACT_NOTES[key])
	var claims: Array[String] = [Previous.Content.SHEN_CLAIM]
	if f.has(&"keeper_admission_words"):
		claims.append(Content.KEEPER_CLAIM)
	var source := Rules.content(_chapter)
	var status: String = source.PLACE
	if _chapter == 4 and f.has(&"c4_entered"):
		status = Rules.Fourth.CLOSED if f.has(&"c4_closed") else Rules.Fourth.BOARDING if f.has(&"c4_boarding") else Rules.Fourth.BEFORE
		status += "\n" + Rules.Fourth.WARNING
	status += "\n" + Content.PREPARATION % [_prepared(f, &"backup_connected"), _prepared(f, &"ladder_lowered")]
	status += "\n" + Content.ROUTE[f.get(&"platform_route", "blank")]
	status += "\n" + Content.FATE[f.get(&"sister_fate", "unconfirmed")]
	if f.has(&"shiori_boundary_respected"):
		status += "\n" + Content.RELATION[f[&"shiori_boundary_respected"]]
	if f.has(&"ending_id"):
		status += "\n" + Content.ENDING_LABEL + Content.ENDINGS[f[&"ending_id"]]
	return {
		"chapter": _chapter, "title": source.TITLE, "objective": source.OBJECTIVE,
		"status": status, "facts": f, "confirmed": notes, "claims": claims,
		"line": _dialogue[_cursor] if speaking() else Content.FINISHED if f.has(&"ending_id") else Content.IDLE,
		"speaking": speaking(), "completed": f.has(&"ending_id"),
		"actions": source.LABELS.duplicate(true), "candidates": _world.possibility_ids(),
	}


func _prepared(f: Dictionary, key: StringName) -> String:
	return Content.UNKNOWN if not f.has(key) else Content.DONE if f[key] else Content.NOT_DONE


func new_attempt() -> RefCounted:
	var fresh: RefCounted = get_script().new()
	var previous := Previous.new().restore_save(_prologue)
	if previous != null:
		fresh.start_after(previous)
	return fresh


func save_data() -> Dictionary:
	return {"version": SAVE_VERSION, "chapter": CONTENT_REVISION, "prologue": _prologue.duplicate(true), "events": _events.duplicate()}


func restore_save(data: Variant) -> RefCounted:
	if not data is Dictionary or data.size() != 4 or not save_header_error(data).is_empty():
		return null
	if not data.get("events") is Array or data["events"].size() > MAX_SAVE_EVENTS:
		return null
	var previous := Previous.new().restore_save(data.get("prologue"))
	var restored: RefCounted = get_script().new()
	if not restored.start_after(previous):
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
	return Previous.save_header_error(data["prologue"])
