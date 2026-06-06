extends Notable
class_name Curiosity
## A node in the graph
## Represents a topic, person, place, or thing of interest to the user
## Connections are handled by the containing Graph

@export var title: String
@export var style: NodeStyle = preload("node_styles/white.tres")
@export var image: Texture2D
@export var size: int = 0
@export var position: Vector2
	
@export var flags: Array[NodeFlag]

func _to_string() -> String:
	return "<Curiosity \"%s\">" % title
