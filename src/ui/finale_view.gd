extends "res://src/ui/kitchen_view.gd"
## One live session through four sets. Entering/leaving 3D never replays narrative input.

const Sets := {
	3: preload("res://src/art/photo_studio.gd"),
	4: preload("res://src/art/breakwater.gd"),
	5: preload("res://src/art/evening_store.gd"),
	6: preload("res://src/art/farewell_station.gd"),
}
const ArcContent := preload("res://src/content/finale_content.gd")
var shown_chapter := 0


func _ready() -> void:
	shown_chapter = session.view()["chapter"]
	room_script = Sets[shown_chapter]
	spatial_script = preload("res://src/game/finale_interactions.gd")
	initial_audio_muted = true
	completed_text = ArcContent.FINISHED
	super._ready()
	mute_button.hide()


func refresh() -> void:
	var state: Dictionary = session.view()
	if shown_chapter != state["chapter"]:
		shown_chapter = state["chapter"]
		room.free()
		room_script = Sets[shown_chapter]
		room = room_script.new()
		add_child(room)
		player.position = Vector3(1.4, 0.08, 2.8)
		player.velocity = Vector3.ZERO
		_active_zone = &""
		frame_camera(false)
		fade_in()
	action_labels = state["actions"]
	zone_names = action_labels
	scene_title = state["title"]
	var f: Dictionary = state["facts"]
	var historical: bool = shown_chapter == 4 and f.has(&"c4_entered") and not f.has(&"c4_closed")
	_visual.scale = Vector3.ONE * (0.7 if historical else 1.0)
	Appearance.set_present(_visual, not historical)
	super.refresh()
	if shown_chapter == 4 and not state["speaking"] and not f.has(&"c4_closed"):
		story_label.text = preload("res://src/content/chapter_four.gd").WARNING
	if state["completed"]:
		story_label.text = ArcContent.ENDING_LABEL + ArcContent.ENDINGS[f[&"ending_id"]] + "\n" + completed_text


func _refresh_zone(force: bool = false) -> void:
	super._refresh_zone(force)
	# Always expose the active time window. Full warnings and evidence remain in the notebook.
	if shown_chapter == 4:
		zone_label.text = session.view()["status"].split("\n")[0]
