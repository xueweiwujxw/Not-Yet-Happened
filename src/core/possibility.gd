class_name Possibility
extends RefCounted

var _id: StringName
var _facts: Dictionary


func _init(possibility_id: StringName, facts: Dictionary) -> void:
	_id = possibility_id
	_facts = facts.duplicate(true)


func possibility_id() -> StringName:
	return _id


func facts() -> Dictionary:
	return _facts.duplicate(true)


func is_valid() -> bool:
	if _id.is_empty() or _facts.is_empty():
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
	)


func duplicate_possibility() -> RefCounted:
	return get_script().new(_id, _facts)
