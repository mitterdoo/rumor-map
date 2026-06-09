extends Control
class_name Main

var current_file: String:
	set(value):
		current_file = value
		update_window_title()
var window_title_base: String = "Rumor Map"
var changes_made: bool = false:
	set(value):
		changes_made = value
		update_window_title()
static var global_graph: Graph

enum FileMenuOperation {
	NEW = 0,
	OPEN = 1,
	SAVE = 2,
	SAVE_AS = 3,
	CLEAR_HISTORY = 99,
	TEMP_LOAD = 69421,
	TEMP_SAVE = 69420
}
enum UnsaveDialogResult {
	CANCEL,
	DONT_SAVE,
	SAVE
}
signal _unsaved_outcome(result: UnsaveDialogResult)
signal _file_open_outcome(path: String)
signal _yes_no_outcome(said_yes: bool)

@export var graph: Graph:
	set(value):
		graph = value
		global_graph = value
		%RumorGraph.graph = value
		%StyleEditor.graph = graph
		%ElementEdit.graph = graph

func get_filename():
	return "New rumor map" if current_file == "" else current_file.get_file()

func update_window_title():
	var filename = get_filename()
	
	var title = "%s - %s" % [filename, window_title_base]
	if changes_made:
		title = "(*) " + title
	
	get_tree().root.title = title

#region Internal refreshers
func _queue_refresh():
	## Update the RumorGraph and anything else to match the resource
	# this should look at existing Controls and align them with the Resource
	# don't do the naive approach of just deleting and recreating everything cause that'll use a lot of memory
	%RumorGraph.queue_refresh()

func _recompose_file_menu():
	
	var recents = Settings.get_recent_files()
	var menu = %FileButton
	menu.clear()
	menu.add_item("New", 0)
	menu.set_item_shortcut(menu.item_count-1, preload("res://ui/shortcuts/new.tres"))
	
	menu.add_item("Open...", 1)
	menu.set_item_shortcut(menu.item_count-1, preload("res://ui/shortcuts/open.tres"))
	
	menu.add_separator("Recent")
	if len(recents) == 0:
		menu.add_item("(none)")
		menu.set_item_disabled(menu.item_count-1, true)
	else:
		var i = 0
		for recent in recents:
			menu.add_item(str(recent), 100 + i)
			i += 1
		menu.add_item("Clear history", 99)
	
	menu.add_separator()
	menu.add_item("Save", 2)
	menu.set_item_shortcut(menu.item_count-1, preload("res://ui/shortcuts/save.tres"))
	menu.add_item("Save As", 3)
	menu.set_item_shortcut(menu.item_count-1, preload("res://ui/shortcuts/save_as.tres"))

#endregion
func _create_new_graph():
	## create a new graph from the default graph Resource
	## recursive copy
	
	# TODO
	# if a user saves a map, then later I change the default styles, their preexisting map won't have the new styles. might need to fix
	const default_graph: Graph = preload("res://graph/default_graph.tres")
	graph = default_graph.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
	
	
func _ready():
	Settings.begin()
	
	_recompose_file_menu()
	var current_file = Settings.config.get_value("history", "current_file", "")
	if Settings.config.get_value("settings", "reopen_current_file", true) and current_file != "":
		if FileAccess.file_exists(current_file):
			load_graph(current_file)
		else:
			Log.push_warning("main", "Current file '" + current_file + "' does not exist. falling back to new file")
			Settings.config.set_value("history", "current_file", "")
			_create_new_graph()
	else:
		_create_new_graph()
	_refresh_style_list()
	
	# %RumorGraph.curiosity_added.connect(func(x): print("== Added curiosity ", x))
	# %RumorGraph.curiosity_deleted.connect(func(x): print("== Deleted curiosity ", x))
	
	# %RumorGraph.connection_added.connect(func(from, conn): print("== Added connection from" , from, " with ", conn))
	# %RumorGraph.connection_deleted.connect(func(from, conn): print("== Deleted connection from ", from, " with ", conn))
	
	var dontsave_button: Button = %ConfirmationDialog.add_button("Don't Save")
	dontsave_button.pressed.connect(func():
		# %ConfirmationDialog.
		_unsaved_outcome.emit(UnsaveDialogResult.DONT_SAVE)
	)
	%ConfirmationDialog.canceled.connect(func(): _unsaved_outcome.emit(UnsaveDialogResult.CANCEL))
	%ConfirmationDialog.confirmed.connect(func(): _unsaved_outcome.emit(UnsaveDialogResult.SAVE))
	
	%YesNoDialog.canceled.connect(func(): _yes_no_outcome.emit(false))
	%YesNoDialog.confirmed.connect(func(): _yes_no_outcome.emit(true))
	
	%FileDialog.file_selected.connect(func(x): _file_open_outcome.emit(x))
	%FileDialog.canceled.connect(func(): _file_open_outcome.emit(""))

	update_window_title()

	get_tree().set_auto_accept_quit(false)


func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not await check_closing_unsaved_warning(): return
		get_tree().quit()

