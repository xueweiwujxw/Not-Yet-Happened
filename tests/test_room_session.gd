extends RefCounted

const Session := preload("res://src/game/room_session.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	var session := Session.new()
	_expect(session.view()["phase"] == Session.Phase.PREPARATION, "start in preparation", failures)
	_expect(session.view()["facts"].is_empty(), "do not preselect a history", failures)
	_expect(session.call_rescue(), "allow early rescue call", failures)
	_expect(not session.call_rescue(), "reject duplicate call", failures)
	_expect(session.listen(), "accept first listening observation", failures)
	_expect(session.view()["remaining"] == 1, "assisted footsteps leave reunion", failures)
	_expect(not session.view()["facts"].has(&"child_safe"), "partial observation does not reveal safety", failures)
	_expect(not session.listen(), "reject duplicate listening", failures)
	_expect(session.open_door() == &"reunion", "prepared observed route guarantees reunion", failures)
	_expect(session.view()["facts"][&"child_safe"] == true, "reunion anchors safety", failures)
	var snapshot := session.view()
	_expect(not session.call_rescue(), "no late intervention", failures)
	_expect(not session.listen(), "no observation after ending", failures)
	_expect(session.open_door() == &"reunion", "opening is idempotent", failures)
	_expect(session.view() == snapshot, "rejected actions preserve history", failures)
	snapshot["facts"][&"child_safe"] = false
	_expect(session.view()["facts"][&"child_safe"], "views cannot mutate history", failures)
	var unprepared := Session.new()
	unprepared.listen()
	_expect(not unprepared.call_rescue(), "listening closes preparation window", failures)
	_expect(unprepared.view()["remaining"] == 2, "footsteps remove only empty history", failures)
	_expect(not unprepared.view()["facts"].has(&"child_safe"), "footsteps do not imply safety", failures)
	var outcomes: Dictionary = {}
	for seed_value: int in range(128):
		for assisted: bool in [false, true]:
			var first := Session.new(seed_value)
			var second := Session.new(seed_value)
			if assisted:
				first.call_rescue()
				second.call_rescue()
			var outcome := first.open_door()
			outcomes[outcome] = true
			_expect(outcome == second.open_door(), "seeded attempts repeat", failures)
			_expect(not outcome.is_empty(), "every route resolves", failures)
			_expect(first.view()["remaining"] == 1, "opening fixes one history", failures)
			if assisted:
				_expect(first.view()["facts"][&"child_safe"], "rescue guarantees safety across seeds", failures)
	_expect(outcomes.size() == 5, "all five authored endings are reachable", failures)
	_test_action_sequences(failures)
	return failures


func _test_action_sequences(failures: Array[String]) -> void:
	# Exhaust all four-action sequences, including repeated and out-of-order input.
	for sequence: int in range(81):
		var session := Session.new(sequence)
		var encoded := sequence
		for step: int in range(4):
			var before := session.view()
			var accepted := false
			match encoded % 3:
				0:
					accepted = session.call_rescue()
				1:
					accepted = session.listen()
				2:
					accepted = not session.open_door().is_empty()
			encoded = floori(float(encoded) / 3.0)
			if not accepted or before["phase"] == Session.Phase.RESOLVED:
				_expect(session.view() == before, "invalid or terminal actions preserve state", failures)
			for key: Variant in before["facts"]:
				_expect(session.view()["facts"].get(key) == before["facts"][key], "action never rewrites a fact", failures)
		session.open_door()
		_expect(session.view()["phase"] == Session.Phase.RESOLVED, "every sequence can finish", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Room: " + message)
