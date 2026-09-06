extends RefCounted
## Frame-rate-independent acceleration and bounded turns; dialogue stops immediately.

const SPEED := 2.5
const ACCELERATION := 7.0
const BRAKING := 10.0
const TURN_SPEED := 7.0


static func velocity(current: Vector2, direction: Vector2, delta: float, locked: bool) -> Vector2:
	if locked:
		return Vector2.ZERO
	var target := direction.limit_length(1.0) * SPEED
	return current.move_toward(target, (BRAKING if target.is_zero_approx() else ACCELERATION) * maxf(delta, 0.0))


static func facing(current: float, velocity_xz: Vector2, delta: float) -> float:
	if velocity_xz.length() < 0.03:
		return current
	return rotate_toward(current, atan2(velocity_xz.x, velocity_xz.y), TURN_SPEED * maxf(delta, 0.0))
