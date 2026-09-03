extends Control

signal continue_story
signal session_replaced

const Session := preload("res://src/game/chapter_session.gd")
const Content := preload("res://src/content/chapter_one.gd")
const RoomScene := preload("res://scenes/room.tscn")
const SaveStore := preload("res://src/game/chapter_save_store.gd")
const Second := preload("res://src/game/chapter_two_session.gd")
const SecondContent := preload("res://src/content/chapter_two.gd")
const FinaleNavigation := preload("res://src/ui/finale_navigation.gd")
const FinaleContent := preload("res://src/content/finale_content.gd")
const KitchenView := preload("res://src/ui/kitchen_view.gd")
const KitchenContent := preload("res://src/content/kitchen_visual.gd")

var session: RefCounted = Session.new()
var save_store := SaveStore.new()
var second_store := SaveStore.new("user://chapter-two.json", Second)
var is_second := false
var finale_navigation: RefCounted
var finale_button: Button
var kitchen_button: Button
var kitchen_view: Control
var second_button: Button
var load_second_button: Button
var second_back_button: Button
var second_screen: Control
var save_button: Button
var load_button: Button
var save_status: Label
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
	if not is_second:
		kitchen_button = _button(column, KitchenContent.ENTRY, _show_kitchen)
	_label(column, SecondContent.CHAPTER_TITLE if is_second else Content.TITLE, 30)
	_label(column, Content.HELP, 16)
	_label(column, SecondContent.CHAPTER_OBJECTIVE if is_second else Content.OBJECTIVE, 20)
	lamp_label = _label(column, "", 18)
	story_label = _label(column, "", 24)
	story_label.custom_minimum_size.y = 120
	next_button = _button(column, Content.NEXT, _advance)
	var actions := HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 12)
	actions.add_theme_constant_override("v_separation", 10)
	column.add_child(actions)
	var order: Array[StringName] = SecondContent.ACTION_ORDER if is_second else Content.ORDER
	var labels: Dictionary = SecondContent.ACTION_LABELS if is_second else Content.LABELS
	for id: StringName in order:
		action_buttons[id] = _button(actions, labels[id], _act.bind(id))
	_label(column, Content.NOTEBOOK, 24)
	notebook_label = _label(column, "", 18)
	var save_actions := HFlowContainer.new()
	column.add_child(save_actions)
	save_button = _button(save_actions, Content.SAVE, _save)
	load_button = _button(save_actions, Content.LOAD, _load)
	save_status = _label(column, "", 18)
	restart_button = _button(column, SecondContent.RESET if is_second else Content.RESTART, _restart)
	if not is_second:
		second_button = _button(column, SecondContent.ENTRY, _enter_second)
		load_second_button = _button(column, SecondContent.LOAD_CHAPTER, _load_second)
		finale_navigation = FinaleNavigation.new()
		finale_navigation.configure(self, column)
	else:
		finale_button = _button(column, FinaleContent.ENTRY, func() -> void: continue_story.emit())
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
			_focus_action()


func _act(id: StringName) -> void:
	session.act(id)
	_refresh()
	if session.speaking():
		next_button.grab_focus()
		chapter_scroll.scroll_vertical = 0


func _restart() -> void:
	_clear_second()
	session = session.new_attempt() if is_second else Session.new()
	session_replaced.emit()
	save_status.text = Content.RESTART_INFO
	_refresh()
	next_button.grab_focus()
	chapter_scroll.scroll_vertical = 0


func _save() -> void:
	var result := save_store.save_session(session)
	save_status.text = Content.SAVE_OK if result["ok"] else Content.SAVE_ERRORS[result["error"]]


func _load() -> void:
	var result := save_store.load_session()
	if not result["ok"]:
		save_status.text = Content.SAVE_ERRORS[result["error"]]
		return
	session = result["session"]
	_clear_second()
	session_replaced.emit()
	_refresh()
	save_status.text = Content.LOAD_BACKUP if result["recovered"] else Content.LOAD_OK
	if session.speaking():
		next_button.grab_focus()
	elif session.view()["completed"]:
		restart_button.grab_focus()
	else:
		_focus_action()
	chapter_scroll.scroll_vertical = 0


