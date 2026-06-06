extends Resource
class_name NodeStyle

@export var name: String:
	set(value):
		name = value
		emit_changed()
@export var background_color: Color = Color.WHITE:
	set(value):
		background_color = value
		emit_changed()
@export var foreground_color: Color = Color.BLACK:
	set(value):
		foreground_color = value
		emit_changed()
		
func _to_string() -> String:
	return "<NodeStyle \"%s\">" % name
