extends GraphElement
class_name CuriosityUI

var _fucking_style: StyleBox # why does godot make me create a whole new style just for overriding parts of its actual style resource??? because fuck you. do not pass go. do not collect two hundred dollars

@export var curiosity: Curiosity:
	set(value):
		curiosity = value
		queue_refresh()

var scale_factor: float = 1.0
const fallback: Texture2D = preload("res://image/question_mark.png")

func _ready():
	var parent := get_parent() as RumorGraph
	if not parent:
		queue_free()
	assert(parent, "CuriosityUI must be a direct descendant of RumorGraph")
	
	var its_the_fucking_style = %PanelContainer.get_theme_stylebox("panel").duplicate()
	_fucking_style = its_the_fucking_style
	queue_refresh()

func _process(_dt):
	size = Vector2.ZERO

func center_at_origin():
	## moves the position_offset so the element is centered on the Curiosity's current origin
	## useful when creating curiosities from the user's cursor
	position_offset = position_offset - size/2

func queue_refresh():
	# kill me.
	if not is_node_ready():
		return
		# later
	
	%PanelContainer.add_theme_stylebox_override("panel", _fucking_style)
	if curiosity == null:
		_fucking_style.bg_color = Color.MAGENTA
		%Label.text = "<undefined>"
		%Label.add_theme_color_override("font_color", Color.BLACK)
		_update_texture(null)
	
	else:
		_fucking_style.bg_color = curiosity.style.background_color
		%Label.text = curiosity.title
		%Label.add_theme_color_override("font_color", curiosity.style.foreground_color)
		_update_texture(curiosity.image)
	
	_rescale()
	
func _update_texture(value):
	if value == null:
		%TextureRect.texture = fallback
		%TextureRect.modulate = curiosity.style.background_color if curiosity != null else Color.MAGENTA
		queue_redraw()
	else:
		%TextureRect.texture = value
		%TextureRect.modulate = Color.WHITE
		queue_redraw()
	
func _rescale():
	scale_factor = 1.5 ** (curiosity.size if curiosity != null else 0)
	
	var base_margin = 3
	%MarginContainer.add_theme_constant_override("margin_left", base_margin * scale_factor)
	%MarginContainer.add_theme_constant_override("margin_right", base_margin * scale_factor)
	%MarginContainer.add_theme_constant_override("margin_top", base_margin * scale_factor)
	%MarginContainer.add_theme_constant_override("margin_bottom", base_margin * scale_factor)
	
	var base_font_size = 18
	%Label.add_theme_font_size_override("font_size", base_font_size * scale_factor)
	
	var base_label_min_width = 150
	%Label.custom_minimum_size = Vector2(base_label_min_width * scale_factor, 0)
	
	# var base_expand_margin = 8
	#_fucking_style.expand_margin_left = base_expand_margin * scale_factor
	#_fucking_style.expand_margin_right = base_expand_margin * scale_factor
	#_fucking_style.expand_margin_top = base_expand_margin * scale_factor
	#_fucking_style.expand_margin_bottom = base_expand_margin * scale_factor
	
	#var base_border_width = 4
	#_fucking_style.border_width_left = base_border_width * scale_factor
	#_fucking_style.border_width_right = base_border_width * scale_factor
	#_fucking_style.border_width_top = base_border_width * scale_factor
	#_fucking_style.border_width_bottom = base_border_width * scale_factor

var cursor_border = 16 # remember to multiply it by scale_factor
var _is_hovered = false
func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and event.double_click:
		accept_event()
		(get_parent() as RumorGraph).curiosity_double_clicked.emit(self)
		return
	
	if event is InputEventMouseMotion:
		var adjusted_cursor_border = min(cursor_border, min(size.x, size.y) / 2)
		var rect = Rect2(adjusted_cursor_border, adjusted_cursor_border, size.x - adjusted_cursor_border*2, size.y - adjusted_cursor_border*2)
		_is_hovered = not rect.has_point(event.position)
		_process_cursor()
	elif event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT and _is_hovered:
		if event.double_click:
			print("DOUBLE CLICK")
		elif event.pressed:
			accept_event()
			(get_parent() as RumorGraph).my_connection_drag_started.emit(self)
			# don't eat the input if we release
			# just in case the user grabs close to the border, then the cursor goes into range while moving
		else:
			(get_parent() as RumorGraph).my_connection_drag_ended.emit(self, position_offset + event.position)
			_process_cursor()

func _on_control_mouse_exited() -> void:
	_is_hovered = false
	_process_cursor()

func _process_cursor():
	if _is_hovered:
		set_default_cursor_shape(Control.CURSOR_CROSS)
	else:
		set_default_cursor_shape(Control.CURSOR_DRAG)

func _on_node_selected() -> void:
	if is_node_ready():
		_fucking_style.border_color = Color(1,1,1,1)


func _on_node_deselected() -> void:
	if is_node_ready():
		_fucking_style.border_color = Color(1,1,1,0)


func _on_position_offset_changed() -> void:
	if curiosity:
		curiosity.position = position_offset
