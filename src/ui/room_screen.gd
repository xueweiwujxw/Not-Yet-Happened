extends Control

const Session := preload("res://src/game/room_session.gd")
const ENDINGS := {
	&"reunion": "The keeper opens the door. Shiori is beside him, wrapped in a dry coat.\nYou made room for a gentler history before looking.",
	&"safe-at-harbor": "The room is empty. A radio message confirms Shiori reached the harbor safely.\nAn empty room does not always mean a loss.",
	&"waiting-alone": "Shiori is waiting alone. You take her hand.\nShe is safe, but next time you need not leave that to chance.",
	&"left-in-storm": "Wet footprints lead out toward the sea. Shiori has left without an escort.\nYou cannot call someone into a history you have already fixed.",
	&"empty-room": "The room is empty. No one can account for Shiori in the storm.\nThe silence is now a fact, not a possibility.",
}

var session := Session.new()
var call_button: Button
var listen_button: Button
var open_button: Button
var restart_button: Button
var status_label: Label
var story_label: Label


func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var scroll := ScrollContainer.new()
	margin.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 18)
	scroll.add_child(column)
	_label(column, "NOT YET HAPPENED / The keeper's room", 30)
	_label(column, "A storm is coming. Shiori may be inside the keeper's room.\nGoal: make sure she is safe. You can telephone the keeper to arrange an escort.\nListening or opening the door advances time into the storm. After that, the telephone line is down.", 20)
	story_label = _label(column, "", 22)
	status_label = _label(column, "", 18)
	call_button = _button(column, "Telephone the keeper (before the storm)", _call)
	listen_button = _button(column, "Let time pass and listen at the door", _listen)
	open_button = _button(column, "Open the door — confirm this history", _open)
	restart_button = _button(column, "Start a new attempt", _restart)
	_refresh()
	call_button.grab_focus()


func _label(parent: Node, text_value: String, size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	parent.add_child(label)
	return label


func _button(parent: Node, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size.y = 44
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _call() -> void:
	session.call_rescue()
	_refresh()


func _listen() -> void:
	session.listen()
	_refresh()


func _open() -> void:
	session.open_door()
	_refresh()


func _restart() -> void:
	session = Session.new()
	_refresh()
	call_button.grab_focus()


func _refresh() -> void:
	var state := session.view()
	var ended: bool = state["phase"] == Session.Phase.RESOLVED
	call_button.disabled = state["phase"] != Session.Phase.PREPARATION or state["called"]
	listen_button.disabled = ended or state["listened"]
	open_button.disabled = ended
	if ended:
		story_label.text = ENDINGS.get(state["outcome"], "No compatible history remains.")
	elif state["listened"]:
		story_label.text = "Footsteps, beneath the rain. Someone was here.\nThat does not tell you whether Shiori is safe."
	elif state["called"]:
		story_label.text = "The keeper promises to escort Shiori before the storm.\nYou have changed the conditions, without looking inside."
	else:
		story_label.text = "Your hand rests on the door. There is still time to make a call."
	var facts: Dictionary = state["facts"]
	var lines: Array[String] = ["CONFIRMED"]
	lines.append("Escort arranged: %s" % ("yes" if state["called"] else "not yet" if state["phase"] == Session.Phase.PREPARATION else "no"))
	if facts.has(&"footsteps"):
		lines.append("Footsteps in this history: %s" % ("confirmed" if facts[&"footsteps"] else "none"))
	lines.append("Shiori's safety: %s" % ("confirmed safe" if facts.get(&"child_safe") == true else "not secured" if facts.has(&"child_safe") else "unconfirmed"))
	lines.append("History: %s" % ("fixed" if ended else "partially observed, not fixed" if state["listened"] else "not yet observed"))
	if state["phase"] != Session.Phase.PREPARATION:
		lines.append("Compatible histories (prototype diagnostic): %d" % state["remaining"])
	status_label.text = "\n".join(lines)
