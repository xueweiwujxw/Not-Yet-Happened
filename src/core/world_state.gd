class_name WorldState
extends RefCounted

var _facts: Dictionary = {}


func confirm_fact(key: StringName, value: Variant) -> bool:
	if _facts.has(key):
		return _facts[key] == value

	_facts[key] = value
	return true


func has_fact(key: StringName) -> bool:
	return _facts.has(key)


func get_fact(key: StringName, default_value: Variant = null) -> Variant:
	return _facts.get(key, default_value)


func fact_count() -> int:
	return _facts.size()


func snapshot() -> Dictionary:
	return _facts.duplicate(true)
