extends Control
## 3D presentation of the same first-chapter session, not a parallel story implementation.

signal return_requested
signal continue_requested

const Room := preload("res://src/art/kitchen_room.gd")
const Art := preload("res://src/art/low_poly.gd")
const Appearance := preload("res://src/art/character_appearance.gd")
const Sound := preload("res://src/art/kitchen_audio.gd")
const PersonAnimator := preload("res://src/art/person_animator.gd")
const Spatial := preload("res://src/game/kitchen_interactions.gd")
const Controls := preload("res://src/game/kitchen_controls.gd")
const Content := preload("res://src/content/kitchen_visual.gd")
const Chapter := preload("res://src/content/chapter_one.gd")
const Motion := preload("res://src/game/character_motion.gd")
const Director := preload("res://src/art/scene_director.gd")
const Guide := preload("res://src/game/exploration_guide.gd")
const Voice := preload("res://src/art/dialogue_voice.gd")

var dialogue := preload("res://src/game/dialogue_cursor.gd").new()
var speaker_label: Label
var dialogue_count: Label

var preferences: RefCounted
var journey_continuation := false
var confirm_decisions := false
var continue_button: Button
var objective_label: Label
var hint_label: Label
var _pending_action: StringName = &""
var confirm_button: Button
var cancel_button: Button
var _selected_action := -1
var _target_labels: Array[Label] = []

var session: RefCounted
var room_script: GDScript = Room
var spatial_script: GDScript = Spatial
var action_labels: Dictionary = Chapter.LABELS
var scene_title: String = Content.SUBTITLE
var scene_label: Label
var zone_names: Dictionary = Content.ZONES
var completed_text: String = Content.DONE
var initial_audio_muted := false
var sound: Node
var voice: Node
var director := Director.new()
var motion_button: Button
var voice_button: Button
var replay_button: Button
var transition: ColorRect
var transition_tween: Tween
var mute_button: Button
var room: Node3D
var player: CharacterBody3D
var camera: Camera3D
var hud: Control
var next_button: Button
var back_button: Button
var story_label: Label
var zone_label: Label
var action_buttons: Dictionary = {}
var _visual: Node3D
var _actions: HFlowContainer
var _marker: MeshInstance3D
var _active_zone: StringName = &""
var _moving := false
var _walk_phase := 0.0
var _manual_camera := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sound = Sound.new()
	sound.muted = initial_audio_muted
	add_child(sound)
	voice = Voice.new()
	add_child(voice)
	if preferences != null:
		voice.set_muted(not preferences.voice_enabled)
		director.enabled = preferences.camera_enabled
	room = room_script.new()
	add_child(room)
	player = CharacterBody3D.new()
	player.position = Vector3(1.4, 0.08, 2.8)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.5
	shape.shape = capsule
	shape.position.y = 0.78
	player.add_child(shape)
	add_child(player)
	_visual = Art.person(player, Vector3.ZERO, "d49a70")
	Appearance.apply(_visual, &"lin_che")
	director.player_visual = _visual
	_marker = _build_interaction_marker()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.8
	add_child(camera)
	frame_camera(false)
	camera.make_current()
	transition = ColorRect.new()
	transition.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition.color = Color(0.12, 0.17, 0.18, 0)
	transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(transition)
	_build_hud()
	refresh()
	visibility_changed.connect(func() -> void:
		if not is_visible_in_tree():
			voice.stop()
		_update_replay()
	)


func _process(delta: float) -> void:
	if is_visible_in_tree() and not is_queued_for_deletion() and not _manual_camera:
		director.tick(camera, delta)
	_position_targets()


func fade_in() -> void:
	if transition_tween != null:
		transition_tween.kill()
	transition.color.a = 0.85 if director.enabled else 0.0
	transition_tween = create_tween()
	transition_tween.tween_property(transition, "color:a", 0.0, 0.65)


func frame_camera(detail: bool, gameplay: bool = true) -> void:
	_manual_camera = detail or not gameplay
	camera.position = Vector3(8, 7, 10) if detail else Vector3(11, 10, 14)
	camera.size = 7.8 if detail else 13.2 if gameplay else 12.2
	camera.v_offset = -0.85 if gameplay and not detail else 0.0
	camera.look_at(Vector3(0.3, 0.7, -0.4) if detail else Vector3(0, 0.6, 0))


