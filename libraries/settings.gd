extends Object

class_name Settings
const CONFIG_PATH = "user://config.ini"
const RECENT_FILE_COUNT = 5

"""
[settings]
autosave_frequency_minutes=5
reopen_current_file=true

[history]
current_file=
recent_1=
recent_2=
recent_3=
recent_4=
recent_5=
last_folder=
"""

static var config: ConfigFile

const DEFAULT_CONFIG = {
	'settings': {
		'autosave_frequency_minutes': 5,
		'reopen_current_file': true
	},
	'history': {
		'current_file': '',
		'recent_1': '',
		'recent_2': '',
		'recent_3': '',
		'recent_4': '',
		'recent_5': '',
		'last_folder': ''
	}
}

static func save():
	var ok = config.save(CONFIG_PATH)
	Log.print("settings", "Attempting to save to \"" + str(CONFIG_PATH) + "\"")
	if ok != OK:
		Log.push_error("settings", "Unable to save. ConfigFile.save() returned " + str(ok))
	else:
		Log.print("settings", "Saved!")

static func generate_missing_defaults() -> bool:
	var modified = false
	for section in DEFAULT_CONFIG:
		var contents = DEFAULT_CONFIG[section]
		for key in contents:
			var default = contents[key]
			var current = config.get_value(section, key, null)
			
			if current == null:
				Log.print("settings", str(section) + "." + str(key) + " is missing. Creating default of ", default)
				config.set_value(section, key, default)
				modified = true
	return modified

static func begin():
	Log.print("settings", "Begin loading settings")
	config = ConfigFile.new()
	var result = config.load(CONFIG_PATH)
	if generate_missing_defaults():
		Log.print("settings", "Had to load some defaults. saving new settings")
		save()
	Log.print("settings", "Finished loading settings")

static func get_recent_files() -> Array:
	var list = []
	for i in range(RECENT_FILE_COUNT):
		var entry = config.get_value("history", "recent_" + str(i + 1))
		if not entry:
			break
		list.append(entry)
	return list

static func add_recent_file(path: String):
	var recents = get_recent_files()
	var new_recents = [path]
	for i in len(recents):
		var recent = recents[i]
		if recent == path:
			continue
		new_recents.append(recent)
	
	for i in RECENT_FILE_COUNT:
		if i >= len(new_recents):
			config.set_value("history", "recent_" + str(i + 1), "")
		else:
			config.set_value("history", "recent_" + str(i + 1), new_recents[i])
	
	save()
