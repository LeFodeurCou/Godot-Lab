extends Node3D

class_name Orientable

func applyDirection(direction: Orientation.Cardinal):
	match direction:
		Orientation.Cardinal.NORTH:
			rotation.y = 0
		Orientation.Cardinal.EAST:
			rotation.y = PI/2
		Orientation.Cardinal.SOUTH:
			rotation.y = PI
		Orientation.Cardinal.WEST:
			rotation.y = -PI/2

func rotateTop() -> Node3D:
	applyDirection(Orientation.Cardinal.NORTH)
	return self
	
func rotateRight() -> Node3D:
	applyDirection(Orientation.Cardinal.EAST)
	return self
	
func rotateBottom() -> Node3D:
	applyDirection(Orientation.Cardinal.SOUTH)
	return self
	
func rotateLeft() -> Node3D:
	applyDirection(Orientation.Cardinal.WEST)
	return self