func _physics_process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	var keyboard := Vector2.ZERO
	var stick := Vector2.ZERO
	if not session.speaking() and not get_viewport().gui_get_focus_owner() is LineEdit:
		keyboard.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		keyboard.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
		var joypads := Input.get_connected_joypads()
		if not joypads.is_empty():
			var device: int = joypads[0]
			stick = Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
	move_player(Controls.movement(keyboard, stick), delta)
	_refresh_zone()
	if _marker.visible:
		_marker.position.y = 0.12 + sin(Time.get_ticks_msec() * 0.005) * 0.035


func move_player(input: Vector2, delta: float) -> void:
	# Public deterministic input seam for movement/collision regression tests.
	var move := input.limit_length(1.0) if not session.speaking() else Vector2.ZERO
	var right := camera.global_basis.x
	var forward := camera.global_basis.z
	right.y = 0
	forward.y = 0
	var direction := (right.normalized() * move.x + forward.normalized() * move.y).limit_length(1.0)
	var speed := Motion.velocity(Vector2(player.velocity.x, player.velocity.z), Vector2(direction.x, direction.z), delta, session.speaking())
	player.velocity.x = speed.x
	player.velocity.z = speed.y
	player.velocity.y = maxf(player.velocity.y - 12.0 * delta, -20.0)
	var before := player.position
	player.move_and_slide()
	player.position = spatial_script.constrain(player.position)
	var travelled := Vector2(player.position.x - before.x, player.position.z - before.z).length()
	_moving = travelled > 0.0001
	if _moving:
		_visual.rotation.y = Motion.facing(_visual.rotation.y, Vector2(player.position.x - before.x, player.position.z - before.z) / maxf(delta, 0.001), delta)
		_walk_phase = fmod(_walk_phase + travelled * 7.0, TAU)
	PersonAnimator.blend(_visual, _walk_phase, minf(travelled / maxf(delta, 0.001) / Motion.SPEED, 1.0), delta)
	sound.travel(travelled, player.is_on_floor() and not session.speaking())


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or is_queued_for_deletion():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E, KEY_SPACE, KEY_ENTER:
				_trigger_primary_action()
				get_viewport().set_input_as_handled()
				return
			KEY_Q, KEY_F:
				_cycle_choice(-1 if event.physical_keycode == KEY_Q else 1)
				get_viewport().set_input_as_handled()
				return
	if event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		_cycle_choice(-1 if event.button_index == JOY_BUTTON_LEFT_SHOULDER else 1)
		get_viewport().set_input_as_handled()
		return
	# Reserve controller face buttons and Tab before GUI focus handling consumes them.
	var keyboard_back: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_TAB, KEY_ESCAPE]
	var gamepad_back: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B
	if keyboard_back or gamepad_back:
		return_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		_trigger_primary_action()
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y:
		_replay_voice()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or is_queued_for_deletion():
		return
	var keyboard_action: bool = event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E
	if keyboard_action:
		_trigger_primary_action()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_replay_voice()
		get_viewport().set_input_as_handled()


func _trigger_primary_action() -> void:
	if session.speaking():
		_continue_dialogue()
	elif not _pending_action.is_empty():
		_act(_pending_action)
	elif session.view()["completed"] and journey_continuation:
		continue_requested.emit()
	elif action_buttons.size() == 1:
		_act(action_buttons.keys()[0])
	elif not action_buttons.is_empty():
		if _selected_action < 0:
			_cycle_choice(1)
		else:
			_act(action_buttons.keys()[_selected_action])


