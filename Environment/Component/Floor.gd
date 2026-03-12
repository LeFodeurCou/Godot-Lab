extends Object


static func create(name: String, size: Vector3, position: Vector3) -> Node3D:
	var floorMesh = MeshInstance3D.new()
	floorMesh.mesh = BoxMesh.new()
	floorMesh.scale = size
	floorMesh.position = position
	
	var floorCollision = CollisionShape3D.new()
	floorCollision.shape = BoxShape3D.new()
	floorCollision.shape.size = size
	floorCollision.position = position
	
	var floorBody = StaticBody3D.new()
	floorBody.name = "Ground"
	floorBody.collision_layer = 2
	floorBody.collision_mask = 0
	floorBody.position = position
	floorBody.add_child(floorMesh)
	floorBody.add_child(floorCollision)
	return floorBody
