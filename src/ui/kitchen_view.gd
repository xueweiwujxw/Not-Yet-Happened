extends Control
## 3D presentation of the same first-chapter session, not a parallel story implementation.

signal return_requested

const Room := preload("res://src/art/kitchen_room.gd")
const Art := preload("res://src/art/low_poly.gd")
const Spatial := preload("res://src/game/kitchen_interactions.gd")
const Content := preload("res://src/content/kitchen_visual.gd")
const Chapter := preload("res://src/content/chapter_one.gd")

var session: RefCounted
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
var _active_zone: StringName = &""
var _moving := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room = Room.new()
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
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.8
	add_child(camera)
	frame_camera(false)
	camera.make_current()
	_build_hud()
	refresh()


func frame_camera(detail: bool, gameplay: bool = true) -> void:
	camera.position = Vector3(8, 7, 10) if detail else Vector3(11, 10, 14)
	camera.size = 7.8 if detail else 13.2 if gameplay else 12.2
	camera.v_offset = -0.85 if gameplay and not detail else 0.0
	camera.look_at(Vector3(0.3, 0.7, -0.4) if detail else Vector3(0, 0.6, 0))


func _physics_process(delta: float) -> void:
	if not visible:
		return
	var input := Vector2.ZERO
	if not session.speaking() and not get_viewport().gui_get_focus_owner() is LineEdit:
		input.x = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		input.y = float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	move_player(input, delta)
	_refresh_zone()


func move_player(input: Vector2, delta: float) -> void:
	# Public deterministic input seam for movement/collision regression tests.
	var move := input.limit_length(1.0) if not session.speaking() else Vector2.ZERO
	var right := camera.global_basis.x
	var forward := camera.global_basis.z
	right.y = 0
	forward.y = 0
	var direction := (right.normalized() * move.x + forward.normalized() * move.y).limit_length(1.0)
	player.velocity.x = direction.x * 2.5
	player.velocity.z = direction.z * 2.5
	player.velocity.y = maxf(player.velocity.y - 12.0 * delta, -20.0)
	player.move_and_slide()
	player.position = Spatial.constrain(player.position)
	_moving = direction.length_squared() > 0.01
	if _moving:
		_visual.rotation.y = atan2(direction.x, direction.z)


func _input(event: InputEvent) -> void:
	# Reserve the notebook shortcut before GUI focus traversal consumes Tab.
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_TAB:
		return_requested.emit()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_E:
		if session.speaking():
			_advance()
		elif not action_buttons.is_empty():
			_act(action_buttons.keys()[0])
		get_viewport().set_input_as_handled()


func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var title := _label(hud, Content.TITLE, 25)
	title.position = Vector2(32, 23)
	var subtitle := _label(hud, Content.SUBTITLE, 16)
	subtitle.position = Vector2(33, 61)
	back_button = _button(hud, Content.BACK, func() -> void: return_requested.emit())
	back_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	back_button.offset_left = -280
	back_button.offset_right = -28
	back_button.offset_top = 25
	back_button.offset_bottom = 65
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
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
	story_label = _label(column, "", 19)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var row := HBoxContainer.new()
	column.add_child(row)
	next_button = _button(row, Chapter.NEXT, _advance)
	_actions = HFlowContainer.new()
	_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_actions)
	_label(column, Content.HELP, 13)


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


func _advance() -> void:
	session.advance()
	refresh()


func _act(action: StringName) -> void:
	var available := Spatial.nearby(player.position, session)
	if action not in available.get("actions", []):
		return
	session.act(action)
	refresh()


func refresh() -> void:
	var state: Dictionary = session.view()
	room.sync_state(state)
	story_label.text = state["line"] if state["speaking"] else Content.DONE if state["completed"] else Content.WANDER
	next_button.visible = state["speaking"]
	_refresh_zone(true)


func _refresh_zone(force: bool = false) -> void:
	var nearby := Spatial.nearby(player.position, session)
	var id: StringName = nearby.get("id", &"")
	if not force and id == _active_zone:
		return
	_active_zone = id
	for button: Button in action_buttons.values():
		button.queue_free()
	action_buttons.clear()
	zone_label.text = Content.ZONES.get(id, Content.SUBTITLE)
	for action: StringName in nearby.get("actions", []):
		action_buttons[action] = _button(_actions, Chapter.LABELS[action], _act.bind(action))
