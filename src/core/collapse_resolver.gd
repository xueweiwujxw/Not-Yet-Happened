class_name CollapseResolver
extends RefCounted

const WorldStateModel := preload("res://src/core/world_state.gd")


func resolve(world_state: WorldStateModel, random_source: RandomNumberGenerator) -> StringName:
	if world_state == null or random_source == null:
		return &""
	if world_state.is_collapsed():
		return world_state.collapsed_possibility_id()

	var possibility_ids := world_state.possibility_ids()
	if possibility_ids.is_empty():
		return &""
	if possibility_ids.size() == 1:
		var only_id: StringName = possibility_ids[0]
		return only_id if world_state.collapse_to(only_id) else &""

	var maximum_weight := 0.0
	for possibility_id: StringName in possibility_ids:
		maximum_weight = maxf(maximum_weight, world_state.possibility_weight(possibility_id))

	var total_weight := 0.0
	for possibility_id: StringName in possibility_ids:
		total_weight += world_state.possibility_weight(possibility_id) / maximum_weight

	var target := random_source.randf() * total_weight
	var cumulative_weight := 0.0
	for possibility_id: StringName in possibility_ids:
		cumulative_weight += world_state.possibility_weight(possibility_id) / maximum_weight
		if target < cumulative_weight:
			return possibility_id if world_state.collapse_to(possibility_id) else &""

	var fallback_id: StringName = possibility_ids.back()
	return fallback_id if world_state.collapse_to(fallback_id) else &""