func _build_interaction_marker() -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.42
	mesh.outer_radius = 0.52
	mesh.rings = 12
	mesh.ring_segments = 8
	var marker := MeshInstance3D.new()
	marker.mesh = mesh
	var marker_material := Art.material("f3bd62")
	marker_material.emission_enabled = true
	marker_material.emission = Color("c67b42")
	marker.material_override = marker_material
	marker.visible = false
	add_child(marker)
	return marker


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var title := _label(hud, Content.TITLE, 25)
	title.position = Vector2(32, 23)
	scene_label = _label(hud, scene_title, 16)
	scene_label.position = Vector2(33, 61)
	back_button = _button(hud, Content.BACK, func() -> void: return_requested.emit())
	back_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back_button.offset_left = -280
	back_button.offset_right = -28
	back_button.offset_top = 25
	back_button.offset_bottom = 65
	mute_button = _button(hud, "Audio: ON", _toggle_audio)
	mute_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mute_button.offset_left = -180
	mute_button.offset_right = -28
	mute_button.offset_top = 76
	mute_button.offset_bottom = 112
	motion_button = _button(hud, "", _toggle_camera)
	motion_button.text = "动态镜头：开" if director.enabled else "动态镜头：关"
	motion_button.position = Vector2(32, 90)
	voice_button = _button(hud, "", _toggle_voice)
	voice_button.text = "普通话试音：关" if voice.muted else "普通话试音：开"
	voice_button.tooltip_text = "普通话逐句试音，表演尚待试听确认。关闭不影响字幕、剧情和环境声。"
	voice_button.position = Vector2(185, 90)
	voice_button.visible = not voice.turn_clips.is_empty()
	objective_label = _label(hud, "", 18)
	objective_label.position = Vector2(32, 140)
	objective_label.size.x = 780
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_color_override("font_color", Color("fff3d5"))
	objective_label.add_theme_color_override("font_shadow_color", Color("172b32"))
	objective_label.add_theme_constant_override("shadow_outline_size", 5)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.offset_left = 28
	panel.offset_right = -28
	panel.offset_top = -206
	panel.offset_bottom = -22
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.925, 0.82, 0.96)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	hud.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	panel.add_child(column)
	zone_label = _label(column, Content.WANDER, 16)
	speaker_label = _label(column, "", 17)
	speaker_label.add_theme_color_override("font_color", Color("9b5d31"))
	story_label = _label(column, "", 21)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 12)
	row.add_theme_constant_override("v_separation", 8)
	column.add_child(row)
	next_button = _button(row, "继续（E / 空格 / A）", _continue_dialogue)
	confirm_button = _button(row, "确定（E / A）", func() -> void: _act(_pending_action))
	cancel_button = _button(row, "取消，继续探索（Q / LB）", _cancel_decision)
	confirm_button.hide()
	cancel_button.hide()
	continue_button = _button(row, "继续旅程（E / A）", func() -> void: continue_requested.emit())
	replay_button = _button(row, "重听这句话（R / Y）", _replay_voice)
	dialogue_count = _label(row, "", 14)
	_actions = HFlowContainer.new()
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_actions)
	hint_label = _label(column, Content.HELP, 14)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _label(parent: Node, text: String, size_px: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", Color("3a534f"))
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _continue_dialogue() -> void:
	if not session.speaking():
		return
	if dialogue.advance():
		voice.stop()
		_refresh_dialogue()
	else:
		_advance()


func _advance() -> void:
	# Commit one canonical block only after its final presentation turn.
	if session.advance():
		dialogue.present("", false)
		voice.stop()
	refresh()


func _replay_voice() -> void:
	if is_visible_in_tree() and not is_queued_for_deletion() and session.speaking():
		voice.replay()


func _update_replay() -> void:
	replay_button.visible = session.speaking() and voice.output.stream != null
	replay_button.disabled = not voice.can_replay()


func _toggle_audio() -> void:
	sound.set_muted(not sound.muted)
	mute_button.text = "Audio: OFF" if sound.muted else "Audio: ON"


func _act(action: StringName) -> void:
	var available: Dictionary = spatial_script.nearby(player.position, session)
	if action not in available.get("actions", []):
		return
	var warning := Guide.consequence(action, session.view()) if confirm_decisions else ""
	if not warning.is_empty() and _pending_action != action:
		_pending_action = action
		story_label.text = warning
		confirm_button.show()
		cancel_button.show()
		return
	_pending_action = &""
	if session.act(action):
		sound.cue()
	refresh()


func refresh() -> void:
	var state: Dictionary = session.view()
	_pending_action = &""
	confirm_button.hide()
	cancel_button.hide()
	scene_label.text = scene_title
	room.sync_state(state)
	director.stage(room, player, state["speaking"], state["line"])
	dialogue.present(state["line"], state["speaking"])
	story_label.text = state["line"] if state["speaking"] else completed_text if state["completed"] else Content.WANDER
	_refresh_dialogue()
	next_button.visible = state["speaking"]
	continue_button.visible = state["completed"] and journey_continuation
	objective_label.text = Guide.objective(state)
	_update_replay()
	_refresh_targets()
	_refresh_zone(true)


func _refresh_zone(force: bool = false) -> void:
	var nearby: Dictionary = spatial_script.nearby(player.position, session)
	var id: StringName = nearby.get("id", &"")
	if not force and id == _active_zone:
		return
	if id != _active_zone and not _pending_action.is_empty():
		_cancel_decision()
	_active_zone = id
	_selected_action = -1
	_marker.visible = not nearby.is_empty()
	if _marker.visible:
		var at: Vector2 = nearby["at"]
		_marker.position = Vector3(at.x, 0.12, at.y)
	for button: Button in action_buttons.values():
		button.queue_free()
	action_buttons.clear()
	zone_label.text = zone_names.get(id, scene_title)
	var actions: Array = nearby.get("actions", [])
	for index: int in range(actions.size()):
		var action: StringName = actions[index]
		action_buttons[action] = _button(_actions, action_labels[action], _act.bind(action))
	_update_choice_labels()


func _cycle_choice(step: int) -> void:
	if not _pending_action.is_empty():
		_cancel_decision()
		return
	if session.speaking() or action_buttons.is_empty():
		return
	_selected_action = (0 if step > 0 else action_buttons.size() - 1) if _selected_action < 0 else posmod(_selected_action + step, action_buttons.size())
	_update_choice_labels()


func _update_choice_labels() -> void:
	var index := 0
	for action: StringName in action_buttons:
		var selected := index == _selected_action or action_buttons.size() == 1
		action_buttons[action].text = ("▶ " if selected else "") + action_labels[action]
		index += 1
	if session.speaking():
		hint_label.text = "E / 空格 / A 继续对白 · R / Y 重听 · 不会自动跳过，按自己的速度阅读。"
	elif action_buttons.size() > 1:
		hint_label.text = "这里有多个选择：Q / F 或 LB / RB 切换 · E / A 确认 · 也可直接点击选项。"
	elif action_buttons.size() == 1:
		hint_label.text = "E / 空格 / A 调查 · WASD / 方向键 / 左摇杆移动 · Tab / B 打开笔记。"
	else:
		hint_label.text = "走向场景中标出的物件 · WASD / 方向键 / 左摇杆移动 · Tab / B 打开笔记。"


func _refresh_targets() -> void:
	for label: Label in _target_labels:
		label.free()
	_target_labels.clear()
	for zone: Dictionary in Guide.locations(spatial_script, session):
		var label := _label(hud, "◇ " + String(zone_names.get(zone["id"], action_labels[zone["actions"][0]])), 15)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color("fff3d5"))
		label.add_theme_color_override("font_shadow_color", Color("172b32"))
		label.add_theme_constant_override("shadow_outline_size", 5)
		label.set_meta("at", zone["at"])
		_target_labels.append(label)
	_position_targets()


