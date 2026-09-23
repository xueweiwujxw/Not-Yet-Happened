extends "res://src/ui/chapter_screen.gd"
## Shipping entry point; the text notebook remains accessible inside the journey.

func _ready() -> void:
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	guided_play = true
	preferences = preload("res://src/game/play_preferences.gd").new()
	preferences.load_settings()
	super._ready()
	_show_kitchen()
