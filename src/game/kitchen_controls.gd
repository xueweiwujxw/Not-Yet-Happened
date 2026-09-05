extends RefCounted
## Deterministic keyboard/gamepad composition, separate from the live Input singleton.

const STICK_DEADZONE := 0.2


static func movement(keyboard: Vector2, stick: Vector2) -> Vector2:
	var filtered_stick := stick if stick.length() >= STICK_DEADZONE else Vector2.ZERO
	return (keyboard + filtered_stick).limit_length(1.0)