func _position_targets() -> void:
	for label: Label in _target_labels:
		var at: Vector2 = label.get_meta("at")
		label.position = hud.get_global_transform_with_canvas().affine_inverse() * camera.unproject_position(Vector3(at.x, 0.7, at.y)) - Vector2(label.size.x * 0.5, 20)


func _toggle_voice() -> void:
	voice.set_muted(not voice.muted)
	voice_button.text = "普通话试音：关" if voice.muted else "普通话试音：开"
	if preferences != null:
		preferences.voice_enabled = not voice.muted
		_store_preferences()
	_update_replay()


func _toggle_camera() -> void:
	director.enabled = not director.enabled
	motion_button.text = "动态镜头：开" if director.enabled else "动态镜头：关"
	if preferences != null:
		preferences.camera_enabled = director.enabled
		_store_preferences()


func _store_preferences() -> void:
	if preferences.save_settings() != OK:
		hint_label.text = "设置已应用，但未能保存到磁盘。下次启动可能恢复默认值。"


func _cancel_decision() -> void:
	_pending_action = &""
	confirm_button.hide()
	cancel_button.hide()
	story_label.text = Content.WANDER


func _refresh_dialogue() -> void:
	var speaking: bool = session.speaking()
	var turn := dialogue.current()
	speaker_label.visible = speaking and not turn["speaker"].is_empty()
	speaker_label.text = turn["speaker"]
	dialogue_count.visible = speaking and dialogue.turns.size() > 1
	dialogue_count.text = "%d / %d" % [dialogue.index + 1, dialogue.turns.size()]
	if speaking:
		story_label.text = turn["text"]
	voice.present_turn(turn["speaker"] if speaking else "", turn["text"])
	_update_replay()
