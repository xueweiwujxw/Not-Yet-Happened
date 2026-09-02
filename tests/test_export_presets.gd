extends RefCounted


func run() -> Array[String]:
	var failures: Array[String] = []
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		return ["Export presets must load successfully"]
	var platforms := ["Linux", "Windows Desktop", "macOS"]
	var architectures := ["x86_64", "x86_64", "universal"]
	for index: int in range(3):
		var section := "preset.%d" % index
		if config.get_value(section, "platform", "") != platforms[index]:
			failures.append("Missing export platform: " + platforms[index])
		if config.get_value(section + ".options", "binary_format/architecture", "") != architectures[index]:
			failures.append("Incorrect architecture: " + platforms[index])
		if not String(config.get_value(section, "export_path", "")).begins_with("build/"):
			failures.append("Exports must stay in ignored build directory")
		if "tests/*" not in String(config.get_value(section, "exclude_filter", "")):
			failures.append("Development tests must not ship in exports")
		if "assets/fonts/*.txt" not in String(config.get_value(section, "include_filter", "")):
			failures.append("Every export must include the bundled font license")
	if config.get_value("preset.1.options", "debug/export_console_wrapper", 0) != 2:
		failures.append("Windows release needs console wrapper for CI smoke test")
	if config.get_value("preset.2.options", "application/bundle_identifier", "") != "org.notyethappened.prototype":
		failures.append("macOS bundle must retain its application identifier")
	if not ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false):
		failures.append("Universal macOS export requires project ETC2/ASTC import")
	return failures
