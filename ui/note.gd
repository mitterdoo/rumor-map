extends PanelContainer
class_name NoteUI

var note: Note
signal editing_finished(text: String)

const base_category = preload("res://graph/note_categories/base.tres")

var source_curiosity: Curiosity
var source_connection: Connection

func load_note(note: Note):
	self.note = note
	%TextEdit.text = note.text
	if note.category != base_category:
		%CategoryLabel.visible = true
		%CategoryLabel.text = note.category.title
		
		var color = note.category.color
		%CategoryLabel.add_theme_color_override("font_color", color)
		
		var style_normal = %CategoryPicker.get_theme_stylebox("normal").duplicate()
		var style_pressed = %CategoryPicker.get_theme_stylebox("pressed").duplicate()
		var style_hover = %CategoryPicker.get_theme_stylebox("hover").duplicate()
		
		style_normal.bg_color = color
		style_hover.bg_color = Color.from_hsv(color.h, color.s, color.v * 1.25)
		style_pressed.bg_color = Color.from_hsv(color.h, color.s, color.v * 1.5)
		
		%CategoryPicker.add_theme_stylebox_override("normal", style_normal)
		%CategoryPicker.add_theme_stylebox_override("pressed", style_pressed)
		%CategoryPicker.add_theme_stylebox_override("hover", style_hover)
		
		
	else:
		%CategoryLabel.visible = false
		%CategoryPicker.remove_theme_stylebox_override("normal")
		%CategoryPicker.remove_theme_stylebox_override("pressed")
		%CategoryPicker.remove_theme_stylebox_override("hover")

func set_source_connection(source_curiosity: Curiosity, connection: Connection):
	
	var fg_color = source_curiosity.style.foreground_color.to_html(false)
	var bg_color = source_curiosity.style.background_color.to_html(false)
	
	self.source_curiosity = source_curiosity
	source_connection = connection
	
	%SourceCuriosity.visible = true
	%SourceCuriosity.text = "[bgcolor=#%s][color=#%s]%s[/color][/bgcolor]" % [bg_color, fg_color, source_curiosity.title]
	# TODO
	# click on the label to select the source connection

func focus():
	%TextEdit.grab_focus(false)
	
func _draw():
	pass
	# var fucking_style := get_theme_stylebox("panel", "NotePanel") as StyleBoxFlat
	# draw_line(Vector2(12, 0), Vector2(12, size.y), fucking_style.border_color, fucking_style.border_width_left)

func _on_text_edit_text_changed() -> void:
	if not note: return
	note.text = %TextEdit.text

func _on_text_edit_focus_exited() -> void:
	editing_finished.emit(%TextEdit.text)

func _on_category_picker_pressed() -> void:
	pass

func _on_category_popup_index_pressed(index: int) -> void:
	assert(Main.global_graph, "global_graph doesn't exist")
	var categories = Main.global_graph.categories
	assert(index >= 0 and index < len(categories), "index %s out of range of categories (max %s)" % [index, len(categories) - 1])
	var category = categories[index]
	note.category = category
	load_note(note)


func _on_category_picker_button_down() -> void:
	if not Main.global_graph: return
	
	%CategoryPopup.clear()
	var index = 0
	for category in Main.global_graph.categories:
		%CategoryPopup.add_radio_check_item(category.title)
		if category == note.category:
			%CategoryPopup.set_item_checked(index, true)
		index += 1

	# TODO
	# show color of each category
	
	var rect: Rect2 = %CategoryPicker.get_global_rect()
	%CategoryPopup.popup_on_parent(Rect2(rect.end, Vector2.ZERO))
