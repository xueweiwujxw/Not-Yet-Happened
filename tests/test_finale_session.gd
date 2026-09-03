extends RefCounted

const First := preload("res://src/game/chapter_session.gd")
const Second := preload("res://src/game/chapter_two_session.gd")
const Session := preload("res://src/game/finale_session.gd")
const Rules := preload("res://src/game/finale_rules.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	for called: bool in [false, true]:
		for respect: bool in [false, true]:
			for light: bool in [false, true]:
				for ladder: bool in [false, true]:
					for resolution: String in ["verify", "seal", "blank"]:
						_test_route(called, respect, light, ladder, resolution, false, failures)
						if light and ladder and resolution == "verify":
							_test_route(called, respect, light, ladder, resolution, true, failures)
	_test_early_and_invalid(failures)
	return failures


func previous(called: bool = true) -> RefCounted:
	var first := First.new()
	drain(first)
	for action: StringName in [&"photo", &"portrait", &"recording", &"letter", &"leave"]:
		first.act(action)
		drain(first)
	var second := Second.new()
	second.start_after(first)
	drain(second)
	for action: StringName in [&"telephone", &"tape", &"enter"]:
		second.act(action)
		drain(second)
	if called:
		second.act(&"call")
		drain(second)
	for action: StringName in [&"listen", &"open", &"return", &"leave"]:
		second.act(action)
		drain(second)
	return second


func to_four(session: RefCounted, failures: Array[String]) -> void:
	for action: StringName in [&"admission", &"equipment", &"stretcher", &"report", &"patrol", &"diagram", &"ask_audio", &"respect"]:
		step(session, action, failures)
	if session.can_act(&"match_cabinet"):
		step(session, &"match_cabinet", failures)
	step(session, &"next", failures)


func _test_route(called: bool, respect: bool, light: bool, ladder: bool, resolution: String, invite: bool, failures: Array[String]) -> void:
	var prologue := previous(called)
	var session := Session.new()
	_expect(session.start_after(prologue), "completed second chapter starts arc", failures)
	check_drain(session, failures)
	var inherited: Dictionary = prologue.view()["facts"]
	for action: StringName in [&"report", &"patrol", &"equipment", &"diagram", &"admission", &"ask_audio"]:
		step(session, action, failures)
	step(session, &"respect" if respect else &"play_anyway", failures)
	step(session, &"forgive" if respect else &"withhold", failures)
	if not called:
		_expect(not session.can_act(&"next"), "missed phone needs matching cabinet", failures)
		step(session, &"match_cabinet", failures)
	_expect(not session.view()["facts"].has(&"pier_empty"), "report never becomes empty-pier fact", failures)
	step(session, &"next", failures)
	_expect(session.view()["chapter"] == 4, "third chapter transitions", failures)
	_expect(not session.act(&"lower_ladder"), "cannot prepare in present", failures)
	step(session, &"revisit", failures)
	_expect(not session.act(&"call"), "cannot change chapter-two call", failures)
	_expect(not session.act(&"lower_ladder"), "ladder only in boarding window", failures)
	if light:
		step(session, &"connect_light", failures)
	step(session, &"boarding", failures)
	_expect(not session.act(&"connect_light"), "cannot return to expired lighting window", failures)
	if ladder:
		step(session, &"lower_ladder", failures)
	step(session, &"leave_blank" if resolution == "blank" else &"confirm_platform", failures)
	_expect(not session.act(&"revisit") and not session.act(&"connect_light"), "closed window cannot reopen", failures)
	_expect(not session.view()["facts"].has(&"sister_fate"), "platform does not determine confirmed fate", failures)
	if resolution == "blank":
		_expect(not session.view()["facts"].has(&"platform_route"), "declining observation keeps route unknown", failures)
	else:
		_expect(session.view()["facts"][&"platform_route"] == ("safe" if light and ladder else "fall"), "exactly two safety conditions", failures)
	step(session, &"next", failures)
	step(session, &"records", failures)
	_expect(not session.view()["facts"].has(&"sister_fate"), "source inspection does not confirm identity", failures)
	_expect(not session.can_act(&"invite"), "invitation only after verified life", failures)
	if resolution == "blank":
		_expect(not session.can_act(&"verify"), "unknown platform cannot invent identity archive", failures)
	_expect(session.act(&"verify" if resolution == "verify" else &"seal"), "identity decision accepted", failures)
	_expect(not session.view()["facts"].has(&"sister_fate"), "unread identity evidence remains pending", failures)
	check_drain(session, failures)
	var fate: String = session.view()["facts"][&"sister_fate"]
	_expect(not session.can_act(&"verify") and not session.can_act(&"seal"), "identity choice permanent", failures)
	if fate == "alive":
		step(session, &"invite" if invite else &"no_invite", failures)
	else:
		_expect(not session.can_act(&"invite"), "no letter in death or unknown route", failures)
	step(session, &"dinner", failures)
	step(session, &"correction", failures)
	step(session, &"next", failures)
	_expect(not session.can_act(&"verify"), "no late fate changes in chapter six", failures)
	step(session, &"memorial", failures)
	step(session, &"portrait_join" if called else &"portrait_decline", failures)
	step(session, &"departure", failures)
	var result := session.view()
	_expect(result["completed"], "all routes terminate", failures)
	var expected := "blank" if fate == "unconfirmed" else "name" if fate == "dead" else "kitchen" if invite else "distance"
	_expect(result["facts"][&"ending_id"] == expected, "deterministic and exhaustive ending", failures)
	_expect(result["facts"][&"memorial_wording"] == Rules.Sixth.WORDING[fate], "memorial matches verified facts", failures)
	_expect(String(result["facts"][&"farewell_portrait"]).ends_with("together" if respect else "alone"), "boundary choice affects photo not fate", failures)
	for key: StringName in inherited:
		_expect(result["facts"][key] == inherited[key], "all earlier facts retained", failures)
	_expect(result["facts"].has(&"report_text") and result["facts"].has(&"report_correction"), "correction does not erase original", failures)
	_expect(not session.advance() and not session.act(&"departure"), "ending committed once", failures)
	var fresh := session.new_attempt()
	_expect(fresh.view()["facts"] == inherited and fresh.view()["chapter"] == 3, "new attempt retains only prior chapters", failures)


func _test_early_and_invalid(failures: Array[String]) -> void:
	var session := Session.new()
	_expect(not session.start_after(Second.new()), "unstarted prologue rejected", failures)
	_expect(session.restore_save(session.save_data()) == null, "unstarted save rejected", failures)
	session.start_after(previous())
	_expect(not session.start_after(previous(false)), "prologue cannot be swapped", failures)
	check_drain(session, failures)
	to_four(session, failures)
	step(session, &"revisit", failures)
	step(session, &"confirm_platform", failures)
	var facts: Dictionary = session.view()["facts"]
	_expect(facts[&"backup_connected"] == false and facts[&"ladder_lowered"] == false, "early confirmation fixes unperformed preparations", failures)
	_expect(facts[&"platform_route"] == "fall" and not facts.has(&"sister_fate"), "early observation fixes fall not death", failures)
	var cases: Array = [null, [], true, {}]
	for field: String in ["version", "chapter", "prologue", "events"]:
		for value: Variant in [null, true, {}, "bad"]:
			var data := session.save_data()
			data[field] = value
			cases.append(data)
	for event: Variant in ["departure", "verify", 1, {}, "x".repeat(33)]:
		var data := session.save_data()
		data["events"] = [event]
		cases.append(data)
	var oversized := session.save_data()
	oversized["events"].resize(Session.MAX_SAVE_EVENTS + 1)
	cases.append(oversized)
	var injected := session.save_data()
	injected["facts"] = {"sister_fate": "alive"}
	cases.append(injected)
	var before := session.view()
	for data: Variant in cases:
		_expect(session.restore_save(data) == null, "malformed input rejected", failures)
		_expect(session.view() == before, "rejected restore does not mutate live state", failures)
	var isolated := session.save_data()
	isolated["prologue"]["prologue"]["events"].clear()
	_expect(not session.save_data()["prologue"]["prologue"]["events"].is_empty(), "deep save snapshot isolated", failures)
	var blank: RefCounted = session.new_attempt()
	drain(blank)
	to_four(blank, failures)
	step(blank, &"revisit", failures)
	step(blank, &"leave_blank", failures)
	_expect(not blank.view()["facts"].has(&"backup_connected") and not blank.view()["facts"].has(&"ladder_lowered"), "early blank exit does not fabricate undone preparations", failures)
	_expect(not blank.view()["facts"].has(&"platform_route"), "early blank exit preserves all routes", failures)
	var fault: RefCounted = session.new_attempt()
	drain(fault)
	fault.act(&"report")
	fault.advance()
	fault._pending[&"children_survived"] = false
	var old_log: Dictionary = fault.save_data()
	_expect(not fault.advance(), "conflicting observation rejected", failures)
	_expect(fault.save_data() == old_log and not fault.view()["facts"].has(&"report_text"), "conflict atomic and does not consume line", failures)


func step(session: RefCounted, action: StringName, failures: Array[String]) -> void:
	_expect(session.act(action), "action accepted: " + action, failures)
	check_drain(session, failures)


func check_drain(session: RefCounted, failures: Array[String]) -> void:
	for count: int in range(128):
		var restored: RefCounted = session.restore_save(JSON.parse_string(JSON.stringify(session.save_data())))
		_expect(restored != null, "every dialogue line round-trips", failures)
		if restored != null:
			_expect(restored.view() == session.view(), "restores exact chapter, facts, pending line and candidates", failures)
		if not session.speaking():
			return
		if not session.advance():
			failures.append("Finale: unexpected observation conflict")
			return
	failures.append("Finale: dialogue did not terminate")


func drain(session: RefCounted) -> void:
	for count: int in range(128):
		if not session.speaking() or not session.advance():
			return


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Finale: " + message)
