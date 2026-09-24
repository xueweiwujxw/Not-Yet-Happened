extends RefCounted
## Presentation turns only. Original blocks still own save events and fact commitment.

const SPEAKERS := ["年幼的林澈", "年幼的栞", "林遥（笑）", "林澈", "林遥", "栞", "许岚", "沈琴", "周启明"]
const INLINE := {
	"栞看见桌上的旧照片：": ["栞看见桌上的旧照片。", "栞"],
	"许岚把碗放到栞面前：": ["许岚把碗放到栞面前。", "许岚"],
	"栞架好相机：": ["栞架好相机。", "栞"],
	"旧录音：雨打着铁皮。年幼的栞说：": ["旧录音里，雨打着铁皮。", "年幼的栞"],
}


static func voice_key(speaker: String, text: String) -> String:
	return (speaker + "\n" + text).sha256_text()


static func split(block: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw: String in block.split("\n", false):
		var line := raw.strip_edges()
		var found := false
		for prefix: String in INLINE:
			if line.begins_with(prefix):
				result.append(beat("", INLINE[prefix][0]))
				result.append(beat(INLINE[prefix][1], line.trim_prefix(prefix)))
				found = true
				break
		if found:
			continue
		for name: String in SPEAKERS:
			if line.begins_with(name + "："):
				result.append(beat("林遥" if name == "林遥（笑）" else name, line.trim_prefix(name + "：")))
				found = true
				break
		if not found:
			result.append(beat("", line))
	return result


static func beat(speaker: String, text: String) -> Dictionary:
	return {"speaker": speaker, "text": text, "voice_key": voice_key(speaker, text) if not speaker.is_empty() else ""}
