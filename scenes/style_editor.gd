extends HBoxContainer

var graph: Graph:
	set(value):
		graph = value
		refresh_options()
		
@export var selected_style: NodeStyle
@export var desired_size: int = 0

signal style_selection_changed ## when [b]user[/b] manually selects a style
signal size_changed

func _ready():
	refresh_options()

func select_none():
	%StyleOption.select(-1)
	selected_style = null

func select_style(style: NodeStyle) -> void:
	var index = _get_index_of_style(style)
	if index >= 0:
		%StyleOption.select(index)

func select_size(size: int):
	%SizeOption.value = size

func _get_index_of_style(style: NodeStyle) -> int:
	if not graph:
		return -1
	return graph.styles.find(style)

func refresh_options():
	%StyleOption.clear()
	
	if not graph:
		return
	for style: NodeStyle in graph.styles:
		%StyleOption.add_item(style.name)
		
	if %StyleOption.selected >= 0 and not selected_style:
		selected_style = graph.styles[%StyleOption.selected]
		style_selection_changed.emit(selected_style)
	elif selected_style:
		select_style(selected_style)
	

func _on_style_option_item_selected(index: int) -> void:
	if not graph:
		return
	assert(index >= 0 and index < len(graph.styles), "dropdown index %d is out of range of styles (has %d styles)" % [index, len(graph.styles)])
	selected_style = graph.styles[index]
	style_selection_changed.emit(selected_style)


func _on_size_option_value_changed(value: float) -> void:
	if not graph:
		return
	var old_size = desired_size
	desired_size = roundi(value)
	if desired_size != old_size:
		size_changed.emit(desired_size)
