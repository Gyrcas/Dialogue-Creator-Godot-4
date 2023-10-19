@tool
extends TextEdit

const max_retry : int = 5

func _ready() -> void:
	connect("text_changed",_on_text_changed)

func _on_text_changed() -> void:
	get_node("../../").content = text

func set_content(retry : int = 0) -> void:
	retry += 1
	if not get_node("../../") is DialogueBox && retry < max_retry:
		set_content.call_deferred(retry)
		return
	if (text != get_node("../../").content || get_node("../../").content == "") && retry < max_retry:
		if get_tree():
			await get_tree().create_timer(0.1).timeout
		text = get_node("../../").content
		set_content.call_deferred(retry)
	
