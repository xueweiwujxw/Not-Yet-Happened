extends RefCounted

const Session := preload("res://src/game/chapter_session.gd")
const Content := preload("res://src/content/chapter_one.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	for order: Array in [
		[&"recording", &"photo", &"letter"], [&"recording", &"letter", &"photo"],
		[&"photo", &"recording", &"letter"], [&"photo", &"letter", &"recording"],
	]:
		var session := Session.new()
		_expect(not session.act(&"photo"), "block actions during dialogue", failures)
		_drain(session)
		_expect(not session.act(&"letter"), "letter cannot be read before arrival", failures)
		_expect(not session.act(&"portrait"), "portrait requires Shiori", failures)
		session.act(&"leave")
		_expect(Content.MISSING in session.view()["line"], "explain missing clues", failures)
		_drain(session)
		var story := ""
		for action: StringName in order:
			_expect(session.act(action), "legal investigation should work", failures)
			var passage := _drain(session)
			if action == &"letter" and not session.view()["done"].has(&"photo"):
				_expect(not "再次想起" in passage, "do not reference unseen photograph", failures)
			story += passage
		_expect(story.count("敲门声响起") == 1, "Shiori arrives exactly once", failures)
		_expect(story.count("沈琴把一封") == 1, "letter delivered exactly once", failures)
		var facts: Dictionary = session.view()["facts"]
		for action: StringName in [&"recording", &"photo", &"letter"]:
			session.act(action)
			var repeat := _drain(session)
			_expect(not "敲门声响起" in repeat, "repeat does not replay arrival", failures)
		_expect(session.view()["facts"] == facts, "repeated evidence is idempotent", failures)
		_expect(not facts.has(&"portrait"), "optional photograph may be skipped", failures)
		_expect(not facts.has(&"sister_dead"), "sister's fate remains unknown", failures)
		_expect(facts[&"children_survived"], "both children remain alive", failures)
		_expect(facts[&"letter_words"] == Content.LETTER, "letter words remain fixed", failures)
		_expect(session.view()["claims"] == [Content.SHEN_CLAIM], "testimony separate from facts", failures)
		_expect(not facts.has(&"letter_written_before_accident"), "do not promote testimony", failures)
		session.act(&"leave")
		_expect(not session.view()["completed"], "finish only after farewell", failures)
		_drain(session)
		_expect(session.view()["completed"], "optional lamp and portrait never block completion", failures)
		var final_state := session.view()
		_expect(not session.act(&"leave") and not session.advance(), "completion cannot repeat", failures)
		_expect(session.view() == final_state, "terminal state stable", failures)
	_test_optional_actions(failures)
	_test_evidence_waits_for_dialogue(failures)
	return failures


func _test_optional_actions(failures: Array[String]) -> void:
	var session := Session.new()
	_drain(session)
	session.act(&"repair")
	_drain(session)
	_expect(not session.view()["repaired"], "repair requires power off", failures)
	for action: StringName in [&"switch", &"repair", &"switch", &"photo"]:
		session.act(action)
		_drain(session)
	_expect(session.view()["lamp"] == Content.LAMP_ON, "repair restores light", failures)
	var before := session.view()
	_expect(not session.act(&"invalid"), "reject unknown action", failures)
	_expect(session.view() == before, "invalid action preserves state", failures)
	session.act(&"melted")
	_drain(session)
	_expect(not session.act(&"eat"), "ice cream choice only once", failures)
	session.act(&"portrait")
	_expect(not session.view()["facts"].has(&"portrait"), "do not record consent prematurely", failures)
	_drain(session)
	_expect(session.view()["facts"].has(&"portrait"), "record photo after consent and shutter", failures)
	_expect(not session.act(&"portrait"), "portrait occurs once", failures)
	session.act(&"notice")
	_drain(session)
	_expect(not session.view()["facts"].has(&"sister_dead"), "memorial is not death evidence", failures)
	var snapshot := session.view()
	snapshot["facts"][&"children_survived"] = false
	snapshot["done"].clear()
	snapshot["confirmed"].clear()
	_expect(session.view()["facts"][&"children_survived"], "snapshot cannot change history", failures)
	_expect(session.view()["done"].has(&"portrait"), "snapshot cannot change progress", failures)


func _test_evidence_waits_for_dialogue(failures: Array[String]) -> void:
	for action: StringName in [&"recording", &"photo", &"letter"]:
		var session := Session.new()
		_drain(session)
		if action == &"letter":
			session.act(&"recording")
			_drain(session)
		var before: Dictionary = session.view()["facts"]
		session.act(action)
		_expect(session.view()["facts"] == before, "evidence should not precede its dialogue", failures)
		if action == &"letter":
			_expect(session.view()["claims"].is_empty(), "testimony waits until heard", failures)
		_drain(session)
		_expect(session.view()["facts"].size() > before.size(), "finished investigation anchors evidence", failures)


func _drain(session: RefCounted) -> String:
	var lines: Array[String] = []
	for step: int in range(100):
		if not session.speaking():
			break
		lines.append(session.view()["line"])
		session.advance()
	return "\n".join(lines)


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("Chapter: " + message)
