extends "res://src/ui/kitchen_view.gd"
## Reuses tested movement/HUD; chapter-specific rules remain in ChapterTwoSession.

const Second := preload("res://src/content/chapter_two.gd")
const SecondSession := preload("res://src/game/chapter_two_session.gd")


func _ready() -> void:
	room_script = preload("res://src/art/keeper_room.gd")
	spatial_script = preload("res://src/game/keeper_interactions.gd")
	action_labels = Second.ACTION_LABELS
	scene_title = Second.CHAPTER_TITLE
	completed_text = Second.END_TEXT
	initial_audio_muted = true
	zone_names = {&"telephone": Second.ACTION_LABELS[&"telephone"], &"tape": Second.ACTION_LABELS[&"tape"], &"door": Second.ACTION_LABELS[&"open"], &"exit": Second.ACTION_LABELS[&"leave"]}
	super._ready()
	# No invented audible footsteps beyond the door; chapter evidence remains textual.
	mute_button.hide()


func refresh() -> void:
	super.refresh()
	# Always expose time and consequence text, including pending dialogue.
	var historical: bool = session.view()["phase"] in [SecondSession.Phase.BEFORE_OUTAGE, SecondSession.Phase.AFTER_OUTAGE, SecondSession.Phase.OBSERVED]
	_visual.scale = Vector3.ONE * (0.7 if historical else 1.0)


func _refresh_zone(force: bool = false) -> void:
	super._refresh_zone(force)
	zone_label.text = session.view()["lamp"].split("\n")[0]
