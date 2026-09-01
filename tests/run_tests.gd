extends SceneTree

const WorldStateTests := preload("res://tests/test_world_state.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	failures.append_array(WorldStateTests.new().run())

	if failures.is_empty():
		print("All tests passed.")
		quit(0)
		return

	printerr("Tests failed:")
	for failure in failures:
		printerr("- %s" % failure)
	quit(1)
