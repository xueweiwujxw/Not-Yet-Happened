extends RefCounted
## Preparation precedes the storm; observations never rewrite it.

const World := preload("res://src/core/world_state.gd")
const Candidate := preload("res://src/core/possibility.gd")
const ObservationModel := preload("res://src/core/observation.gd")
const Resolver := preload("res://src/core/collapse_resolver.gd")

enum Phase { PREPARATION, STORM, RESOLVED }

var _phase: Phase = Phase.PREPARATION
var _called: bool = false
var _world := World.new()
var _random := RandomNumberGenerator.new()


func _init(seed_value: int = 2026) -> void:
	_random.seed = seed_value


func call_rescue() -> bool:
	if _phase != Phase.PREPARATION or _called:
		return false
	_called = true
	return true


func listen() -> bool:
	if _phase == Phase.RESOLVED or _world.has_observation(&"storm-footsteps"):
		return false
	_begin_storm()
	# Authored sound fixes presence, not safety or identity of the footsteps.
	return _world.apply_observation(ObservationModel.new(
		&"storm-footsteps", &"player", {&"footsteps": true}
	)) == World.ObservationResult.ACCEPTED


func open_door() -> StringName:
	if _phase == Phase.RESOLVED:
		return _world.collapsed_possibility_id()
	_begin_storm()
	var result := Resolver.new().resolve(_world, _random)
	if not result.is_empty():
		_phase = Phase.RESOLVED
	return result


func view() -> Dictionary:
	return {
		"phase": _phase,
		"called": _called,
		"listened": _world.has_observation(&"storm-footsteps"),
		"facts": _world.snapshot(),
		"remaining": _world.possibility_count(),
		"outcome": _world.collapsed_possibility_id(),
	}


func _begin_storm() -> void:
	if _phase != Phase.PREPARATION:
		return
	_phase = Phase.STORM
	_world.confirm_fact(&"rescue_called_before_storm", _called)
	if _called:
		_add(&"reunion", true, true)
		_add(&"safe-at-harbor", true, false)
	else:
		_add(&"waiting-alone", true, true)
		_add(&"left-in-storm", false, true)
		_add(&"empty-room", false, false)


func _add(id: StringName, safe: bool, footsteps: bool) -> void:
	_world.add_possibility(Candidate.new(id, {
		&"child_safe": safe,
		&"footsteps": footsteps,
		&"rescue_called_before_storm": _called,
	}))
