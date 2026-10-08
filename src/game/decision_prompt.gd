extends RefCounted
## Consequences shown before a player explicitly commits a choice.

static func text(action: StringName, state: Dictionary) -> String:
	match action:
		&"verify":
			return "核对将确认姐姐的生还或死亡，本轮不能撤销。确定要核对身份吗？"
		&"confirm_platform":
			return "确认平台会结束全部准备；灯和梯缺一将确认失足，但不确认死亡。确定现在观察吗？"
		&"boarding":
			return "进入上船前会结束接线窗口，之后不能补接备用灯。确定继续吗？" if not state["facts"].get(&"backup_connected", false) else ""
		&"leave_blank":
			return "结束本轮重访，保留平台未知；本轮不能再补做准备。确定结束吗？"
		&"seal":
			return "封存保留原始记录，但本轮不再核实身份。确定封存吗？"
		&"play_anyway":
			return "栞已拒绝重听；继续播放会侵犯她的边界，并影响告别。确定播放吗？"
	return ""
