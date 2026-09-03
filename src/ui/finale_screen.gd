extends Control
## Presentation for the sequential final arc; receives its session, store and font theme explicitly.

signal return_requested

const Common := preload("res://src/content/chapter_one.gd")
const Content := preload("res://src/content/finale_content.gd")

var session: RefCounted
var save_store: RefCounted
var scroll: ScrollContainer
var title_label: Label
var objective_label: Label
var status_label: Label
var story_label: Label
var notebook_label: Label
var save_status: Label
var next_button: Button
var save_button: Button
var load_button: Button
var restart_button: Button
var back_button: Button
var action_buttons: Dictionary = {}
var _actions: HFlowContainer
var _shown_chapter := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	scroll.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	title_label = _label(column, "", 30)
	_label(column, Common.HELP, 16)
	objective_label = _label(column, "", 20)
	status_label = _label(column, "", 18)
	story_label = _label(column, "", 24)
	story_label.custom_minimum_size.y = 120
	next_button = _button(column, Common.NEXT, _advance)
	_actions = HFlowContainer.new()
	_actions.add_theme_constant_override("h_separation", 12)
	_actions.add_theme_constant_override("v_separation", 10)
	column.add_child(_actions)
	notebook_label = _label(column, "", 18)
	save_button = _button(column, Common.SAVE, _save)
	load_button = _button(column, Common.LOAD, _load)
	save_status = _label(column, "", 18)
	restart_button = _button(column, Content.RESTART, _restart)
	back_button = _button(column, Content.BACK, func() -> void: return_requested.emit())
	refresh()
	focus_progress()


func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func refresh() -> void:
	var state: Dictionary = session.view()
	if _shown_chapter != state["chapter"]:
		for button: Button in action_buttons.values():
			button.free()
		action_buttons.clear()
		for id: StringName in state["actions"]:
			action_buttons[id] = _button(_actions, state["actions"][id], _act.bind(id))
		_shown_chapter = state["chapter"]
		scroll.scroll_vertical = 0
	title_label.text = state["title"]
	objective_label.text = state["objective"]
	status_label.text = state["status"]
	story_label.text = state["line"]
	next_button.disabled = not state["speaking"]
	for id: StringName in action_buttons:
		action_buttons[id].disabled = not session.can_act(id)
	notebook_label.text = Common.NOTEBOOK + "\n" + Common.CONFIRMED + "\n" + "\n".join(state["confirmed"])
	notebook_label.text += "\n\n" + Common.CLAIMS + "\n" + "\n".join(state["claims"])


func focus_progress() -> void:
	if session.speaking():
		next_button.grab_focus()
	elif session.view()["completed"]:
		save_button.grab_focus()
	else:
		for button: Button in action_buttons.values():
			if not button.disabled:
				button.grab_focus()
				return


func _act(id: StringName) -> void:
	session.act(id)
	refresh()
	focus_progress()
	scroll.scroll_vertical = 0


func _advance() -> void:
	session.advance()
	refresh()
	focus_progress()


func _save() -> void:
	var result: Dictionary = save_store.save_session(session)
	save_status.text = Common.SAVE_OK if result["ok"] else Common.SAVE_ERRORS[result["error"]]


func _load() -> void:
	var result: Dictionary = save_store.load_session()
	if not result["ok"]:
		save_status.text = Common.SAVE_ERRORS[result["error"]]
		return
	session = result["session"]
	refresh()
	focus_progress()
	scroll.scroll_vertical = 0
	save_status.text = Common.LOAD_BACKUP if result["recovered"] else Common.LOAD_OK


func _restart() -> void:
	session = session.new_attempt()
	refresh()
	focus_progress()
	scroll.scroll_vertical = 0
	save_status.text = Common.RESTART_INFO
