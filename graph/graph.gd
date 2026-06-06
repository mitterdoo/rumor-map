extends Resource
class_name Graph

@export var name: String = "My rumor map"
@export var curiosities: Array[Curiosity]
@export var connections: Dictionary[Curiosity, Array]
@export var styles: Array[NodeStyle]
@export var flags: Array[NodeFlag]
@export var categories: Array[NoteCategory]

func _to_string() -> String:
	return "<Graph \"%s\">" % name

func get_inbound_connections(destination: Curiosity) -> Array:
	## returns an array of [source_curiosity: Curiosity, connection: Connection]
	var result = []
	for source_curiosity: Curiosity in connections:
		var curiosity_connections = connections[source_curiosity]
		for connection: Connection in curiosity_connections:
			if connection.destination == destination:
				result.append([source_curiosity, connection])
	
	return result
