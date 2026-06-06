extends GraphEdit
class_name RumorGraph

@export var graph: Graph:
	set(value):
		graph = value
		refresh_curiosity_map()
		refresh_segments()

signal curiosity_selected
signal curiosity_deselected

signal curiosity_added
signal curiosity_deleted

signal connection_added
signal connection_deleted

signal connection_selected
signal connection_deselected

signal my_connection_drag_ended
signal my_connection_drag_started
signal my_connection_request
signal my_connection_to_empty

signal request_edit_curiosity_title
signal request_edit_connection_destination_title

signal change_made

class Segment extends RefCounted:
	var a: Control
	var b: Control
	var hovered: bool = false
	
	var forward_selected: bool = false
	var forward_curiosity: Curiosity
	var forward_connection: Connection
	
	var back_selected: bool = false
	var back_curiosity: Curiosity
	var back_connection: Connection
	
	var bidirectional: bool = false

var _segments: Array[Segment]
var curiosity_map: Dictionary[Curiosity, CuriosityUI]

var selected_curiosities: Array[Curiosity]
var selected_connection: Connection
var selected_connection_source: Curiosity

@export var curiosity_scene: PackedScene
@export var desired_style: NodeStyle
@export var fallback_style: NodeStyle

@export var desired_size: int


var _clicked_at: Vector2 ## local location of cursor in GraphEdit when context menu clicked

func _ready():
	my_connection_drag_started.connect(_on_connection_drag_started)
	my_connection_drag_ended.connect(_on_connection_drag_ended)
	refresh_curiosity_map()
	refresh_segments()
	
	
func queue_refresh():
	refresh_curiosity_map()
	refresh_segments()

func create_curiosity_element(curiosity: Curiosity, do_select: bool = false) -> CuriosityUI:
	var scene_instance = curiosity_scene.instantiate()
	var ui_curiosity: CuriosityUI = scene_instance
	ui_curiosity.curiosity = curiosity
	ui_curiosity.position_offset = curiosity.position
	add_child(ui_curiosity)
	queue_refresh()
	curiosity_added.emit(curiosity)
	if do_select:
		set_selected(ui_curiosity)
		request_edit_curiosity_title.emit()
	return ui_curiosity

func create_curiosity(at_position: Vector2, do_select: bool = true) -> CuriosityUI:
	var curiosity = Curiosity.new()
	curiosity.title = _generate_curiosity_title()
	curiosity.position = at_position
	if desired_style:
		curiosity.style = desired_style
	else:
		curiosity.style = fallback_style
	curiosity.size = desired_size
	graph.curiosities.append(curiosity)
	
	change_made.emit()
	
	return create_curiosity_element(curiosity, do_select)

func _confirm_ok_to_delete_curiosity(curiosity: Curiosity) -> bool:
	var is_unsafe_delete: bool = false
	if len(curiosity.notes) > 0:
		is_unsafe_delete = true
	
	if curiosity in graph.connections:
		var list = graph.connections[curiosity]
		for connection in list:
			if len(connection.notes) > 0:
				is_unsafe_delete = true
				break
	
	# TODO
	# actually prompt the user and await response
	return true

func _confirm_ok_to_delete_connection(connection: Connection) -> bool:
	var is_unsafe_delete = false
	if len(connection.notes) > 0:
		is_unsafe_delete = true
	
	# TODO
	# actually prompt the user and await response
	return true

func clear():
	for child in get_children():
		if child is CuriosityUI:
			child.queue_free()
	selected_connection = null
	selected_connection_source = null
	selected_curiosities = []
	graph = null
	queue_redraw()
	
