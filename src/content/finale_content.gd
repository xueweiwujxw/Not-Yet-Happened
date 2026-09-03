extends RefCounted

const ENTRY := "继续第三至第六章"
const LOAD_ARC := "读取后续章节存档（替换本次进度）"
const BACK := "返回前两章记录"
const RESTART := "从第三章另开尝试（保留前两章）"
const FINISHED := "本次故事结束。可以保存这次记录，或明确另开一次尝试。"
const IDLE := "可以继续调查或作出选择。不可用的操作会显示为灰色。"
const PREPARATION := "准备状态：备用照明 %s；检修梯 %s。"
const DONE := "已完成"
const NOT_DONE := "未完成（已固定）"
const UNKNOWN := "尚未确定"
const FATE := {"alive": "姐姐生还已经核实。", "dead": "姐姐死亡已经核实。", "unconfirmed": "姐姐后续去向尚未确认。"}
const ROUTE := {"safe": "已观察：姐姐进入安全检修路。", "fall": "已观察：姐姐失足；后续仍需身份核实。", "blank": "平台经过未确认。"}
const RELATION := {true: "你尊重了栞对录音的拒绝。", false: "你无视了栞的拒绝，她不会参加告别合照。"}
const KEEPER_CLAIM := "周启明说：他当晚只到过入口，因为害怕，未继续检查。图上的巡查范围已另行记录。"
const ENDINGS := {"kitchen": "厨房的灯", "distance": "她的远方", "name": "把名字留下", "blank": "夏日留白"}
const ENDING_LABEL := "结局："
const CHAPTER_PROGRESS := "已完成章节："
