extends Node3D

class_name WorldGenerator

var debugRoot: Node3D

# SoA (Structure of Arrays) : Replace Cell class
var cellX: Array = PackedInt32Array()
var cellY: Array = PackedInt32Array()
var cellDirection: Array = PackedByteArray()
var cellNeighbors := PackedInt32Array()
var cellHeat: Array = PackedInt32Array()
var cellSocketMask: Array = PackedByteArray()
var cellStructureType: Array = PackedByteArray()
var cellCount: int = 0;

# TODO pass through config after
var roomWidth = 10
var roomDepth = 10
var wallHeight = 8
var wallThickeness = 2
var floorThickeness = 2

var floorFactory = preload("res://Environment/Component/Floor.gd")
var wallFactory = preload("res://Environment/Component/Wall.gd")

# Direction on axe x
# DX[DIR_DOWN] = 0
const DX = [0, 1, 0, -1]
# Direction on axe z
# DZ[DIR_DOWN] = 1
const DZ = [-1, 0, 1, 0]

func _init(generator: ProceduralGenerator) -> void:
	Game.connectPlayerDebug(self)
	# SoA Cell clear
	cellX.clear()
	cellY.clear()
	cellDirection.clear()
	cellNeighbors.clear()
	cellHeat.clear()
	cellSocketMask.clear()
	cellStructureType.clear()
	
	generator.create()
	
	cellX = generator.cellX
	cellY = generator.cellY
	cellDirection = generator.cellDirection
	cellNeighbors = generator.cellNeighbors
	cellHeat = generator.cellHeat
	cellSocketMask = generator.cellSocketMask
	cellStructureType = generator.cellStructureType
	cellCount = generator.cellCount

func _onDebugToggled(value: bool) -> void:
	if debugRoot:
		debugRoot.visible = value

func generate(world: Node3D) -> Vector3i:
	debugRoot = Node3D.new()
	debugRoot.visible = Game.player.isDebug
	debugRoot.name = "DebugRoot"
	world.add_child(debugRoot)
	var originX = cellX[0]
	var originY = cellY[0]
	for cellIdx in range(cellCount):
		var x = (cellX[cellIdx] - originX) * roomWidth
		var z = (cellY[cellIdx] - originY) * roomDepth
		makeFloor(world, x, z)
		checkNeighbors(world, cellIdx, x, z)
		debugLabels(cellIdx, x, z)
	return Vector3i(0, floorThickeness >> 1, 0)
	
func makeFloor(world: Node3D, x: int, z: int) -> void:
	world.add_child(
		floorFactory.create(
			"Floor",
			Vector3(roomWidth, 2, roomDepth),
			Vector3(x, 0, z)
		)
	)
	
func checkNeighbors(world: Node3D, cellIdx: int, x: int, z: int) -> void:
		for dir in 4 :
				var wall: Wall
				if cellSocketMask[cellIdx] & (1 << dir):
					continue # Place real links here
				else:
					wall = makeWall(
						x + (DX[dir] * roomWidth >> 1),
						z + (DZ[dir] * roomDepth >> 1)
					)
				if null != wall and dir % 2 != 0:
					wall.rotateLeft()
				world.add_child(wall)
	
func makeWall(x: int, z: int) -> Wall:
	return wallFactory.create(
			"Wall",
			Vector3(roomWidth + wallThickeness, wallHeight, wallThickeness),
			Vector3(x, wallHeight / 2.0 - floorThickeness, z)
		)

func debugLabels(cellIdx: int, x: int, z:int) -> void:
	var label = Label3D.new()
	label.text = str(cellHeat[cellIdx])
	label.font_size = 320
	label.position = Vector3(x, 3, z)
	debugRoot.add_child(label)
