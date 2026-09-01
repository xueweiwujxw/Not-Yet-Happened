extends RefCounted

const CollapseResolverScript := preload("res://src/core/collapse_resolver.gd")
const PossibilityScript := preload("res://src/core/possibility.gd")
const WorldStateScript := preload("res://src/core/world_state.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	_test_rejects_invalid_weight(failures)
	_test_resolves_weighted_possibility(failures)
	_test_large_weights_do_not_overflow(failures)
	_test_same_seed_repeats_result(failures)
	_test_single_possibility_does_not_consume_randomness(failures)
	_test_collapse_anchors_selected_reality(failures)
	_test_rejects_unknown_possibility(failures)
	_test_repeated_resolution_is_stable(failures)
	_test_empty_world_does_not_collapse(failures)
	return failures


func _test_rejects_invalid_weight(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var facts := {&"sister_alive": true}

	_expect(not state.add_possibility(PossibilityScript.new(&"zero", facts, 0.0)), "zero weight should be rejected", failures)
	_expect(not state.add_possibility(PossibilityScript.new(&"negative", facts, -1.0)), "negative weight should be rejected", failures)
	_expect(not state.add_possibility(PossibilityScript.new(&"infinite", facts, INF)), "infinite weight should be rejected", failures)
	_expect(not state.add_possibility(PossibilityScript.new(&"not-a-number", facts, NAN)), "NaN weight should be rejected", failures)


func _test_resolves_weighted_possibility(failures: Array[String]) -> void:
	var state := _weighted_world()
	var resolver := CollapseResolverScript.new()
	var control := RandomNumberGenerator.new()
	control.seed = 42
	var target := control.randf() * 4.0
	var expected: StringName = &"sister-alive" if target < 1.0 else &"sister-missing"
	var random_source := RandomNumberGenerator.new()
	random_source.seed = 42

	_expect(
		resolver.resolve(state, random_source) == expected,
		"resolver should select from cumulative possibility weights",
		failures
	)


func _test_large_weights_do_not_overflow(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"first-world", {&"outcome": &"first"}, 1.0e308))
	state.add_possibility(PossibilityScript.new(&"second-world", {&"outcome": &"second"}, 1.0e308))
	var control := RandomNumberGenerator.new()
	control.seed = 314
	var expected: StringName = &"first-world" if control.randf() * 2.0 < 1.0 else &"second-world"
	var random_source := RandomNumberGenerator.new()
	random_source.seed = 314
	var resolver := CollapseResolverScript.new()

	_expect(
		resolver.resolve(state, random_source) == expected,
		"large finite weights should retain their relative probability",
		failures
	)


func _test_same_seed_repeats_result(failures: Array[String]) -> void:
	var first_state := _weighted_world()
	var second_state := _weighted_world()
	var first_random := RandomNumberGenerator.new()
	var second_random := RandomNumberGenerator.new()
	first_random.seed = 2026
	second_random.seed = 2026
	var resolver := CollapseResolverScript.new()

	_expect(
		resolver.resolve(first_state, first_random) == resolver.resolve(second_state, second_random),
		"same seed and candidates should produce the same collapse",
		failures
	)


func _test_single_possibility_does_not_consume_randomness(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"only-world", {&"sister_alive": true}))
	var random_source := RandomNumberGenerator.new()
	random_source.seed = 99
	var state_before := random_source.state
	var resolver := CollapseResolverScript.new()

	_expect(resolver.resolve(state, random_source) == &"only-world", "single possibility should collapse", failures)
	_expect(random_source.state == state_before, "single possibility should not consume randomness", failures)


func _test_collapse_anchors_selected_reality(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	state.add_possibility(
		PossibilityScript.new(
			&"kitchen-reunion",
			{&"sister_alive": true, &"sister_location": &"kitchen"}
		)
	)
	state.add_possibility(PossibilityScript.new(&"empty-house", {&"sister_alive": false}))

	_expect(state.collapse_to(&"kitchen-reunion"), "known possibility should collapse", failures)
	_expect(state.is_collapsed(), "world should report collapsed state", failures)
	_expect(state.collapsed_possibility_id() == &"kitchen-reunion", "selected id should be retained", failures)
	_expect(state.possibility_count() == 1, "collapse should discard every other possibility", failures)
	_expect(state.get_fact(&"sister_alive") == true, "collapse should anchor selected facts", failures)
	_expect(state.get_fact(&"sister_location") == &"kitchen", "collapse should anchor all selected facts", failures)
	_expect(
		not state.add_possibility(PossibilityScript.new(&"late-alternative", {&"sister_alive": false})),
		"collapsed world should reject alternative possibilities",
		failures
	)


func _test_rejects_unknown_possibility(failures: Array[String]) -> void:
	var state := _weighted_world()

	_expect(not state.collapse_to(&"unknown-world"), "unknown possibility should not collapse", failures)
	_expect(not state.is_collapsed(), "failed collapse should not alter world state", failures)
	_expect(state.possibility_count() == 2, "failed collapse should preserve candidates", failures)


func _test_repeated_resolution_is_stable(failures: Array[String]) -> void:
	var state := _weighted_world()
	var resolver := CollapseResolverScript.new()
	var random_source := RandomNumberGenerator.new()
	random_source.seed = 7
	var first := resolver.resolve(state, random_source)
	var random_state_after_first := random_source.state
	var second := resolver.resolve(state, random_source)

	_expect(second == first, "resolved world should return the same possibility", failures)
	_expect(random_source.state == random_state_after_first, "repeated resolution should not consume randomness", failures)


func _test_empty_world_does_not_collapse(failures: Array[String]) -> void:
	var state := WorldStateScript.new()
	var resolver := CollapseResolverScript.new()
	var random_source := RandomNumberGenerator.new()

	_expect(resolver.resolve(state, random_source).is_empty(), "empty world should not resolve", failures)
	_expect(not state.is_collapsed(), "empty world should remain uncollapsed", failures)


func _weighted_world() -> RefCounted:
	var state := WorldStateScript.new()
	state.add_possibility(PossibilityScript.new(&"sister-alive", {&"sister_alive": true}, 1.0))
	state.add_possibility(PossibilityScript.new(&"sister-missing", {&"sister_alive": false}, 3.0))
	return state


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
