extends Object

class_name Cell

var x: int
var y: int
# TODO add a strong typing variable to define if it's room, corridor, big room etc.
var direction: int = -1
var heat: int = -1
var socketMask = 0

func _init(px: int, py: int):
	x = px
	y = py

func connectToCell(cell: Cell, dir: int) -> void:
	assert(cell != self)
	
	# binary socketing
	socketMask |= (1 << dir)
	cell.socketMask |= (1 << Directions.OPP[dir])
	