func delete_curiosity(curiosity: Curiosity):
	if not _confirm_ok_to_delete_curiosity(curiosity):
		return
	
	var ui_curiosity: CuriosityUI
	for node in get_children():
		if node is CuriosityUI and node.curiosity == curiosity:
			ui_curiosity = node
			break
	assert(ui_curiosity != null, "Could not find a matching CuriosityUI Control for the provided Curiosity")
	
	curiosity_deleted.emit(curiosity)
	
	
	# TODO
	# warn the user that this will delete the notes stored in any connections, but only if notes exist
	
	# find all references to this and disconnect
	# there's just the graph's list of curiosities, and dictionary of connections
	change_made.emit()
	graph.curiosities.erase(curiosity)
	graph.connections.erase(curiosity)
	
	for source: Curiosity in graph.connections:
		var list: Array = graph.connections[source]
		var to_remove = []
		for connection: Connection in list:
			if connection.destination == curiosity:
				to_remove.append(connection)
		for remove: Connection in to_remove:
			connection_deleted.emit(source, remove)
			list.erase(remove)
	
	ui_curiosity.queue_free()
	_on_node_deselected(ui_curiosity)
	
	queue_refresh()

func delete_connection(connection: Connection):
	if not _confirm_ok_to_delete_connection(connection):
		return
	
	var segment: Segment
	for this_seg: Segment in _segments:
		if this_seg.forward_connection == connection or this_seg.back_connection == connection:
			segment = this_seg
			break
	
	assert(segment != null, "Couldn't find a Segment for connection %s" % connection)
	
	var source_curiosity = segment.forward_curiosity if segment.forward_connection == connection else segment.back_curiosity
	var conn_list = graph.connections[source_curiosity]
	assert(connection in conn_list, "Graph is missing connection %s from curiosity %s" % [connection, source_curiosity])
	conn_list.erase(connection)
	
	if len(conn_list) == 0:
		graph.connections.erase(source_curiosity)
	
	# TODO TODO TODO TODO
	# be careful when erasing bidirectional connections
	change_made.emit()
	_segments.erase(segment)
	
	if selected_connection == connection:
		selected_connection = null
		selected_connection_source = null
		connection_deselected.emit(source_curiosity, connection)
	
	connection_deleted.emit(source_curiosity, connection)
	queue_refresh()
	

func refresh_curiosity_map():
	curiosity_map = {}
	queue_redraw()
	if not graph:
		return
	for node in get_children():
		var ui_curiosity := node as CuriosityUI
		if ui_curiosity and ui_curiosity.curiosity in graph.curiosities:
			curiosity_map[ui_curiosity.curiosity] = ui_curiosity

func refresh_segments():
	# TODO
	# dont delete all the segments, so we can preserve the selected state of them
	_segments = []
	
	# keep track of the connections we make, so if there's a reverse connection made between the two same nodes, use the same Segment object
	var connections_made = {}
	# { destination_curiosity = { source_curiosity = Segment } }
	queue_redraw()
	if not graph: 
		return
	for curiosity in graph.connections:
		var connection_list: Array = graph.connections[curiosity]
		
		for connection: Connection in connection_list:
			assert(curiosity in curiosity_map, "curiosity {curiosity} is not a key of the curiosity_map")
			
			if (curiosity in connections_made) and (connection.destination in connections_made[curiosity]):
				#       bidirectional!!!
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⠔⠒⡒⢠⣩⣍⣁⠂⠠⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⢀⠔⣡⣴⣾⣽⣹⣿⣿⣿⣿⣿⣦⡈⢂⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⢀⣤⣃⣶⣟⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⡆⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⡠⠒⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡅⢸⠀⠀⠀⠀⠀⠀⠀
				#⠀⢀⣜⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣜⢨⠄⠀⠀⠀⠀⠀⠀
				#⢀⣞⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⢸⠀⠀⠀⠀⠀⠀⠀
				#⣾⠿⠛⠛⠛⡝⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢢⡇⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⢽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣹⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠙⠻⠿⢿⣿⡿⠟⠛⣿⣿⣿⣿⣿⡳⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣯⡆⠀⠀⢻⣿⡟⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⡿⡗⠀⠀⣼⣿⡅⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣧⠁⠀⠀⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⢹⠀⠀⠀⢿⣿⢳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣾⠤⡄⣀⣚⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠈⠻⠿⠿⠷⠾⢥⣬⣴⣿⢿⣿⡟⢿⠉⠛⢻⡽⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⢀⡠⢊⣡⠞⠉⠿⣌⢷⡂⢼⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⢀⠔⣡⠔⠋⠀⠀⠀⠀⠘⢦⣝⣾⣿⣽⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⣴⡡⠊⠀⠀⠀⠀⠀⢀⣀⢤⣔⣽⣿⡟⣷⣮⣔⡢⢄⡀⡀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⣶⣖⣶⠭⠿⠶⠛⠛⠉⠁⢸⠅⡇⠀⠈⠙⠛⠳⠶⢯⣵⣲⠠
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⢀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡜⣸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				#⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡧⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
				var existing_segment: Segment = connections_made[curiosity][connection.destination]
				
				existing_segment.back_curiosity = curiosity
				existing_segment.back_connection = connection
				existing_segment.bidirectional = true
				
			else:
			
				var node_a = curiosity_map[curiosity]
				var node_b = curiosity_map[connection.destination]
				
				var segment = Segment.new()
				segment.a = node_a
				segment.b = node_b
				segment.forward_curiosity = curiosity
				segment.forward_connection = connection
				_segments.append(segment)
				if connection.destination not in connections_made:
					connections_made[connection.destination] = {}
				
				connections_made[connection.destination][curiosity] = segment

