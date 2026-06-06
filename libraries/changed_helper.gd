extends Object
class_name ChangedHelper

static func handle_connection(old: Resource, new: Resource, callable: Callable):
	if old != null and old.changed.is_connected(callable):
		old.changed.disconnect(callable)
	if new != null:
		new.changed.connect(callable)
