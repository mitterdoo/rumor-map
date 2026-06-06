extends Control

func _ready():
	var graph = Graph.new()
	
	var curiosity1 = Curiosity.new()
	curiosity1.title = "Hello world"
	
	var note1 = Note.new()
	note1.text = "The quick brown fox jumps over the lazy dog."
	curiosity1.notes.append(note1)
	
	var curiosity2 = Curiosity.new()
	curiosity2.title = "Whoa"
	curiosity2.style = preload("res://graph/node_styles/blue.tres")
	
	var curiosity3 = Curiosity.new()
	curiosity3.title = "Third"
	curiosity3.style = preload("res://graph/node_styles/orange.tres")
	curiosity3.size = 2
	
	var connection1 = Connection.new()
	connection1.destination = curiosity2
	graph.connections[curiosity1] = connection1
	
	var connection2 = Connection.new()
	connection2.destination = curiosity3
	graph.connections[curiosity2] = connection2
	
	var connection3 = Connection.new()
	connection3.destination = curiosity1
	graph.connections[curiosity3] = connection3
	
	graph.curiosities.append(curiosity1)
	graph.curiosities.append(curiosity2)
	graph.curiosities.append(curiosity3)
	
	ResourceSaver.save(graph, "user://hello_world.tres")
