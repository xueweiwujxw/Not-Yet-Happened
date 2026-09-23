extends RefCounted
## Hints project known progress only; they never pick a history or execute an action.

const Second := preload("res://src/game/chapter_two_session.gd")


static func objective(state: Dictionary) -> String:
	if state["completed"]:
		if state.get("chapter", 0) == 6:
			return "旅程结束 · 可打开笔记回顾并保存这次经历。"
		return "本章完成 · 继续旅程，或打开笔记保存。"
	if state.has("objective"):
		return state["objective"]
	if state.has("phase"):
		match state["phase"]:
			Second.Phase.BEFORE_OUTAGE:
				return "往事 · 电话仍可用。监听会推进时间，开门会固定经历。先决定是否拨号。"
			Second.Phase.AFTER_OUTAGE:
				return "往事 · 电话已断。走近值班室的门，决定是否开门确认。"
			Second.Phase.OBSERVED:
				return "门后的经历已固定 · 在门边选择回到现在。"
			Second.Phase.RETURNED:
				return "回到了现在 · 可重听录音，或从出口继续旅程。"
		return "先调查电话与录音，再到录音机旁选择重访往事。"
	var done: Dictionary = state["done"]
	var missing: Array[String] = []
	for entry: Array in [[&"recording", "餐桌上的录音"], [&"photo", "右侧的旧照片"], [&"letter", "餐桌上的信"]]:
		if not done.has(entry[0]):
			missing.append(entry[1])
	if missing.is_empty():
		return "线索已齐 · 可继续与栞交谈，或从左侧门廊离开。"
	return "寻找姐姐的线索：" + "、".join(missing) + ("。先看照片或听录音。" if not state["people_present"] else "。")


static func locations(spatial: GDScript, session: RefCounted) -> Array[Dictionary]:
	var state: Dictionary = session.view()
	var zones: Variant = spatial.ZONES
	if zones is Dictionary:
		zones = zones.get(state["chapter"], [])
	var result: Array[Dictionary] = []
	for zone: Dictionary in zones:
		var actions: Array[StringName] = []
		for action: StringName in zone["actions"]:
			if session.can_act(action):
				actions.append(action)
		if not actions.is_empty():
			result.append({"id": zone["id"], "at": zone["at"], "actions": actions})
	return result


static func consequence(action: StringName, state: Dictionary) -> String:
	if state.has("phase"):
		if action == &"listen":
			return "监听会让时间走到停电之后；还未拨出的电话将无法拨出。要继续监听吗？"
		if action == &"open":
			return "开门会确认门后的经历，结束这次可改变的时间窗口。要开门吗？"
	match action:
		&"confirm_platform": return "观察站台会固定这次经历。还想做准备的话，先取消并继续探索。现在观察吗？"
		&"leave_blank": return "你将保留这段空白并离开此次重访。确定继续吗？"
		&"play_anyway": return "栞已经拒绝播放。继续会越过她明确提出的边界。仍然播放吗？"
	return ""
