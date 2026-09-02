extends RefCounted
## Authored content only. ChapterSession owns progression and facts.

const TITLE := "尚未发生 · 第一章：厨房的灯"
const HELP := "Tab 切换焦点 · Enter / 空格确认 · 对话结束后可自由调查"
const NEXT := "继续"
const RESTART := "重新开始本章（清空本次进度）"
const SANDBOX := "独立机制沙盒（不属于正式剧情）"
const BACK := "返回第一章"
const LICENSE := "字体许可（Noto Sans CJK / SIL OFL 1.1）"
const NOTEBOOK := "调查笔记"
const CONFIRMED := "已经确认"
const CLAIMS := "人物说法（未独立核实）"
const UNKNOWN := "仍未确定：姐姐事故后的去向。"
const EMPTY := "暂无新记录。"
const IDLE := "你站在老屋厨房。窗外有风，可以继续调查。"
const FINISHED := "第一章完成：和栞去旧值班室。\n第二章尚未实装。本章没有确认姐姐的生死。"
const OBJECTIVE := "找出姐姐留下的照片、录音和信件。"
const LAMP_ON := "灯已亮起，桌面暖了起来。"
const LAMP_OFF := "灯关着。"
const LAMP_BROKEN := "灯闪了一下，又暗了。"
const MISSING := "还不能离开："
const LABELS := {
	&"notice": "查看追思会通知",
	&"switch": "拨动灯开关",
	&"repair": "拧好松动的灯泡",
	&"recording": "播放可辨认的录音",
	&"photo": "查看旧照片的正反面",
	&"melted": "把化的那根冰棒给我",
	&"eat": "先别说话，快吃",
	&"portrait": "征求同意，给栞拍照",
	&"letter": "阅读沈琴送来的信",
	&"leave": "离开老屋",
}
const ORDER: Array[StringName] = [
	&"notice", &"switch", &"repair", &"recording", &"photo",
	&"melted", &"eat", &"portrait", &"letter", &"leave",
]
const REQUIREMENTS := {&"recording": "录音还没有听", &"photo": "旧照片还没有看", &"letter": "桌上的信还没有读"}
const FACT_NOTES := {
	&"children_survived": "来源：已知经历。林澈和栞从十四年前的事故中生还，如今均为二十四岁。",
	&"sister_missing": "来源：回乡背景。姐姐林遥十四年前失踪；失踪不等于死亡。",
	&"notice_text": "来源：通知。旧堤拆除前将举行最后一次集体追思会。",
	&"recording_words": "来源：录音。姐弟谈论这台录音机；后段无法辨认。",
	&"photo_front": "来源：旧照片正面。姐弟与栞在防波堤，栞穿着红鞋。",
	&"photo_back": "来源：旧照片背面。写着“开学前最后一个夏天”。",
	&"portrait": "来源：本次拍摄。栞同意留下吃冰棒时的照片。",
	&"letter_words": "来源：信件字句。姐姐写道开学前会想办法打电话；这不证明电话后来发生。",
}
const SHEN_CLAIM := "沈琴说：信是姐姐在事故前交给她的，姐姐当时说的是去上学。"
const LETTER := "阿澈：\n如果我走了，厨房的灯不要换，它只是接触不好。\n钱在饼干盒里，别一次买完冰棒。\n开学之前，我会想办法给你打电话。\n别把所有坏掉的东西都扔了。但也不是每一样，都要你修好。\n姐"
const RECORDING: Array[String] = [
	"年幼的林澈：这个可以录多久？",
	"林遥：录到你终于不问问题。",
	"年幼的林澈：那会不会不够？",
	"林遥（笑）：可能不够。",
	"风声盖住了后半段。你确认了听清的声音，没有填补缺失的内容。",
]
const ARRIVAL: Array[String] = [
	"敲门声响起。栞带着两根冰棒，坐到窗边的椅子上。",
	"栞：有一根化了。\n林澈：你拿来的时候就化了？\n栞：你开门太慢。",
	"门廊又传来敲门声。沈琴把一封没有寄件日期的信放在桌上。",
	"沈琴：应该早点给你的。\n林澈：什么时候寄来的？\n沈琴：不是寄来的。是她交给我的。",
	"林澈：那你为什么现在才给？\n沈琴：我以前总觉得，再等一等，就不用寄了。",
]
const LINES := {
	&"opening": ["钥匙碰撞的轻响。\n林澈：还是第二把。", "厨房的灯闪了一下。桌上有相框、一台录音机和追思会通知。"],
	&"notice": ["通知：旧防波堤拆除前，最后一次集体追思。\n这是一场追思会，不是一份死亡证明。"],
	&"unsafe_repair": ["灯泡旁贴着纸条：先关开关。\n林澈：你写这么大，是怕谁看不见。"],
	&"repair": ["你关着电，把松动的灯泡拧好。现在可以重新开灯。"],
	&"already_repaired": ["灯泡已经拧好了，不必再动它。"],
	&"photo_alone": ["旧照片里，你、姐姐和栞站在防波堤。栞穿着红鞋。", "背面写着：开学前最后一个夏天。\n林澈：我不记得拍过这张。"],
	&"photo_together": ["旧照片里，你、姐姐和栞站在防波堤。栞穿着红鞋。", "背面写着：开学前最后一个夏天。\n林澈：我不记得拍过这张。\n栞：你那天一直问，拍完能不能去买冰棒。"],
	&"photo_followup": ["栞看见桌上的旧照片：你那天一直问，拍完能不能去买冰棒。"],
	&"lamp_memory": ["栞指着灯泡旁的纸条：她以前把那张纸贴在你额头上过。"],
	&"melted": ["林澈：把化的那根给我。\n栞：你小时候可不这样。"],
	&"eat": ["林澈：那先别说话，快吃。\n栞坐下。两人安静了一会儿，窗外的风吹动纸条。"],
	&"portrait": ["林澈：拍一张？\n栞：现在？我嘴上都是。", "林澈：那等一下。\n栞：不用。就这样。", "你按下快门。这张照片会留下，不管以后怎样理解这个夏天。"],
	&"letter_end": ["林澈：她知道自己会出事？\n沈琴：她那天说的是去上学。", "你再次想起照片背面的“开学前”。原来姐姐也要开始自己的生活。"],
	&"letter_without_photo": ["林澈：她知道自己会出事？\n沈琴：她那天说的是去上学。", "原来姐姐也要开始自己的生活。桌上的旧照片，也许还留着那个夏天的线索。"],
	&"leave_repaired": ["栞：走之前关灯吗？\n林澈：关吧。回来还能打开。"],
	&"leave_repaired_off": ["栞：灯修好了？\n林澈：嗯。回来就能打开。"],
	&"leave_dark": ["栞：灯还是坏的。\n林澈：回来再修。"],
}


static func lines(id: StringName) -> Array[String]:
	var result: Array[String] = []
	result.assign(LINES.get(id, []))
	return result
