extends Notable
class_name Connection

@export var destination: Curiosity:
	set(value):
		destination = value
		emit_changed()

func _to_string() -> String:
	return "<Connection (%d notes)>" % len(notes)
