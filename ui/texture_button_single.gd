@tool
extends TextureButton
class_name TextureButtonSingle
## Like TextureButton, but only has a single texture and instead uses modulation for the different states
## Still requires texture_focused since it is overlayed on top of the regular texture

@export var texture: Texture2D: ## The main texture to use
	get:
		return texture_normal
	set(value):
		texture_normal = value

@export var modulate_normal: Color = Color.WHITE
@export var modulate_hover: Color = Color.WHITE
@export var modulate_disabled: Color = Color.WHITE
@export var modulate_pressed: Color = Color.WHITE

func _process(dt: float):
	if disabled:
		if modulate != modulate_disabled:
			modulate = modulate_disabled
	elif button_pressed:
		if modulate != modulate_pressed:
			modulate = modulate_pressed
	elif is_hovered():
		if modulate != modulate_hover:
			modulate = modulate_hover
	else:
		modulate = modulate_normal
