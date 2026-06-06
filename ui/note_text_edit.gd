extends TextEdit

@export var allow_enter_newline: bool = false
@export var allow_shift_enter_newline: bool = true
func _ready():
	focus_entered.connect(_focus_entered)
	focus_exited.connect(_focus_exited)
func _gui_input(event):
	if event is InputEventKey:
		# TODO
		# shift enter newline boi
		if not allow_enter_newline and (event.keycode == Key.KEY_ENTER or event.keycode == Key.KEY_KP_ENTER):
			accept_event()
			release_focus()
			return
	if event.is_action_pressed("ui_cancel"):
		release_focus()

func _focus_entered():
	if $FuckingFocusRing:
		$FuckingFocusRing.visible = true

func _focus_exited():
	if $FuckingFocusRing:
		$FuckingFocusRing.visible = false

func _on_text_edit_focus_exited() -> void:
	release_focus()
