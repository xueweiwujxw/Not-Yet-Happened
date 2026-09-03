extends SceneTree

const WorldStateTests := preload("res://tests/test_world_state.gd")
const ObservationTests := preload("res://tests/test_observation.gd")
const PossibilityTests := preload("res://tests/test_possibility.gd")
const CollapseResolverTests := preload("res://tests/test_collapse_resolver.gd")
const RoomSessionTests := preload("res://tests/test_room_session.gd")
const RoomScreenTests := preload("res://tests/test_room_screen.gd")
const ExportPresetTests := preload("res://tests/test_export_presets.gd")
const ChapterSessionTests := preload("res://tests/test_chapter_session.gd")
const ChapterScreenTests := preload("res://tests/test_chapter_screen.gd")
const ChapterSaveTests := preload("res://tests/test_chapter_saves.gd")
const ChapterTwoTests := preload("res://tests/test_chapter_two.gd")
const FinaleRulesTests := preload("res://tests/test_finale_rules.gd")
const FinaleSessionTests := preload("res://tests/test_finale_session.gd")
const FinaleScreenTests := preload("res://tests/test_finale_screen.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var suites: Array[GDScript] = [
		WorldStateTests,
		ObservationTests,
		PossibilityTests,
		CollapseResolverTests,
		RoomSessionTests,
		RoomScreenTests,
		ExportPresetTests,
		ChapterSessionTests,
		ChapterScreenTests,
		ChapterSaveTests,
		ChapterTwoTests,
		FinaleRulesTests,
		FinaleSessionTests,
		FinaleScreenTests,
	]
	for suite: GDScript in suites:
		if not suite.can_instantiate():
			printerr("Test suite failed to compile: %s" % suite.resource_path)
			quit(1)
			return

	var failures: Array[String] = []
	failures.append_array(WorldStateTests.new().run())
	failures.append_array(ObservationTests.new().run())
	failures.append_array(PossibilityTests.new().run())
	failures.append_array(CollapseResolverTests.new().run())
	failures.append_array(RoomSessionTests.new().run())
	failures.append_array(RoomScreenTests.new().run(root))
	failures.append_array(ExportPresetTests.new().run())
	failures.append_array(ChapterSessionTests.new().run())
	failures.append_array(await ChapterScreenTests.new().run(root))
	failures.append_array(ChapterSaveTests.new().run(root))
	failures.append_array(await ChapterTwoTests.new().run(root))
	failures.append_array(FinaleRulesTests.new().run())
	failures.append_array(FinaleSessionTests.new().run())
	failures.append_array(await FinaleScreenTests.new().run(root))

	if failures.is_empty():
		print("All tests passed.")
		quit(0)
		return

	printerr("Tests failed:")
	for failure in failures:
		printerr("- %s" % failure)
	quit(1)