func _refresh() -> void:
	var state: Dictionary = session.view()
	story_label.text = state["line"]
	lamp_label.text = state["lamp"]
	lamp_label.modulate = Color(1.0, 0.85, 0.55) if state["repaired"] else Color.WHITE
	next_button.disabled = not state["speaking"]
	for id: StringName in action_buttons:
		action_buttons[id].disabled = not session.can_act(id)
	if second_button != null:
		second_button.disabled = not state["completed"]
		second_button.text = SecondContent.RESUME if second_screen != null else SecondContent.ENTRY
	if finale_button != null:
		finale_button.disabled = not state["completed"]
	var confirmed: Array = state["confirmed"]
	var claims: Array = state["claims"]
	notebook_label.text = Content.CONFIRMED + "\n" + "\n".join(confirmed)
	notebook_label.text += "\n\n" + Content.CLAIMS + "\n"
	notebook_label.text += "\n".join(claims) if not claims.is_empty() else Content.EMPTY
	notebook_label.text += "\n\n" + Content.UNKNOWN


func _show_sandbox() -> void:
	if _sandbox == null:
		_sandbox = RoomScene.instantiate()
		_sandbox.offset_top = 56
		add_child(_sandbox)
		back_button = _button(self, SecondContent.RESUME if is_second else Content.BACK, _hide_sandbox)
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


func _focus_action() -> void:
	for button: Button in action_buttons.values():
		if not button.disabled:
			button.grab_focus()
			return


func _enter_second() -> void:
	if not session.view()["completed"]:
		return
	if second_screen == null:
		var next_session := Second.new()
		if not next_session.start_after(session):
			return
		_show_second(next_session)
	else:
		chapter_scroll.hide()
		second_screen.show()
		second_back_button.show()
		second_back_button.grab_focus()


func _show_second(next_session: RefCounted) -> void:
	_clear_second()
	second_screen = get_script().new()
	second_screen.is_second = true
	second_screen.session = next_session
	second_screen.save_store = second_store
	second_screen.continue_story.connect(finale_navigation.enter)
	second_screen.session_replaced.connect(finale_navigation.clear)
	second_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(second_screen)
	second_screen.offset_top = 56
	second_back_button = _button(self, SecondContent.RETURN, _return_first)
	second_back_button.position = Vector2(28, 0)
	chapter_scroll.hide()
	if next_session.speaking():
		second_screen.next_button.grab_focus()
	else:
		second_back_button.grab_focus()


func _load_second() -> void:
	var result := second_store.load_session()
	if not result["ok"]:
		save_status.text = Content.SAVE_ERRORS[result["error"]]
		return
	var next_session: RefCounted = result["session"]
	session = Session.new().restore_save(next_session.save_data()["prologue"])
	_show_second(next_session)
	_refresh()
	second_screen.save_status.text = Content.LOAD_BACKUP if result["recovered"] else Content.LOAD_OK


func _return_first() -> void:
	# A loaded second-chapter save may carry a different first-chapter attempt.
	session = Session.new().restore_save(second_screen.session.save_data()["prologue"])
	second_screen.hide()
	second_back_button.hide()
	chapter_scroll.show()
	_refresh()
	second_button.grab_focus()


func _clear_second() -> void:
	if finale_navigation != null:
		finale_navigation.clear()
	if second_screen != null:
		second_screen.free()
		second_screen = null
		second_back_button.free()
		second_back_button = null


func _show_kitchen() -> void:
	if kitchen_view != null:
		return
	kitchen_view = KitchenView.new()
	kitchen_view.session = session
	kitchen_view.theme = theme
	kitchen_view.return_requested.connect(_hide_kitchen)
	add_child(kitchen_view)
	chapter_scroll.hide()


func _hide_kitchen() -> void:
	# Rendering/movement never owns facts. Both interfaces have used the exact same session.
	kitchen_view.queue_free()
	kitchen_view = null
	chapter_scroll.show()
	_refresh()
	kitchen_button.grab_focus()
