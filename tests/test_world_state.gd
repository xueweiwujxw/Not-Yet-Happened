extends RefCounted

const WorldStateScript := preload("res://src/core/world_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_confirms_new_fact(failures)
	_test_accepts_repeated_same_fact(failures)
	_test_rejects_conflicting_fact(failures)
	_test_snapshot_is_independent(failures)
	_test_mutable_fact_is_isolated(failures)
	return failures


func _test_confirms_new_fact(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	_expect(state.confirm_fact(&"sister_alive", false), "new fact should be accepted", failures)
	_expect(state.has_fact(&"sister_alive"), "confirmed fact should exist", failures)
	_expect(state.get_fact(&"sister_alive") == false, "confirmed value should be retrievable", failures)
	_expect(state.fact_count() == 1, "fact count should increase once", failures)


func _test_accepts_repeated_same_fact(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.confirm_fact(&"door_open", true)
	_expect(state.confirm_fact(&"door_open", true), "repeating the same fact should be valid", failures)
	_expect(state.fact_count() == 1, "repeating a fact should not duplicate it", failures)


func _test_rejects_conflicting_fact(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.confirm_fact(&"witness_present", true)
	_expect(not state.confirm_fact(&"witness_present", false), "conflicting fact should be rejected", failures)
	_expect(state.get_fact(&"witness_present") == true, "conflict must not rewrite confirmed history", failures)


func _test_snapshot_is_independent(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.confirm_fact(&"heard_gunshot", true)
	var copy := state.snapshot()
	copy[&"heard_gunshot"] = false
	_expect(state.get_fact(&"heard_gunshot") == true, "snapshot mutation must not affect world state", failures)


func _test_mutable_fact_is_isolated(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var source := {&"location": &"pier", &"clues": [&"red-shoe"]}
	state.confirm_fact(&"sister_state", source)
	source[&"location"] = &"station"
	(source[&"clues"] as Array).append(&"broken-camera")
	var retrieved: Dictionary = state.get_fact(&"sister_state")
	retrieved[&"location"] = &"school"
	(retrieved[&"clues"] as Array).clear()
	var stored: Dictionary = state.get_fact(&"sister_state")

	_expect(stored[&"location"] == &"pier", "fact should not retain mutable input references", failures)
	_expect(stored[&"clues"] == [&"red-shoe"], "retrieved fact mutation must not rewrite history", failures)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