func _refresh_style_list():
	## update the visual style dropdown to match the current list of styles
	pass

func _refresh_style_for_selection():
	var length = len(%RumorGraph.selected_curiosities)
	
	if length == 0:
		return
	
	var current_style
	var current_size = 0
	for curiosity: Curiosity in %RumorGraph.selected_curiosities:
		if not current_style:
			current_style = curiosity.style
			current_size = curiosity.size
		elif curiosity.style != current_style:
			# multiple styles selected
			%StyleEditor.select_none()
			# not sure if i should even bother picking a size to display for conflicting sizes.
			# maybe TODO?
			return
	
	%StyleEditor.select_size(current_size)
	%StyleEditor.select_style(current_style)

func _set_curiosity_image(curiosity: Curiosity, image: Image):
	var cur_image = curiosity.image
	if cur_image != image and cur_image:
		curiosity.image = null
	
	if image:
		var texture = ImageTexture.create_from_image(image)
		curiosity.image = texture
	var ui_curiosity: CuriosityUI = %RumorGraph.curiosity_map[curiosity]
	if ui_curiosity:
		ui_curiosity.queue_refresh()
	if %ElementEdit._current_curiosity == curiosity:
		%ElementEdit.queue_refresh()
	
func _refresh_editor_for_curiosity(curiosity: Curiosity) -> void:
	var length = len(%RumorGraph.selected_curiosities)
	if length == 1 and %RumorGraph.selected_connection == null:
		%ElementEdit.set_curiosity(curiosity)
	elif length == 0 and %RumorGraph.selected_connection == null:
		%ElementEdit.clear()
	else:
		# multiple things are selected
		%ElementEdit.clear(true)

func _on_rumor_graph_curiosity_selected(curiosity: Curiosity) -> void:
	_refresh_style_for_selection()
	_refresh_editor_for_curiosity(curiosity)

func _on_rumor_graph_curiosity_deselected(curiosity: Curiosity) -> void:
	_refresh_style_for_selection()
	_refresh_editor_for_curiosity(curiosity)

func _on_rumor_graph_connection_selected(source: Curiosity, connection: Connection) -> void:
	%ElementEdit.set_connection(source, connection)

func _on_rumor_graph_connection_deselected(source: Curiosity, connection: Connection) -> void:
	%ElementEdit.clear()

func _on_rumor_graph_request_edit_connection_destination_title() -> void:
	if %ElementEdit._other_curiosity:
		%ElementEdit.focus_other_title()

func _on_rumor_graph_request_edit_curiosity_title() -> void:
	if %ElementEdit._current_curiosity:
		%ElementEdit.focus_source_title()

func _on_style_editor_style_selection_changed(style: NodeStyle) -> void:
	%RumorGraph.desired_style = style
	for curiosity in %RumorGraph.selected_curiosities:
		changes_made = true
		curiosity.style = style
		var ui_curiosity: CuriosityUI = %RumorGraph.curiosity_map[curiosity]
		ui_curiosity.queue_refresh()
	%ElementEdit.queue_refresh()

func _on_style_editor_size_changed(size: int) -> void:
	%RumorGraph.desired_size = size
	for curiosity in %RumorGraph.selected_curiosities:
		changes_made = true
		curiosity.size = size
		var ui_curiosity: CuriosityUI = %RumorGraph.curiosity_map[curiosity]
		ui_curiosity.queue_refresh()
	%RumorGraph.refresh_segments()

func _on_element_edit_curiosity_title_changed(curiosity: Curiosity, text: String) -> void:
	changes_made = true
	if curiosity in %RumorGraph.curiosity_map:
		%RumorGraph.curiosity_map[curiosity].queue_refresh()

func save_graph(path: String):
	ResourceSaver.save(graph, path, ResourceSaver.FLAG_COMPRESS)
	Settings.add_recent_file(path)
	Settings.config.set_value("history", "current_file", path)
	Settings.save()
	_recompose_file_menu()
	changes_made = false

func load_graph(path: String) -> Graph:
	if graph:
		clear_graph()
	
	var loaded_graph := load(path) as Graph
	assert(loaded_graph, "Could not load graph!")
	
	for curiosity: Curiosity in loaded_graph.curiosities:
		%RumorGraph.create_curiosity_element(curiosity, false)
	graph = loaded_graph
	current_file = path
	changes_made = false
	
	Settings.add_recent_file(path)
	Settings.config.set_value("history", "current_file", path)
	Settings.save()
	_recompose_file_menu()
	
	_queue_refresh()
	return loaded_graph

func clear_graph():
	%RumorGraph.clear()
	%ElementEdit.clear()
	graph = null
	Settings.config.set_value("history", "current_file", "")
	Settings.save()
	_create_new_graph()
	_refresh_style_list()
	current_file = ""
	changes_made = false

