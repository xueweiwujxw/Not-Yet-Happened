class_name Possibility
extends RefCounted

var _id: StringName
var _facts: Dictionary
var _weight: float


func _init(possibility_id: StringName, facts: Dictionary, weight: float = 1.0) -> void:
	_id = possibility_id
	_facts = facts.duplicate(true)
	_weight = weight


func possibility_id() -> StringName:
	return _id


func facts() -> Dictionary:
	return _facts.duplicate(true)


func weight() -> float:
	return _weight


func is_valid() -> bool:
	if _id.is_empty() or _facts.is_empty() or not is_finite(_weight) or _weight <= 0.0:
		return false

	for key: Variant in _facts:
		if not key is StringName or (key as StringName).is_empty():
			return false

	return true


func matches_constraints(constraints: Dictionary) -> bool:
	for key: Variant in constraints:
		if _facts.has(key) and _facts[key] != constraints[key]:
			return false
	return true


func is_equivalent_to(other: Variant) -> bool:
	return (
		other is RefCounted
		and other.get_script() == get_script()
		and _id == other._id
		and _facts == other._facts
		and _weight == other._weight
	)


func duplicate_possibility() -> RefCounted:
	return get_script().new(_id, _facts, _weight)
