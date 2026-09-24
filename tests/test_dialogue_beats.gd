extends RefCounted

const Beats := preload("res://src/game/dialogue_beats.gd")
const Cursor := preload("res://src/game/dialogue_cursor.gd")
const View := preload("res://src/ui/kitchen_view.gd")
const First := preload("res://src/game/chapter_session.gd")
const Fixture := preload("res://tests/test_finale_view.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var source := "门响了。\n栞：有一根化了。\n林澈：你拿来的时候就化了？\n栞：你开门太慢。"
	var turns := Beats.split(source)
	check(turns.size() == 4 and turns[0]["speaker"].is_empty(), "narration is unvoiced", failures)
	check(turns[1]["speaker"] == "栞" and turns[1]["text"] == "有一根化了。", "names are metadata, not synthesized text", failures)
	check(Beats.voice_key("栞", "好。") != Beats.voice_key("林澈", "好。"), "identical words retain separate casting", failures)
	var embedded := Beats.split("许岚把碗放到栞面前：栞，明天想吃什么？")
	check(embedded.size() == 2 and embedded[1]["speaker"] == "许岚", "embedded stage direction is separated", failures)
	check(Beats.split("通知：明天开会。")[0]["speaker"].is_empty(), "documents are not guessed to be dialogue", failures)
	check(Beats.split("林遥（笑）：可能不够。")[0]["speaker"] == "林遥", "acting direction is not read as a name", failures)
	var cursor := Cursor.new()
	cursor.present(source, true)
	cursor.advance()
	cursor.present(source, true)
	check(cursor.index == 1, "refresh preserves turn", failures)
	cursor.present(source, false)
	check(cursor.turns.is_empty(), "end clears presentation", failures)

	var view := View.new()
	view.session = First.new()
	root.add_child(view)
	view.set_process(false)
	view.set_physics_process(false)
	var before: Dictionary = view.session.save_data()
	check(view.speaker_label.text.is_empty() and view.voice.current_key.is_empty(), "opening narration cannot play the actor early", failures)
	view._trigger_primary_action()
	check(view.speaker_label.text == "林澈" and view.story_label.text == "还是第二把。", "primary input advances one speaker turn", failures)
	check(view.session.save_data() == before, "turn does not consume an observation event", failures)
	check(view.voice.current_key == Beats.voice_key("林澈", "还是第二把。"), "audio matches displayed speaker and text", failures)
	var pending: Dictionary = view.session.save_data()
	view._replay_voice()
	check(view.session.save_data() == pending and view.dialogue.index == 1, "replay keeps reading position and facts", failures)
	view.next_button.pressed.emit()
	check(view.session.save_data()["events"].size() == before["events"].size() + 1, "final turn commits exactly one original advance", failures)
	Fixture.drain(view)
	view.player.position = Vector3(3.95, 0.1, 1.6)
	view._act(&"photo")
	for i: int in range(30):
		if view.session.view()["line"] == First.Content.ARRIVAL[1]:
			break
		view._advance()
	check(view.session.view()["line"] == First.Content.ARRIVAL[1], "arrival fixture reached", failures)
	before = view.session.save_data()
	for name: String in ["栞", "林澈", "栞"]:
		check(view.speaker_label.text == name, "arrival speaker order: " + name, failures)
		if name != "栞" or view.dialogue.index == 0:
			view._trigger_primary_action()
	check(view.session.save_data() == before, "all arrival turns remain inside one canonical block", failures)
	view._trigger_primary_action()
	check(view.session.save_data()["events"].size() == before["events"].size() + 1, "last arrival turn advances once", failures)
	var saved: Dictionary = view.session.save_data()
	var restored: RefCounted = First.new().restore_save(saved)
	check(restored != null and restored.view() == view.session.view(), "existing replay save format is unchanged", failures)
	view.free()
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Dialogue beats: " + message)
