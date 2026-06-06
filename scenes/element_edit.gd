extends TabContainer

@export var note_control_scene: PackedScene
@export var main_node: Main
var graph: Graph
var are_multiple_selected: bool = false

signal curiosity_title_changed(curiosity: Curiosity, new_title: String) ## curiosity, new title
signal deletion_requested(notable: Notable)
signal request_load_image(path: String)
signal delete_image(curiosity: Curiosity)
signal note_added(notable: Notable, note: Note)
signal note_deleted(notable: Notable, note: Note)

# TODO
# fix being able to tab into this control while it's deactivated
# maybe just have a flag on this control that propagates to the inputs


func _ready():
	queue_refresh()

var _current_curiosity: Curiosity
var _other_curiosity: Curiosity
var _selection: Notable

func set_curiosity(curiosity: Curiosity):
	_selection = curiosity
	_current_curiosity = curiosity
	_other_curiosity = null
	queue_refresh()

func set_connection(source: Curiosity, connection: Connection):
	_selection = connection
	_current_curiosity = source
	_other_curiosity = connection.destination
	queue_refresh()


func focus_source_title():
	%CurrentNode.grab_focus()
	%CurrentNode.set_caret_column(len(%CurrentNode.text))
func focus_other_title():
	%OtherNode.grab_focus()
	%OtherNode.set_caret_column(len(%OtherNode.text))

func clear(multiple_selected: bool = false):
	if _selection:
		_selection = null
		_current_curiosity = null
		_other_curiosity = null
		are_multiple_selected = multiple_selected
		queue_refresh()

func _insert_note_ui(note: Note, do_focus: bool = false) -> NoteUI:
	var note_ui: NoteUI = note_control_scene.instantiate() as NoteUI
	assert(note_ui, "Couldn't instantiate note_control_scene as NoteUI")
	%NoteList.add_child(note_ui)
	note_ui.load_note(note)
	if do_focus:
		note_ui.focus()
	note_ui.editing_finished.connect(func(text: String):
		if len(text) == 0:
			if note_ui.source_connection:
				_delete_note(note_ui.source_connection, note, note_ui)
			else:
				_delete_note(_selection, note, note_ui)
	)
	return note_ui

func _delete_note(source: Notable, note: Note, note_ui: NoteUI):
	assert(_selection, "cannot delete a Note when we don't have a selection")
	note_ui.queue_free()
	source.notes.erase(note)
	note_deleted.emit(source, note)

func queue_refresh():
	var editable = _selection != null
	
	if editable:
		var curiosity = _current_curiosity
		current_tab = 0
		%CurrentNode.text = curiosity.title
		%CurrentNode.add_theme_color_override("background_color", curiosity.style.background_color)
		%CurrentNode.add_theme_color_override("font_color", curiosity.style.foreground_color)
		%CurrentNode.add_theme_color_override("caret_color", curiosity.style.foreground_color)

	if _selection is Curiosity:
		%SidebarTitle.text = "Curiosity"
		%ImageButton.visible = true
		%OtherNode.visible = false
		%ConnectionArrow.visible = false
		
		if _current_curiosity.image:
			%ImageButton.tooltip_text = "Change image"
			%ImageButton.texture = preload("res://image/icons/image_change.svg")
			%DeleteImageButton.visible = true
		else:
			%ImageButton.tooltip_text = "Add image"
			%ImageButton.texture = preload("res://image/icons/image_add.svg")
			%DeleteImageButton.visible = false
		
	elif _selection is Connection:
		%SidebarTitle.text = "Connection"
		%OtherNode.text = _other_curiosity.title
		%OtherNode.add_theme_color_override("background_color", _other_curiosity.style.background_color)
		%OtherNode.add_theme_color_override("font_color", _other_curiosity.style.foreground_color)
		%OtherNode.add_theme_color_override("caret_color", _other_curiosity.style.foreground_color)
		%ImageButton.visible = false
		%DeleteImageButton.visible = false
		%OtherNode.visible = true
		%ConnectionArrow.visible = true
	
	# TODO
	# maybe only clear if we absolutely have to?
	
	for old_note in %NoteList.get_children():
		old_note.queue_free()
	
	if _selection:
		# load the notes
		for note in _selection.notes:
			_insert_note_ui(note)
		# load incoming notes
		if _selection is Curiosity:
			var incoming = graph.get_inbound_connections(_selection as Curiosity)
			for record in incoming:
				var source_curiosity = record[0]
				var connection = record[1]
				
				for conn_note in connection.notes:
					var note_ui := _insert_note_ui(conn_note)
					note_ui.set_source_connection(source_curiosity, connection)
	
	if not editable:
		current_tab = 2 if are_multiple_selected else 1
		for child in %NoteList.get_children():
			child.queue_free()



func _on_current_node_text_changed() -> void:
	if not _current_curiosity: return
	_current_curiosity.title = %CurrentNode.text
	curiosity_title_changed.emit(_current_curiosity, %CurrentNode.text)

func _on_other_node_text_changed() -> void:
	if not _other_curiosity: return
	_other_curiosity.title = %OtherNode.text
	curiosity_title_changed.emit(_other_curiosity, %OtherNode.text)

func _on_add_note_button_pressed() -> void:
	if not _selection: return
	
	var note: Note = Note.new()
	_selection.notes.append(note)
	_insert_note_ui(note, true)
	note_added.emit(_selection, note)


func _on_delete_node_button_pressed() -> void:
	# TODO
	# user should confirm deletion first
	if _selection:
		deletion_requested.emit(_selection)


func _on_image_button_pressed() -> void:
	%FileDialog.popup_file_dialog()

func _on_file_dialog_file_selected(path: String) -> void:
	if _selection and _selection is Curiosity:
		request_load_image.emit(path)
		queue_refresh()

func _on_delete_image_button_pressed() -> void:
	if _selection and _selection is Curiosity and _current_curiosity.image:
		delete_image.emit(_current_curiosity)
		queue_refresh()
