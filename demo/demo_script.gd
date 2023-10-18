extends Node

func blue() -> void:
	get_node("../../background").color = Color("513aff")

func orange() -> void:
	get_node("../../background").color = Color("b33c00")

func condition() -> bool:
	return get_node("../../background").color != Color("513aff")
