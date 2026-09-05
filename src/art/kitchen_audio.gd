extends Node
## Original, deliberately quiet synthesized placeholders. Never receives narrative state.

const RATE := 22050
var ambience: AudioStreamPlayer
var effects: AudioStreamPlayer
var footsteps: AudioStreamPlayer
var muted := false
var distance := 0.0
var steps := 0


func _ready() -> void:
	ambience = _player(synthesize(true), -24.0)
	effects = _player(synthesize(false), -18.0)
	footsteps = _player(synthesize(false, 110.0), -22.0)
	ambience.play()


func _exit_tree() -> void:
	for item: AudioStreamPlayer in [ambience, effects, footsteps]:
		item.stop()
		item.stream = null


static func synthesize(loop: bool, frequency: float = 650.0) -> AudioStreamWAV:
	var count := RATE * 4 if loop else int(RATE * 0.12)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 419
	var smooth := 0.0
	for i: int in range(count):
		var t := float(i) / RATE
		var envelope := sin(PI * float(i) / float(count - 1))
		smooth = lerpf(smooth, rng.randf_range(-1.0, 1.0), 0.09)
		var value := smooth * envelope if loop else sin(TAU * frequency * t) * envelope * exp(-35.0 * t) * 0.5
		bytes.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = count
	return stream


func _player(stream: AudioStreamWAV, db: float) -> AudioStreamPlayer:
	var result := AudioStreamPlayer.new()
	result.stream = stream
	result.volume_db = db
	add_child(result)
	return result


func set_muted(value: bool) -> void:
	muted = value
	for item: AudioStreamPlayer in [ambience, effects, footsteps]:
		item.stream_paused = value
	# Short effects must not resume late after unmuting.
	if value:
		effects.stop()
		footsteps.stop()


func cue() -> void:
	if not muted:
		effects.play()


func travel(metres: float, grounded: bool) -> void:
	if not grounded or metres <= 0.0001:
		distance = 0.0
		return
	distance += minf(metres, 0.2)
	if distance >= 0.65:
		distance = fmod(distance, 0.65)
		steps += 1
		if not muted:
			footsteps.play()