func _on_file_button_id_pressed(id: int) -> void:
	if id >= 100 and id < 100 + Settings.RECENT_FILE_COUNT:
		file_open_recent(id-100)
		return
	
	match id as FileMenuOperation:
		FileMenuOperation.OPEN:
			file_open()
		FileMenuOperation.NEW:
			# TODO
			# confirm with user if nothing's been done yet since current file has been saved/opened last
			if not await check_closing_unsaved_warning():
				return
			clear_graph()
		FileMenuOperation.SAVE:
			file_save()
		
		FileMenuOperation.SAVE_AS:
			file_save(true)
		
		FileMenuOperation.CLEAR_HISTORY:
			%YesNoDialog.title = "Confirm"
			%YesNoDialog.dialog_text = "Clear recent file history?"
			%YesNoDialog.popup_centered()
			if await _yes_no_outcome:
				Settings.clear_recent_files()
				_recompose_file_menu()

func _file_save_select_callback(path: String):
	current_file = path
	save_graph(path)



func check_closing_unsaved_warning() -> bool:
	if not changes_made: return true
	
	%ConfirmationDialog.dialog_text = """File "%s" has unsaved changes.
Save before closing?
""" % get_filename()
	%ConfirmationDialog.popup_centered()
	
	var result = await _unsaved_outcome
	
	match result:
		UnsaveDialogResult.CANCEL:
			return false
		UnsaveDialogResult.DONT_SAVE:
			%ConfirmationDialog.hide() # doesnt hide on its own can't have shit in detroit
			return true
		UnsaveDialogResult.SAVE:
			await file_save()
			return true
		_:
			return false

func file_save(save_as: bool = false):
	if save_as or current_file == "":
		%FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_SAVE_FILE
		%FileDialog.ok_button_text = "Save" if not save_as else "Save as"
		if current_file != "":
			%FileDialog.current_path = current_file
		else:
			var last_folder = Settings.get_last_folder()
			if last_folder != "":
				if DirAccess.dir_exists_absolute(last_folder):
					# TODO this might not actually work idk
					%FileDialog.current_path = last_folder
				else:
					Settings.clear_last_folder()
		
		%FileDialog.popup_file_dialog()
		
		var path = await _file_open_outcome
		if path != "":
			current_file = path
			save_graph(path)
	else:
		# TODO
		# dont save if no changes?
		save_graph(current_file)

func file_open():
	# TODO
	# confirm with user before closing unsaved changes
	if not await check_closing_unsaved_warning():
		return
	
	%FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	%FileDialog.ok_button_text = "Open"
	
	var last_folder = Settings.get_last_folder()
	if last_folder != "":
		if DirAccess.dir_exists_absolute(last_folder):
			%FileDialog.current_path = last_folder
		else:
			Settings.clear_last_folder()
	%FileDialog.popup_file_dialog()
	
	var path = await _file_open_outcome
	if path != "":
		load_graph(path)

func file_open_recent(index: int):
	if not await check_closing_unsaved_warning():
		return
	var recents = Settings.get_recent_files()
	if index >= len(recents):
		push_error("Tried to open a recent file out of range (there are " + str(len(recents)) + " tracked)")
	var path = recents[index]

	if FileAccess.file_exists(path):	
		load_graph(path)
	else:
		%YesNoDialog.title = "File missing!"
		%YesNoDialog.dialog_text = "The file at '" + path + "' no longer exists or is not accessible.\nRemove from recent file list?"
		%YesNoDialog.popup_centered()
		if await _yes_no_outcome:
			Settings.remove_recent_file(path)
			_recompose_file_menu()

func _on_element_edit_deletion_requested(notable: Notable) -> void:
	if notable is Curiosity:
		changes_made = true
		%RumorGraph.delete_curiosity(notable as Curiosity)
	elif notable is Connection:
		changes_made = true
		%RumorGraph.delete_connection(notable as Connection)

const fucking_whitespace_chars = "\t \r\n"

func _input(event):
	if event.is_action_pressed("ui_paste") and len(%RumorGraph.selected_curiosities) == 1:
		var curiosity = %RumorGraph.selected_curiosities[0]
		if DisplayServer.clipboard_has_image():
			changes_made = true
			_set_curiosity_image(curiosity, DisplayServer.clipboard_get_image())
		elif DisplayServer.clipboard_has():
			var text := DisplayServer.clipboard_get().lstrip(fucking_whitespace_chars).rstrip(fucking_whitespace_chars)
			var ext := text.get_extension()
			if not text.begins_with("file://"): return
			var path = text.substr(7)
			if ext.to_lower() in ['jpg', 'jpeg', 'png']:
				changes_made = true
				_on_element_edit_request_load_image(path)

func _on_element_edit_request_load_image(path: String) -> void:
	var loaded_image = Image.load_from_file(path)
	if loaded_image and len(%RumorGraph.selected_curiosities) == 1:
		changes_made = true
		_set_curiosity_image(%RumorGraph.selected_curiosities[0], loaded_image)

func _on_element_edit_delete_image(curiosity: Curiosity) -> void:
	changes_made = true
	_set_curiosity_image(curiosity, null)


func _on_rumor_graph_change_made() -> void:
	changes_made = true
