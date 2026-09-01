extends RefCounted

const ObservationScript := preload("res://src/core/observation.gd")
const PossibilityScript := preload("res://src/core/possibility.gd")
const WorldStateScript := preload("res://src/core/world_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_registers_possibilities(failures)
	_test_observation_filters_incompatible_possibilities(failures)
	_test_keeps_possibilities_with_unknown_facts(failures)
	_test_rejects_observation_that_eliminates_every_possibility(failures)
	_test_confirmed_fact_filters_possibilities(failures)
	_test_rejects_fact_that_eliminates_every_possibility(failures)
	_test_rejects_possibility_conflicting_with_history(failures)
	_test_copies_possibility_facts(failures)
	return failures


func _test_registers_possibilities(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var first := PossibilityScript.new(&"sister-at-pier", {&"sister_location": &"pier"})
	var second := PossibilityScript.new(&"sister-at-station", {&"sister_location": &"station"})

	_expect(state.add_possibility(first), "first possibility should be accepted", failures)
	_expect(state.add_possibility(second), "second possibility should be accepted", failures)
	_expect(state.possibility_count() == 2, "both possibilities should be retained", failures)
	var expected_ids: Array[StringName] = [&"sister-at-pier", &"sister-at-station"]
	_expect(
		state.possibility_ids() == expected_ids,
		"possibility ids should be deterministic",
		failures
	)


func _test_observation_filters_incompatible_possibilities(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"sister-alive", {&"sister_alive": true}))
	state.add_possibility(PossibilityScript.new(&"sister-dead", {&"sister_alive": false}))
	var observation := ObservationScript.new(&"kitchen-view", &"player", {&"sister_alive": true})

	_expect(
		state.apply_observation(observation) == WorldStateScript.ObservationResult.ACCEPTED,
		"compatible observation should be accepted",
		failures
	)
	_expect(state.has_possibility(&"sister-alive"), "matching possibility should remain", failures)
	_expect(not state.has_possibility(&"sister-dead"), "contradictory possibility should be removed", failures)
	_expect(state.get_fact(&"sister_alive") == true, "accepted observation should confirm its fact", failures)


func _test_keeps_possibilities_with_unknown_facts(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"unknown-shooter", {&"gunshot_heard": true}))
	state.add_possibility(PossibilityScript.new(&"sister-fired", {&"shooter": &"sister"}))
	var observation := ObservationScript.new(&"hallway-sound", &"player", {&"gunshot_heard": true})
	state.apply_observation(observation)

	_expect(state.possibility_count() == 2, "missing facts should remain undetermined, not contradictory", failures)


func _test_rejects_observation_that_eliminates_every_possibility(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"sister-at-pier", {&"sister_location": &"pier"}))
	state.add_possibility(PossibilityScript.new(&"sister-at-station", {&"sister_location": &"station"}))
	var impossible := ObservationScript.new(&"school-view", &"player", {&"sister_location": &"school"})

	_expect(
		state.apply_observation(impossible) == WorldStateScript.ObservationResult.CONFLICT,
		"observation eliminating every possibility should be rejected",
		failures
	)
	_expect(not state.has_fact(&"sister_location"), "rejected observation must not confirm a fact", failures)
	_expect(state.possibility_count() == 2, "rejected observation must not filter possibilities", failures)
	_expect(not state.has_observation(&"school-view"), "rejected observation must not be recorded", failures)


func _test_confirmed_fact_filters_possibilities(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"light-on", {&"light_on": true}))
	state.add_possibility(PossibilityScript.new(&"light-off", {&"light_on": false}))

	_expect(state.confirm_fact(&"light_on", true), "compatible fact should be confirmed", failures)
	_expect(state.has_possibility(&"light-on"), "fact should preserve its matching possibility", failures)
	_expect(not state.has_possibility(&"light-off"), "fact should remove its contradictory possibility", failures)


func _test_rejects_fact_that_eliminates_every_possibility(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"door-open", {&"door_open": true}))

	_expect(not state.confirm_fact(&"door_open", false), "impossible fact should be rejected", failures)
	_expect(not state.has_fact(&"door_open"), "rejected fact must not alter confirmed history", failures)
	_expect(state.has_possibility(&"door-open"), "rejected fact must not remove the last possibility", failures)


func _test_rejects_possibility_conflicting_with_history(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.confirm_fact(&"door_open", true)
	var conflicting := PossibilityScript.new(&"door-closed", {&"door_open": false})

	_expect(not state.add_possibility(conflicting), "possibility conflicting with history should be rejected", failures)
	_expect(state.possibility_count() == 0, "conflicting possibility should not be stored", failures)


func _test_copies_possibility_facts(failures: Array[String]) -> void:
	var source := {&"sister_location": &"pier"}
	var possibility := PossibilityScript.new(&"copied-world", source)
	source[&"sister_location"] = &"station"
	var state := WorldStateScript.new()
	state.add_possibility(possibility)
	var snapshot := state.possibility_facts(&"copied-world")
	snapshot[&"sister_location"] = &"school"

	_expect(
		state.possibility_facts(&"copied-world")[&"sister_location"] == &"pier",
		"possibility should isolate both input and returned facts",
		failures
	)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
