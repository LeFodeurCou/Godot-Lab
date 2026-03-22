extends Node

var portalBackTarget: String

func _ready() -> void:
	self.name = "World000003"
	
	var roomWidth = 60
	var roomDepth = 60
	var wallHeight = 10
	var wallThickeness = 2
	
	var floorFactory = preload("res://Environment/Component/Floor.gd")
	
	self.add_child(
		floorFactory.create(
			"Floor",
			Vector3(roomWidth, 2, roomDepth),
			Vector3(0, 0, 0)
		)
	)
	
	var wallFactory = preload("res://Environment/Component/DoorWall.gd")
	
	var door = preload("res://Environment/Component/Door.gd").create(
		roomWidth / 12.0,
		wallHeight / 2.0
	)
	
	#Walls
	self.add_child(
		wallFactory.create(
			"TopWall",
			Vector3(roomWidth, wallHeight, wallThickeness),
			Vector3(0, wallHeight / 2.0, -roomDepth / 2.0),
			door
		).rotateTop()
	)
	
	self.add_child(
		wallFactory.create(
			"RightWall",
			Vector3(roomDepth, wallHeight, wallThickeness),
			Vector3(roomWidth / 2.0, wallHeight / 2.0, 0),
			door
		).rotateRight()
	)
	self.add_child(
		wallFactory.create(
			"BottomWall",
			Vector3(roomWidth, wallHeight, wallThickeness),
			Vector3(0, wallHeight / 2.0, roomDepth / 2.0),
			door
		).rotateBottom()
	)
	
	self.add_child(
		wallFactory.create(
			"LeftWall",
			Vector3(roomDepth, wallHeight, wallThickeness),
			Vector3(-roomWidth / 2.0, wallHeight / 2.0, 0),
			door
		).rotateLeft()
	)
	
	var lightFactory = preload("res://Environment/Component/Light.gd")
	self.add_child(
		lightFactory.create()
	)
	
	 #Portal backp
	var portalScene = preload("res://Environment/Portal/portal.tscn")
	var portal = portalScene.instantiate()
	portal.targetWorld = portalBackTarget
	portal.position = Vector3(roomWidth / 2.0 - roomWidth / 4.0, 0, roomDepth / 2.0 - roomDepth / 4.0)
	self.add_child(portal)
