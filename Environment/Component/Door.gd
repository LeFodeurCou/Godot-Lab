extends Object

class_name Door

var width: float

var height: float

static func create(w: float, h: float) -> Door:
	var door = Door.new()
	door.width = w
	door.height = h
	return door
