@tool
extends Node
class_name DialoguePlayer

##Action used to progress the dialogue
@export var action_next : String = "ui_accept" : set = set_action_next

func set_action_next(value : String) -> void:
	action_next = value
	update_configuration_warnings()

##Parent node of button found in dialogue
@export var button_container : Node

##Node where the text will be displayed. Must contain a text variable
@export var text_node : Node

@export var use_typewritter : bool = true

@export var typewritter_speed : float = 0.1

@export var variables : Dictionary = {}

##Used by script to detect when user as pressed the action key to continue dialogue
signal confirm
##Emitted when dialogue is finished
signal finished

enum types {msg,script,choice,condition,move_to,placeholder,choice_option}

##Wether the typewritter is writing or not
var writing : bool = false

#Return dialogue if found, else null
func get_dialogue_by_id(id : int, dialogue : Dictionary) -> Variant:
	if dialogue.id == id:
		return dialogue
	for child in dialogue.children:
		var result : Variant = get_dialogue_by_id(id, child)
		if result:
			return result
	return null

var visible_characters : int = 0 : set = set_visible_characters

func play_sound() -> void:
	pass

func set_visible_characters(value : int) -> void:
	if value > visible_characters && value > 0:
		play_sound()
	visible_characters = value
	text_node.visible_characters = value

func tween_typewritter(text : String) -> void:
	visible_characters = 0
	text_node.text = text
	var tween : Tween = create_tween()
	tween.tween_property(self,"visible_characters",text_node.text.length(),typewritter_speed * text_node.text.length())
	tween.tween_callback(func():confirm.emit())
	await confirm
	if tween && tween.is_valid():
		tween.kill()
	visible_characters = -1
	await get_tree().create_timer(0.1).timeout

##Play dialogue
func play(dialogue : Dictionary, current_dialogue : Dictionary = dialogue) -> void:
	if current_dialogue == {}:
		finished.emit()
		return
	if button_container.get_child_count() > 0:
		for child in button_container.get_children():
			child.queue_free()
	var s = ""
	s.length()
	match int(current_dialogue.type):
		types.msg:
			for key in variables.keys():
				current_dialogue.content = current_dialogue.content.replace(key,variables[key])
			if use_typewritter:
				await tween_typewritter(current_dialogue.content)
				#do_typewritter(current_dialogue.content)
			else:
				text_node.text = current_dialogue.content
			await confirm
			play(dialogue,current_dialogue.children[0] if current_dialogue.children.size() > 0 else {})
		types.script:
			var split : PackedStringArray = current_dialogue.content.split("?")
			var node : Node = Node.new()
			node.set_script(load(split[0]))
			add_child(node)
			node.call(split[1])
			node.queue_free()
			if current_dialogue.children.size() > 0:
				play(dialogue,current_dialogue.children[0])
		types.choice:
			for key in variables.keys():
				current_dialogue.content = current_dialogue.content.replace(key,variables[key])
			if use_typewritter:
				await tween_typewritter(current_dialogue.content)
			else:
				text_node.text = current_dialogue.content
			for child in current_dialogue.children:
				var button : Button = Button.new()
				for key in variables.keys():
					child.content = child.content.replace(key,variables[key])
				button.text = child.content
				button.connect("pressed",play.bind(dialogue,child.children[0] if child.children.size() > 0 else {}))
				button_container.add_child(button)
			if button_container.get_child_count() > 0:
				button_container.get_child(0).grab_focus()
		types.condition:
			var split : PackedStringArray = current_dialogue.content.split("?")
			var node : Node = Node.new()
			node.set_script(load(split[0]))
			add_child(node)
			var result : bool = node.call(split[1])
			node.queue_free()
			play(dialogue,current_dialogue.children[0] if result else current_dialogue.children[1])
		types.move_to:
			play(dialogue,get_dialogue_by_id(int(current_dialogue.content),dialogue))
		types.placeholder:
			finished.emit()

func play_from_file(path : String) -> void:
	if !FileAccess.file_exists(path):
		push_error("File \"" + path + "\" doesn't exist")
		return
	var file : FileAccess = FileAccess.open(path,FileAccess.READ)
	var dialogue : Dictionary = JSON.parse_string(file.get_as_text())
	play(dialogue)

##Typewritter

func _input(event : InputEvent) -> void:
	if event.is_action_pressed(action_next):
		if writing:
			writing = false
		else:
			confirm.emit()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = []
	if !InputMap.get_actions().has(action_next):
		warnings.append("Action \"" + action_next + "\" doesn't exist")
	return warnings
