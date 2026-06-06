extends GraphElement



func _on_dragged(from: Vector2, to: Vector2) -> void:
	print("on dragged", from, to)
	



func _on_node_selected() -> void:
	print("selected")