func get_curiosity_at(pos: Vector2) -> CuriosityUI:
	var curiosity: CuriosityUI = null
	for child in get_children():
		var child_element := child as CuriosityUI
		if child_element and child_element.get_global_rect().has_point(pos):
			curiosity = child_element
	return curiosity


func _get_desired_size():
	return %SizeOption.value

# TODO
# make this way better holy shit this is ugly as fuck
# just have a default name, and add (1) or (2) etc after the name just like windows
var _counter = 0
func _generate_curiosity_title():
	_counter += 1
	return "Curiosity " + str(_counter)

const chevron_texture: Texture2D = preload("res://image/chevron.svg")
const chevron_texture_forward: Texture2D = preload("res://image/double_chevron_forward.svg")
const chevron_texture_back: Texture2D = preload("res://image/double_chevron_back.svg")

func convert_local_to_graph(vec: Vector2) -> Vector2:
	return (vec + scroll_offset) / zoom
	
func convert_graph_to_local(vec: Vector2) -> Vector2:
	return vec * zoom - scroll_offset

func _get_segment_points(seg: Segment):
	var pos_a = convert_graph_to_local(seg.a.position_offset) + seg.a.size/2 * zoom
	var pos_b = convert_graph_to_local(seg.b.position_offset) + seg.b.size/2 * zoom
	
	return [pos_a, pos_b]

