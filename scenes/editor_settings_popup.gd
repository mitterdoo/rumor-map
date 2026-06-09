extends Popup


func _on_ok_button_pressed() -> void:
	hide()
	
func _pre_popup():
	%SettingReopen.button_pressed = Settings.config.get_value("settings", "reopen_current_file", true)
	%SettingBackupCount.value = Settings.config.get_value("settings", "backup_count", 5)
	%SettingBackupFrequency.value = Settings.config.get_value("settings", "backup_frequency_minutes", 5)




func _on_setting_reopen_toggled(toggled_on: bool) -> void:
	Settings.config.set_value("settings", "reopen_current_file", toggled_on)


func _on_setting_backup_count_value_changed(value: float) -> void:
	var count: int = int(value)
	%SettingBackupFrequency.editable = count > 0
	Settings.config.set_value("settings", "backup_count", count)


func _on_setting_backup_frequency_value_changed(value: float) -> void:
	var freq = int(value)
	Settings.config.set_value("settings", "backup_frequency_minutes", freq)
