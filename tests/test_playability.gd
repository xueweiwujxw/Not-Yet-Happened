extends RefCounted

const View := preload("res://src/ui/kitchen_view.gd")
const Session := preload("res://src/game/chapter_session.gd")
const Preferences := preload("res://src/game/play_preferences.gd")
const Guide := preload("res://src/game/exploration_guide.gd")
const Fixture := preload("res://tests/test_finale_view.gd")
const Keeper := preload("res://src/ui/keeper_view.gd")
const Screen := preload("res://src/ui/chapter_screen.gd")


func run(root: Window) -> Array[String]:
	var failures: Array[String] = []
	var settings := Preferences.new()
	settings.path = "user://test-play-preferences.cfg"
	if FileAccess.file_exists(settings.path):
		DirAccess.remove_absolute(settings.path)
	settings.load_settings()
	check(not settings.voice_enabled, "unreviewed auditions are opt-in", failures)
	settings.voice_enabled = true
	settings.camera_enabled = false
	check(settings.save_settings() == OK, "settings save", failures)
	var restored := Preferences.new()
	restored.path = settings.path
	restored.load_settings()
	check(restored.voice_enabled and not restored.camera_enabled, "settings survive recreation", failures)
	settings.voice_enabled = false
	var view := View.new()
	view.preferences = settings
	view.session = Session.new()
	root.add_child(view)
	view.set_physics_process(false)
	check(view.voice.muted and not view.director.enabled, "scene applies saved preferences", failures)
	Fixture.drain(view)
	check("照片" in view.objective_label.text and not view._target_labels.is_empty(), "exploration has an objective and visible destinations", failures)
	view.player.position = Vector3(3.95, 0.1, 1.6)
	view._refresh_zone(true)
	view._trigger_primary_action()
	Fixture.drain(view)
	view.player.position = Vector3(2.3, 0.1, -1.45)
	view._refresh_zone(true)
	var saved: Dictionary = view.session.save_data()
	view._trigger_primary_action()
	check(view.session.save_data() == saved and view._selected_action == 0, "multiple choices never silently execute the first option", failures)
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	pad.pressed = true
	view._input(pad)
	check(view._selected_action == 1, "shoulder button selects a different choice", failures)
	view._trigger_primary_action()
	check(view.session.save_data()["events"].back() == "eat", "confirmation executes selected alternative", failures)
	Fixture.drain(view)
	view.player.position = Vector3(0.65, 0.1, 0.1)
	view._refresh_zone(true)
	view._cycle_choice(-1)
	check(view._selected_action == view.action_buttons.size() - 1, "backward selection wraps", failures)
	view.player.position = Vector3(0, 0.1, 3.3)
	view._refresh_zone()
	check(view._selected_action == -1, "walking away clears selection", failures)
	view.voice_button.pressed.emit()
	restored.load_settings()
	check(restored.voice_enabled, "voice toggle persists independently of story saves", failures)
	view.free()

	var keeper := Keeper.new()
	keeper.session = preload("res://tests/test_finale_session.gd").new().previous()
	keeper.preferences = settings
	keeper.confirm_decisions = true
	root.add_child(keeper)
	keeper.set_physics_process(false)
	# preload("res://tests/test_finale_session.gd").new().previous() has completed its chapter; use a fresh attempt for warnings.
	keeper.session = keeper.session.new_attempt()
	Fixture.drain(keeper)
	for action: StringName in [&"telephone", &"tape", &"enter"]:
		keeper.session.act(action)
		Fixture.drain(keeper)
	keeper.player.position = Vector3(2.5, 0.1, -1.6)
	keeper.refresh()
	saved = keeper.session.save_data()
	keeper._act(&"listen")
	check(keeper.session.save_data() == saved and keeper.confirm_button.visible, "consequence warning precedes irreversible input", failures)
	keeper._cycle_choice(-1)
	check(keeper.session.save_data() == saved and not keeper.confirm_button.visible, "cancel preserves phone window", failures)
	keeper._act(&"listen")
	keeper._trigger_primary_action()
	check(keeper.session.save_data()["events"].back() == "listen", "explicit confirmation advances time", failures)
	Fixture.drain(keeper)
	check("电话已断" in keeper.objective_label.text, "guidance follows the closed phone window", failures)
	keeper.free()

	var screen := Screen.new()
	screen.guided_play = true
	screen.preferences = settings
	screen.session = preload("res://tests/test_chapter_two.gd").new()._first()
	root.add_child(screen)
	screen._show_kitchen()
	screen.kitchen_view._trigger_primary_action()
	check(screen.second_screen != null and screen.second_screen.kitchen_view != null, "chapter one continues directly into chapter two scenery", failures)
	check(screen.second_screen.preferences == settings, "preferences follow chapter transitions", failures)
	screen.second_screen.session = preload("res://tests/test_finale_session.gd").new().previous()
	screen.second_screen._hide_kitchen()
	screen.second_screen._show_kitchen()
	screen.second_screen.kitchen_view._trigger_primary_action()
	check(screen.finale_navigation.screen != null and screen.finale_navigation.screen.spatial_view != null, "chapter two continues directly into chapter three scenery", failures)
	screen.free()
	# Exercise the actual shipping subclass: child chapters must not create another entry point.
	var entry := preload("res://scenes/game.tscn").instantiate()
	root.add_child(entry)
	for source: String in ["res://src/game/exploration_guide.gd", "res://src/ui/kitchen_view.gd"]:
		var copy := FileAccess.get_file_as_string(source)
		for i: int in range(copy.length()):
			if copy.unicode_at(i) > 32 and not entry.theme.default_font.has_char(copy.unicode_at(i)):
				failures.append("Playability: missing bundled glyph " + copy[i])
				break
	check(entry.kitchen_view != null and not entry.chapter_scroll.visible, "shipping startup opens the scene", failures)
	entry._hide_kitchen()
	entry.session = preload("res://tests/test_chapter_two.gd").new()._first()
	entry._enter_second()
	check(entry.second_screen.get_script() == Screen and entry.second_screen.preferences == entry.preferences, "entry does not recursively bootstrap child chapters", failures)
	entry.free()
	root.content_scale_size = Vector2i.ZERO
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	DirAccess.remove_absolute(settings.path)
	await root.get_tree().create_timer(0.1).timeout
	return failures


func check(ok: bool, message: String, failures: Array[String]) -> void:
	if not ok:
		failures.append("Playability: " + message)
