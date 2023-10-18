@tool
extends Control
class_name DialogueCreatorInterface

var used_ids : Array[int] = []	

@onready var file_dialog : FileDialog = $file_dialog

var undo_redo : UndoRedo = UndoRedo.new()

var export : bool = false

var saving : bool = false

func _draw() -> void:
	var biggest : Vector2 = global_position
	var lines : PackedVector2Array = []
	for child in nodes.get_children():
		if child.parent:
			lines.append_array([child.global_position - global_position + Vector2(125,125), child.parent.global_position - global_position + Vector2(125,125)])
			if child.global_position.x > biggest.x:
				biggest.x = child.global_position.x
			if child.global_position.y > biggest.y:
				biggest.y = child.global_position.y
	if !lines.is_empty():
		draw_multiline(lines,Color(0,0,0),2.5)
	if biggest == Vector2.ZERO:
		return
	nodes.custom_minimum_size = biggest * 1000

@onready var scroll : ScrollContainer = $scroll
@onready var nodes : Control = $scroll/nodes

func get_first_available_id() -> int:
	var i : int = 0
	while used_ids.has(i):
		i += 1
	return i

func _on_save_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	saving = true
	export = false
	file_dialog.visible = true


func _on_load_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	saving = false
	file_dialog.visible = true

func _on_export_pressed() -> void:
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	saving = true
	export = true
	file_dialog.visible = true

func _on_nodes_child_entered_tree(node : Node) -> void:
	node.interface = self
	if node.id < 0:
		node.id = get_first_available_id()
		used_ids.append(node.id)

func _physics_process(_delta : float) -> void:
	queue_redraw()

func _on_new_pressed() -> void:
	scroll.scale = Vector2(1,1)
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	used_ids = []
	for child in nodes.get_children():
		child.queue_free()
	if nodes.get_child_count() == 0:
		nodes.add_child.call_deferred(preload("res://addons/DialogueCreator/box.tscn").instantiate())

func load_save(box_data : Dictionary, parent : DialogueBox = null) -> DialogueBox:
	if !parent:
		for child in nodes.get_children():
			child.queue_free()
	var box : DialogueBox = preload("res://addons/DialogueCreator/box.tscn").instantiate()
	box.id = box_data.id
	nodes.add_child(box)
	box.set_content(box_data.content)
	if parent:
		box.parent = parent
	if box_data.keys().has("position"):
		box.global_position = Vector2(box_data.position[0],box_data.position[1])
	box._on_type_item_selected(box_data.type)
	for child in box.children:
		child.queue_free()
	box.children = []
	for child in box_data.children:
		box.children.append(load_save(child,box))
	return box
	

func save(box : DialogueBox, blueprint : bool = false) -> Dictionary:
	var save : Dictionary = {}
	save.id = box.id
	save.type = box.type_select.selected
	save.content = box.content
	if blueprint:
		save.position = [box.global_position.x,box.global_position.y]
	save.children = []
	for child in box.children:
		if export && child.type_select.selected == child.types.placeholder:
			continue
		save.children.append(save(child,blueprint))
	return save

func _on_file_dialog_file_selected(path : String) -> void:
	if saving:
		print(used_ids)
		var save_data : Dictionary
		for child in nodes.get_children():
			if child.id == 0:
				save_data = save(child, !export)
		var file : FileAccess = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(save_data))
	else:
		used_ids = []
		var file : FileAccess = FileAccess.open(path, FileAccess.READ)
		var save_data : Dictionary = JSON.parse_string(file.get_as_text())
		load_save(save_data)

func _on_nodes_child_exiting_tree(node : Node) -> void:
	used_ids.erase(node.id)
	if nodes.get_child_count() == 1:
		nodes.add_child.call_deferred(preload("res://addons/DialogueCreator/box.tscn").instantiate())