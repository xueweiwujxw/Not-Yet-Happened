extends RefCounted
## Local reading position is not an observation. Leaving/reloading restarts the current block.

const Beats := preload("res://src/game/dialogue_beats.gd")
var block := ""
var turns: Array[Dictionary] = []
var index := 0


func present(text: String, speaking: bool) -> void:
	var next := text if speaking else ""
	if next == block:
		return
	block = next
	turns = Beats.split(block)
	index = 0


func current() -> Dictionary:
	return turns[index] if not turns.is_empty() else Beats.beat("", "")


func advance() -> bool:
	if index + 1 >= turns.size():
		return false
	index += 1
	return true
