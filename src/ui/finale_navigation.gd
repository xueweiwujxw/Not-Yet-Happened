extends RefCounted
## Root-owned navigation: never let an earlier-chapter load retain dependent later history.

const Session := preload("res://src/game/finale_session.gd")
const Screen := preload("res://src/ui/finale_screen.gd")
const Store := preload("res://src/game/chapter_save_store.gd")
const First := preload("res://src/game/chapter_session.gd")
const Second := preload("res://src/game/chapter_two_session.gd")
const Content := preload("res://src/content/finale_content.gd")
const Common := preload("res://src/content/chapter_one.gd")

var owner_screen: Control
var screen: Control
var save_store := Store.new("user://story-finale.json", Session)
var load_button: Button


func configure(owner_view: Control, parent: Node) -> void:
	owner_screen = owner_view
	load_button = owner_screen._button(parent, Content.LOAD_ARC, load_arc)


func enter() -> void:
	if owner_screen.second_screen == null or not owner_screen.second_screen.session.view()["completed"]:
		return
	if screen == null:
		var session := Session.new()
		if not session.start_after(owner_screen.second_screen.session):
			return
		_create_screen(session)
	_show()


func load_arc() -> void:
	var result: Dictionary = save_store.load_session()
	if not result["ok"]:
		owner_screen.save_status.text = Common.SAVE_ERRORS[result["error"]]
		return
	var session: RefCounted = result["session"]
	var second := Second.new().restore_save(session.save_data()["prologue"])
	owner_screen._show_second(second) # Discards dependent live screens, not disk slots.
	owner_screen.session = First.new().restore_save(second.save_data()["prologue"])
	owner_screen._refresh()
	_create_screen(session)
	_show()
	screen.save_status.text = Common.LOAD_BACKUP if result["recovered"] else Common.LOAD_OK


func _create_screen(session: RefCounted) -> void:
	screen = Screen.new()
	screen.session = session
	screen.save_store = save_store
	screen.theme = owner_screen.theme
	screen.return_requested.connect(return_to_records)
	owner_screen.add_child(screen)


func _show() -> void:
	owner_screen.chapter_scroll.hide()
	owner_screen.second_screen.hide()
	owner_screen.second_back_button.hide()
	screen.show()
	screen.focus_progress()


func return_to_records() -> void:
	# Loading inside the arc can change both prior chapters. Restore the matching record.
	var second := Second.new().restore_save(screen.session.save_data()["prologue"])
	owner_screen.second_screen.session = second
	owner_screen.second_screen._refresh()
	owner_screen.session = First.new().restore_save(second.save_data()["prologue"])
	screen.hide()
	owner_screen.second_screen.show()
	owner_screen.second_back_button.show()
	owner_screen.second_screen.finale_button.grab_focus()


func clear() -> void:
	if screen != null:
		screen.free()
		screen = null
