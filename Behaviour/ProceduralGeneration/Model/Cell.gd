extends Object

class_name Cell

var position: Vector2i
var sockets:= {}
# TODO add a strong typing variable to define if it's room, corridor, big room etc.
var direction: Vector2i = Vector2i.ZERO
var heat: int = -1

func _init(pos: Vector2i):
	position = pos
	for dir in Directions.Cardinal:
		sockets[dir] = null

func connectToCell(cell: Cell, dir: Vector2i) -> void:
	assert(cell != self)
	
	sockets[dir] = cell
	cell.sockets[Directions.Opposite[dir]] = self
