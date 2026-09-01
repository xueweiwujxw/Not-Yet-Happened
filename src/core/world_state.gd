class_name WorldState
extends RefCounted

const ObservationModel := preload("res://src/core/observation.gd")
const PossibilityModel := preload("res://src/core/possibility.gd")

enum ObservationResult {
	ACCEPTED,
	DUPLICATE,
	CONFLICT,
	INVALID,
}

var _facts: Dictionary = {}
var _observations: Dictionary = {}
var _possibilities: Dictionary = {}


func confirm_fact(key: StringName, value: Variant) -> bool:
	if _facts.has(key):
		return _facts[key] == value

	var constraints := {key: value}
	if not _can_preserve_a_possibility(constraints):
		return false

	_facts[key] = _copy_fact_value(value)
	_filter_possibilities(constraints)
	return true


func has_fact(key: StringName) -> bool:
	return _facts.has(key)


func get_fact(key: StringName, default_value: Variant = null) -> Variant:
	if not _facts.has(key):
		return default_value
	return _copy_fact_value(_facts[key])


func fact_count() -> int:
	return _facts.size()


func snapshot() -> Dictionary:
	return _facts.duplicate(true)


func _copy_fact_value(value: Variant) -> Variant:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	if value is Array:
		return (value as Array).duplicate(true)
	return value


func apply_observation(observation: ObservationModel) -> ObservationResult:
	if observation == null or not observation.is_valid():
		return ObservationResult.INVALID

	var observation_id := observation.observation_id()
	if _observations.has(observation_id):
		var existing: ObservationModel = _observations[observation_id]
		if existing.is_equivalent_to(observation):
			return ObservationResult.DUPLICATE
		return ObservationResult.CONFLICT

	var constraints := observation.constraints()
	for key: StringName in constraints:
		if _facts.has(key) and _facts[key] != constraints[key]:
			return ObservationResult.CONFLICT
	if not _can_preserve_a_possibility(constraints):
		return ObservationResult.CONFLICT

	for key: StringName in constraints:
		_facts[key] = constraints[key]
	_filter_possibilities(constraints)
	_observations[observation_id] = observation.duplicate_observation()
	return ObservationResult.ACCEPTED


func has_observation(observation_id: StringName) -> bool:
	return _observations.has(observation_id)


func observation_count() -> int:
	return _observations.size()


func add_possibility(possibility: PossibilityModel) -> bool:
	if possibility == null or not possibility.is_valid():
		return false

	var possibility_id := possibility.possibility_id()
	if _possibilities.has(possibility_id):
		var existing: PossibilityModel = _possibilities[possibility_id]
		return existing.is_equivalent_to(possibility)

	if not possibility.matches_constraints(_facts):
		return false

	_possibilities[possibility_id] = possibility.duplicate_possibility()
	return true


func has_possibility(possibility_id: StringName) -> bool:
	return _possibilities.has(possibility_id)


func possibility_count() -> int:
	return _possibilities.size()


func possibility_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for possibility_id: StringName in _possibilities:
		ids.append(possibility_id)
	ids.sort_custom(_string_name_less_than)
	return ids


func possibility_facts(possibility_id: StringName) -> Dictionary:
	if not _possibilities.has(possibility_id):
		return {}
	var possibility: PossibilityModel = _possibilities[possibility_id]
	return possibility.facts()


func _can_preserve_a_possibility(constraints: Dictionary) -> bool:
	if _possibilities.is_empty():
		return true

	for possibility: PossibilityModel in _possibilities.values():
		if possibility.matches_constraints(constraints):
			return true
	return false


func _filter_possibilities(constraints: Dictionary) -> void:
	var rejected_ids: Array[StringName] = []
	for possibility_id: StringName in _possibilities:
		var possibility: PossibilityModel = _possibilities[possibility_id]
		if not possibility.matches_constraints(constraints):
			rejected_ids.append(possibility_id)

	for possibility_id: StringName in rejected_ids:
		_possibilities.erase(possibility_id)


func _string_name_less_than(left: StringName, right: StringName) -> bool:
	return String(left) < String(right)
