extends Control

const Session := preload("res://src/game/chapter_session.gd")
const Content := preload("res://src/content/chapter_one.gd")
const RoomScene := preload("res://scenes/room.tscn")

var session := Session.new()
var action_buttons: Dictionary = {}
var next_button: Button
var restart_button: Button
var sandbox_button: Button
var back_button: Button
var story_label: Label
var notebook_label: Label
var lamp_label: Label
var chapter_scroll: ScrollContainer
var _sandbox: Control


func _ready() -> void:
	var font := FontFile.new()
	if FileAccess.file_exists("res://assets/fonts/ChapterSans.otf"):
		var error := font.load_dynamic_font("res://assets/fonts/ChapterSans.otf")
		if error != OK:
			push_error("Could not load bundled chapter font: %s" % error)
	else:
		font = load("res://assets/fonts/ChapterSans.otf") as FontFile
	theme = Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	chapter_scroll = ScrollContainer.new()
	chapter_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(chapter_scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	chapter_scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	_label(column, Content.TITLE, 30)
	_label(column, Content.HELP, 16)
	_label(column, Content.OBJECTIVE, 20)
	lamp_label = _label(column, "", 18)
	story_label = _label(column, "", 24)
	story_label.custom_minimum_size.y = 120
	next_button = _button(column, Content.NEXT, _advance)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 10)
	column.add_child(actions)
	for id: StringName in Content.ORDER:
		action_buttons[id] = _button(actions, Content.LABELS[id], _act.bind(id))
	_label(column, Content.NOTEBOOK, 24)
	notebook_label = _label(column, "", 18)
	restart_button = _button(column, Content.RESTART, _restart)
	sandbox_button = _button(column, Content.SANDBOX, _show_sandbox)
	var license_button := _button(column, Content.LICENSE, _show_license)
	license_button.tooltip_text = "SIL Open Font License 1.1"
	_refresh()
	next_button.grab_focus()


func _label(parent: Node, value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _advance() -> void:
	session.advance()
	_refresh()
	if not session.speaking():
		if session.view()["completed"]:
			restart_button.grab_focus()
		else:
			action_buttons[&"notice"].grab_focus()


func _act(id: StringName) -> void:
	session.act(id)
	_refresh()
	if session.speaking():
		next_button.grab_focus()
		chapter_scroll.scroll_vertical = 0


func _restart() -> void:
	session = Session.new()
	_refresh()
	next_button.grab_focus()
	chapter_scroll.scroll_vertical = 0


func _refresh() -> void:
	var state := session.view()
	story_label.text = state["line"]
	lamp_label.text = state["lamp"]
	lamp_label.modulate = Color(1.0, 0.85, 0.55) if state["repaired"] else Color.WHITE
	next_button.disabled = not state["speaking"]
	for id: StringName in action_buttons:
		action_buttons[id].disabled = not session.can_act(id)
	var confirmed: Array[String] = state["confirmed"]
	var claims: Array[String] = state["claims"]
	notebook_label.text = Content.CONFIRMED + "\n" + "\n".join(confirmed)
	notebook_label.text += "\n\n" + Content.CLAIMS + "\n"
	notebook_label.text += "\n".join(claims) if not claims.is_empty() else Content.EMPTY
	notebook_label.text += "\n\n" + Content.UNKNOWN


func _show_sandbox() -> void:
	if _sandbox == null:
		_sandbox = RoomScene.instantiate()
		_sandbox.offset_top = 56
		add_child(_sandbox)
		back_button = _button(self, Content.BACK, _hide_sandbox)
		back_button.position = Vector2(28, 0)
	chapter_scroll.hide()
	_sandbox.show()
	back_button.show()
	back_button.grab_focus()


func _hide_sandbox() -> void:
	_sandbox.hide()
	back_button.hide()
	chapter_scroll.show()
	sandbox_button.grab_focus()


func _show_license() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "SIL Open Font License 1.1"
	var text := RichTextLabel.new()
	text.custom_minimum_size = Vector2(280, 180)
	text.text = FileAccess.get_file_as_string("res://assets/fonts/OFL.txt")
	dialog.add_child(text)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)
