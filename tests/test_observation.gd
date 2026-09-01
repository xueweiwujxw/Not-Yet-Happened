extends RefCounted

const ObservationScript := preload("res://src/core/observation.gd")
const WorldStateScript := preload("res://src/core/world_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_applies_observation_constraints(failures)
	_test_rejects_conflicting_observation_atomically(failures)
	_test_treats_repeated_observation_as_duplicate(failures)
	_test_rejects_reused_observation_id(failures)
	_test_rejects_invalid_observation(failures)
	_test_copies_constraint_input(failures)
	return failures


func _test_applies_observation_constraints(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var observation := ObservationScript.new(
		&"hallway-glance-01",
		&"player",
		{&"sister_alive": true, &"sister_location": &"hallway"}
	)

	_expect(
		state.apply_observation(observation) == WorldStateScript.ObservationResult.ACCEPTED,
		"valid observation should be accepted",
		failures
	)
	_expect(state.get_fact(&"sister_alive") == true, "observation should confirm each constraint", failures)
	_expect(state.get_fact(&"sister_location") == &"hallway", "observation should confirm all constraints", failures)
	_expect(state.has_observation(&"hallway-glance-01"), "accepted observation should be recorded", failures)


func _test_rejects_conflicting_observation_atomically(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.confirm_fact(&"heard_gunshot", true)
	var observation := ObservationScript.new(
		&"camera-frame-02",
		&"camera-lobby",
		{&"heard_gunshot": false, &"witness_present": true}
	)

	_expect(
		state.apply_observation(observation) == WorldStateScript.ObservationResult.CONFLICT,
		"contradictory observation should be rejected",
		failures
	)
	_expect(not state.has_fact(&"witness_present"), "rejected observation must not apply partial constraints", failures)
	_expect(not state.has_observation(&"camera-frame-02"), "rejected observation must not be recorded", failures)


func _test_treats_repeated_observation_as_duplicate(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var first := ObservationScript.new(&"door-sound-03", &"player", {&"door_open": true})
	var repeated := ObservationScript.new(&"door-sound-03", &"player", {&"door_open": true})
	state.apply_observation(first)

	_expect(
		state.apply_observation(repeated) == WorldStateScript.ObservationResult.DUPLICATE,
		"equivalent observation should be idempotent",
		failures
	)
	_expect(state.observation_count() == 1, "duplicate observation should not be stored twice", failures)


func _test_rejects_reused_observation_id(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.apply_observation(ObservationScript.new(&"window-view-04", &"player", {&"light_on": true}))
	var changed := ObservationScript.new(&"window-view-04", &"player", {&"light_on": false})

	_expect(
		state.apply_observation(changed) == WorldStateScript.ObservationResult.CONFLICT,
		"observation id must not be reused for different contents",
		failures
	)
	_expect(state.get_fact(&"light_on") == true, "reused id must not rewrite confirmed history", failures)


func _test_rejects_invalid_observation(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var missing_constraints := ObservationScript.new(&"empty-05", &"player", {})

	_expect(
		state.apply_observation(missing_constraints) == WorldStateScript.ObservationResult.INVALID,
		"observation without constraints should be invalid",
		failures
	)
	_expect(state.observation_count() == 0, "invalid observation should not be recorded", failures)


func _test_copies_constraint_input(failures: Array[String]) -> void:
	var source := {&"person_location": &"pier"}
	var observation := ObservationScript.new(&"pier-view-06", &"player", source)
	source[&"person_location"] = &"station"
	var state := WorldStateScript.new()
	state.apply_observation(observation)

	_expect(state.get_fact(&"person_location") == &"pier", "observation should own a copy of its constraints", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
