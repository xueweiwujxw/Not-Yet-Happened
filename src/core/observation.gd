class_name Observation
extends RefCounted

var _id: StringName
var _observer_id: StringName
var _constraints: Dictionary


func _init(
	observation_id: StringName,
	observer_id: StringName,
	constraints: Dictionary
) -> void:
	_id = observation_id
	_observer_id = observer_id
	_constraints = constraints.duplicate(true)


func observation_id() -> StringName:
	return _id


func observer_id() -> StringName:
	return _observer_id


func constraints() -> Dictionary:
	return _constraints.duplicate(true)


func is_valid() -> bool:
	if _id.is_empty() or _observer_id.is_empty() or _constraints.is_empty():
		return false

	for key: Variant in _constraints:
		if not key is StringName or (key as StringName).is_empty():
			return false

	return true


func is_equivalent_to(other: Variant) -> bool:
	return (
		other is RefCounted
		and other.get_script() == get_script()
		and _id == other._id
		and _observer_id == other._observer_id
		and _constraints == other._constraints
	)


func duplicate_observation() -> RefCounted:
	return get_script().new(_id, _observer_id, _constraints)
