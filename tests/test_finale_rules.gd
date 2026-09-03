extends RefCounted

const Rules := preload("res://src/game/finale_rules.gd")
const Third := preload("res://src/content/chapter_three.gd")


func run() -> Array[String]:
	var failures: Array[String] = []
	for called: bool in [false, true]:
		for respect: bool in [false, true]:
			var facts: Dictionary = {&"children_survived": true}
			if called:
				facts[&"c2_cabinet_known"] = true
			_expect(not Rules.can_act(3, &"next", facts), "cannot bypass investigation", failures)
			for action: StringName in [&"report", &"patrol", &"equipment", &"diagram", &"admission", &"ask_audio"]:
				_expect(Rules.can_act(3, action, facts), "investigation is reachable", failures)
				facts.merge(Third.FACTS[action])
				_expect(not Rules.can_act(3, action, facts), "confirmed investigation cannot be redone", failures)
			var choice: StringName = &"respect" if respect else &"play_anyway"
			facts.merge(Third.FACTS[choice])
			_expect(not Rules.can_act(3, &"respect", facts) and not Rules.can_act(3, &"play_anyway", facts), "relationship choice immutable", failures)
			if not called:
				_expect(not Rules.can_act(3, &"next", facts), "missed call requires matching cabinet", failures)
				_expect(Rules.can_act(3, &"match_cabinet", facts), "missed call has information fallback", failures)
				facts.merge(Third.FACTS[&"match_cabinet"])
			_expect(Rules.can_act(3, &"next", facts), "forgiveness not a mainline requirement", failures)
			_expect(not facts.has(&"pier_empty") and not facts.has(&"sister_fate"), "records do not infer truth or death", failures)
	return failures


func _expect(value: bool, message: String, failures: Array[String]) -> void:
	if not value:
		failures.append("Finale rules: " + message)