func _draw_segment(seg: Segment):
	const selected_color = Color(1, 1, 1, 1)
	const hovered_color = Color(1, 1, 1, 0.65)
	const normal_color = Color(1, 1, 1, 0.5)
	const chevron_offset = Vector2(-256 - 18, -256)
	const chevron_offset_bidir = Vector2(-256, -256)
	
	var forward_selected = selected_connection == seg.forward_connection
	var back_selected = seg.back_connection and selected_connection == seg.back_connection
	var selected = forward_selected or back_selected
	var segment_color: Color
	if selected:
		segment_color = selected_color
	elif seg.hovered:
		segment_color = hovered_color
	else:
		segment_color = normal_color
	var chevron_scale = 1.0 if not selected else 1.5
	const segment_width = 6
	const chevron_base_scale = 0.12
	const chevron_base_line_spacing = 22
	var chevron_rendered_scale = chevron_scale * chevron_base_scale
	var chevron_line_spacing = chevron_base_line_spacing * chevron_scale
	
	var points = _get_segment_points(seg)
	var pos_a = points[0]
	var pos_b = points[1]
	var dist = pos_a.distance_to(pos_b)
	var frac_for_chevron = chevron_line_spacing * zoom / dist
	
	draw_line(pos_a, lerp(pos_a, pos_b, 0.5 - frac_for_chevron), segment_color, segment_width * zoom, true)
	draw_line(lerp(pos_a, pos_b, 0.5 + frac_for_chevron), pos_b, segment_color, segment_width * zoom, true)
	# TODO
	# Calculate the midpoint of the line traced between the two centerpoints of both nodes, but only do it on the *visible* segment of the line not overlapped by the nodes.
	var midpoint = (pos_a + pos_b) / 2
	var angle = (pos_b - pos_a).angle()
	
	draw_set_transform(midpoint, angle, Vector2.ONE * zoom * chevron_rendered_scale)
	if seg.bidirectional:
		# bidirectional
		var forward_color: Color = selected_color if forward_selected else (hovered_color if seg.hovered else normal_color)
		var back_color: Color = selected_color if back_selected else (hovered_color if seg.hovered else normal_color)
		draw_texture(chevron_texture_forward, chevron_offset_bidir, forward_color)
		draw_texture(chevron_texture_back, chevron_offset_bidir, back_color)
	else:
		draw_texture(chevron_texture, chevron_offset, segment_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _distance_to_segment(point: Vector2, a: Vector2, b: Vector2):
	var ab = b - a
	var t = clamp((point - a).dot(ab) / ab.dot(ab), 0.0, 1.0)
	return (point - (a + t * ab)).length()
	
func _draw():
	for segment in _segments:
		_draw_segment(segment)

var hovered_element: Segment
func _gui_input(event):
	if event is InputEventMouseMotion:
		var is_hovering_curiosity = get_curiosity_at(event.global_position) != null
		const segment_hover_distance = 8
		var scaled_hover_distance = zoom * segment_hover_distance
		var was_hovered = false
		
		if not is_hovering_curiosity:
			for segment in _segments:
				var points = _get_segment_points(segment)
				var a = points[0]
				var b = points[1]
				
				var distance = _distance_to_segment(get_local_mouse_position(), a, b)
				if distance < scaled_hover_distance:
					if hovered_element != null:
						hovered_element.hovered = false
					hovered_element = segment
					segment.hovered = true
					queue_redraw()
					was_hovered = true
					set_default_cursor_shape(Control.CURSOR_POINTING_HAND)
					break
		
		if not was_hovered and hovered_element != null:
			hovered_element.hovered = false
			queue_redraw()
			hovered_element = null
			set_default_cursor_shape(Control.CURSOR_ARROW)
	elif event is InputEventMouseButton:
		if get_curiosity_at(event.global_position):
			set_default_cursor_shape(Control.CURSOR_ARROW)
			return
		if event.pressed and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			if hovered_element:
				if not hovered_element.bidirectional and selected_connection == hovered_element.forward_connection:
					# already selected
					return
				set_selected(null)
				if selected_connection:
					connection_deselected.emit(selected_connection_source, selected_connection)
				
				var new_connection: Connection
				var new_curiosity: Curiosity
				if hovered_element.bidirectional:
					if not selected_connection:
						new_connection = hovered_element.forward_connection
						new_curiosity = hovered_element.forward_curiosity
					else:
						new_connection = hovered_element.forward_connection if selected_connection == hovered_element.back_connection else hovered_element.back_connection
						new_curiosity = hovered_element.forward_curiosity if selected_connection == hovered_element.back_connection else hovered_element.back_curiosity
				else:
					new_connection = hovered_element.forward_connection
					new_curiosity = hovered_element.forward_curiosity
				selected_connection = new_connection
				selected_connection_source = new_curiosity
				connection_selected.emit(selected_connection_source, selected_connection)
				accept_event()
				queue_redraw()
			else:
				if selected_connection:
					connection_deselected.emit(selected_connection_source, selected_connection)
				selected_connection = null
				selected_connection_source = null
				queue_redraw()
func _input(event):
	if event.is_action_pressed("curiosity_size_up") or event.is_action_pressed("curiosity_size_down"):
		var hovered_curiosity = get_curiosity_at(event.global_position)
		var do_increase = event.is_action_pressed("curiosity_size_up")
		
		if hovered_curiosity:
			var curiosity = hovered_curiosity.curiosity
			curiosity.size += 1 if do_increase else -1
			change_made.emit()
			hovered_curiosity.queue_refresh()
		
		for selection: Curiosity in selected_curiosities:
			if hovered_curiosity and hovered_curiosity.curiosity == selection:
				continue
			selection.size += 1 if do_increase else -1
			var ui := curiosity_map[selection]
			change_made.emit()
			ui.queue_refresh()
		

# TODO
# If we're about to draw two segments between the two same nodes (bidirectional), we should space out the points perpendicular to the line direction


func connect_curiosities(source_curiosity: Curiosity, destination_curiosity: Curiosity, do_select: bool = true) -> Connection:
	if source_curiosity == destination_curiosity:
		return
	
	var connection: Connection
	if source_curiosity not in graph.connections:
		connection = Connection.new()
		connection.destination = destination_curiosity
		graph.connections[source_curiosity] = [connection]
	else:
		var cur_list = graph.connections[source_curiosity]
		for this_connection: Connection in cur_list:
			if this_connection.destination == destination_curiosity:
				return
		connection = Connection.new()
		connection.destination = destination_curiosity
		cur_list.append(connection)
	
	connection_added.emit(source_curiosity, connection)
	set_selected(null)
	if do_select:
		if selected_connection:
			connection_deselected.emit(selected_connection_source, selected_connection)
		selected_connection = connection
		selected_connection_source = source_curiosity
		connection_selected.emit(selected_connection_source, selected_connection)
		request_edit_connection_destination_title.emit()
	refresh_segments()
	change_made.emit()
	return connection
	

func _on_connection_drag_started(source: CuriosityUI):
	pass
func _on_connection_drag_ended(source: CuriosityUI, pos: Vector2):
	var destination: CuriosityUI = get_curiosity_at(get_global_mouse_position())
	if not destination:
		# nothing hovered on this end. so, create a curiosity then connect to it
		destination = create_curiosity(pos, false)
		destination.center_at_origin()
		refresh_curiosity_map()

	var source_curiosity: Curiosity = source.curiosity
	var destination_curiosity: Curiosity = destination.curiosity
	assert(source_curiosity, "CuriosityUI isn't attached to a Curiosity!")
	assert(destination_curiosity, "CuriosityUI isn't attached to a Curiosity!")
	connect_curiosities(source_curiosity, destination_curiosity)
	

func _on_popup_menu_id_pressed(id: int) -> void:
	match id:
		0:
			var curiosity = create_curiosity(_clicked_at)

			curiosity.center_at_origin()
func _on_rumor_graph_popup_request(at_position: Vector2) -> void:
	_clicked_at = convert_local_to_graph(at_position)
	var position = %RumorGraph.get_global_rect().position + at_position
	%PopupMenu.popup_on_parent(Rect2(position, Vector2.ZERO))

func _on_rumor_graph_delete_nodes_request(node_names: Array[StringName]) -> void:
	if len(node_names) == 0 and selected_connection:
		delete_connection(selected_connection)
		return
		
	var nodes: Array[Node] = %RumorGraph.get_children().filter(func (x): return x.name in node_names)
	var curiosities = nodes.map(func (x): return x.curiosity)
	for curiosity in curiosities:
		# TODO
		# prompt user if ANY of these curiosities are unsafe to delete (has notes, a connection has notes)
		delete_curiosity(curiosity)


func _on_node_selected(node: Node) -> void:
	var ui_curiosity := node as CuriosityUI
	if selected_connection:
		connection_deselected.emit(selected_connection_source, selected_connection)
		selected_connection = null
		selected_connection_source = null
		queue_redraw()
	if ui_curiosity and ui_curiosity.curiosity:
		selected_curiosities.append(ui_curiosity.curiosity)
		curiosity_selected.emit(ui_curiosity.curiosity)

func _on_node_deselected(node: Node) -> void:
	var ui_curiosity := node as CuriosityUI
	if ui_curiosity and ui_curiosity.curiosity:
		selected_curiosities.erase(ui_curiosity.curiosity)
		curiosity_deselected.emit(ui_curiosity.curiosity)
