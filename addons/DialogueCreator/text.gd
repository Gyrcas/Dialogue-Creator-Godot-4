@tool
extends TextEdit

const max_retry : int = 5

var default_size : Vector2 = size
var zoom : float = 1
var focused : bool = false

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

func _input(event : InputEvent):
	if focused && event is InputEventKey && event.is_pressed():
		match event.keycode:
			61:
				zoom += 0.05
				size = default_size * zoom
			45:
				zoom = zoom - 0.05 if zoom > 1 else 1
				size = default_size * zoom

func _on_focus_entered() -> void:
	size = default_size * zoom
	z_index = 100
	focused = true


func _on_focus_exited() -> void:
	size = default_size
	z_index = 0
	focused = false
