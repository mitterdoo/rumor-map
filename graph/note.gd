extends Resource
class_name Note

@export var text: String:
	set(value):
		text = value
		emit_changed()

@export var category: NoteCategory = preload("res://graph/note_categories/base.tres"):
	set(value):
		ChangedHelper.handle_connection(category, value, emit_changed)
		category = value
func _to_string() -> String:
	return "<Note>"
