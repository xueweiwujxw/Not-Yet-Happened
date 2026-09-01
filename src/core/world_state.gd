class_name WorldState
extends RefCounted

const ObservationModel := preload("res://src/core/observation.gd")

enum ObservationResult {
	ACCEPTED,
	DUPLICATE,
	CONFLICT,
	INVALID,
}

var _facts: Dictionary = {}
var _observations: Dictionary = {}


func confirm_fact(key: StringName, value: Variant) -> bool:
	if _facts.has(key):
		return _facts[key] == value

	_facts[key] = _copy_fact_value(value)
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

	for key: StringName in constraints:
		_facts[key] = constraints[key]
	_observations[observation_id] = observation.duplicate_observation()
	return ObservationResult.ACCEPTED


func has_observation(observation_id: StringName) -> bool:
	return _observations.has(observation_id)


func observation_count() -> int:
	return _observations.size()
