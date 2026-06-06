extends Resource
class_name Tag

@export var title: String:
	set(value):
		title = value
		emit_changed()

@export var color: Color:
	set(value):
		color = value
		emit_changed()
