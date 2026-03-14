extends Object

class_name ProceduralGenerator

# SoA (Structure of Arrays) : Replace Cell class
var cellX: Array = PackedInt32Array()
var cellY: Array = PackedInt32Array()
var cellDirection: Array = PackedByteArray()
var cellHeat: Array = PackedInt32Array()
var cellSocketMask: Array = PackedByteArray()
var cellStructureType: Array = PackedByteArray()
var cellCount: int = 1

var grid:= {}
var frontier: Array = []
var config: ProceduralGeneratorConfig
var rng: RandomGenerator
var roomCounts:= {}

const DX = Directions.DIR_X
const DY = Directions.DIR_Y

func _init(inputConfig: ProceduralGeneratorConfig):
	config = inputConfig
	rng = config.seedHandler.dungeonRng.call(config.id)
	
	# SoA Cell clear
	cellX.clear()
	cellY.clear()
	cellDirection.clear()
	cellHeat.clear()
	cellSocketMask.clear()
	cellStructureType.clear()
	
	# SoA Cell init size
	cellX.resize(config.cellNumber)
	cellY.resize(config.cellNumber)
	cellDirection.resize(config.cellNumber)
	cellHeat.resize(config.cellNumber)
	cellSocketMask.resize(config.cellNumber)
	cellStructureType.resize(config.cellNumber)
	
	# Soa Cell init values
	cellDirection.fill(-1)
	cellHeat.fill(-1)
	cellSocketMask.fill(0)
	
	frontier.clear()
	roomCounts.clear()
	grid.clear()
	
	for size in config.roomSizes:
		roomCounts[size] = 0

func create() -> void:
	# First SoA Cell
	cellX[0] = config.cellNumber
	cellY[0] = config.cellNumber
	grid[key(config.cellNumber, config.cellNumber)] = 0
	frontier.append(0)
	
	# First phase : graph generation
	var frontierIndex
	# Here we check frontier size to avoid pathological seeds
	while cellCount < config.cellNumber and frontier.size() > 0:
		if rng.randf() < config.corridorCoefficient:
			# Take the last frontier cell
			frontierIndex = frontier.size() - 1
		else:
			# Take a random frontier cell
			frontierIndex = rng.randi(0, frontier.size() - 1)
		if(!placeRoomIfPossible(frontierIndex)):
			placeNeighborCell(frontierIndex)

	# Second phase : optional loops and heat computation
	socketRandomConnecter()
	recomputeHeat()

func placeRoomIfPossible(frontierIndex: int) -> bool:
	var cellIndex = frontier[frontierIndex]
	var cx = cellX[cellIndex]
	var cy = cellY[cellIndex]
	for size in config.roomSizes:
		# Avoid overshooting the max cell number
		if cellCount + size * size > config.cellNumber:
			continue
		var coef = config.roomCoefficient[size][0]
		var maxRooms = config.roomCoefficient[size][1]
		if roomCounts[size] >= maxRooms:
			continue
		if rng.randf() > coef:
			continue
		if canPlaceRoomXY(cx, cy, size):
			carveRoomXY(cx, cy, size)
			roomCounts[size] += 1
			return true
	return false

func canPlaceRoomXY(cx:int, cy:int, size:int) -> bool:
	# a bit shift to the right is a division by 2
	# eg. 4 is 100, 2 is 10 then 4 >> 1 == 2
	var half = size >> 1
	var neighborCount = 0
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var px = cx + x
			var py = cy + y
			if grid.has(key(px, py)):
				neighborCount += 1
				# if less than size - 1 only the first cell become a room
				# size - 1 to avoid room collapsing
				if neighborCount > size - 1:
					return false
	return true
	
func carveRoomXY(cx:int, cy:int, size:int):
	var half = int(size / 2.0)
	var centerCellIndex = grid[key(cx,  cy)]
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var nx = cx + x
			var ny = cy + y
			var gridKey = key(nx, ny)
			var cellIndex
			if grid.has(gridKey):
				cellIndex = grid[gridKey]
			else:
				cellIndex = cellCount
				cellX[cellIndex] = nx
				cellY[cellIndex] = ny
				grid[gridKey] = cellIndex
				cellCount += 1
				if abs(x) == half or abs(y) == half:
					frontier.append(cellIndex)
			# Connect internal neighbors
			for dir in 4:
				var px = nx + DX[dir]
				var py = ny + DY[dir]
				if abs(px - cx) <= half and abs(py - cy) <= half:
					var newGridKey = key(px,  py)
					if grid.has(newGridKey) && insideRoom(centerCellIndex, px, py, half):
						connectCellToCell(cellIndex, grid[newGridKey], dir)

func connectCellToCell(idxCellSource: int, idxCellTarget: int, dir: int):
	cellSocketMask[idxCellSource] |= (1 << dir)
	cellSocketMask[idxCellTarget] |= (1 << Directions.OPP[dir])

func placeNeighborCell(frontierIndex: int) -> void:
	var cellIndex = frontier[frontierIndex]
	var cx = cellX[cellIndex]
	var cy = cellY[cellIndex]
	# O(1) Cyclic direction to avoid a O(n) shuffle
	var startDir = rng.randi(0, 3)
	for i in 4:
		var dir = (startDir + i) & 3
		if cellDirection[cellIndex] != -1 and i == 0 and rng.randf() < config.directionMomentum:
			dir = cellDirection[cellIndex]
		var px = cx + DX[dir]
		var py = cy + DY[dir]
		var gridKey = key(px, py)
		# countNeighbors inlined here
		var neighborCount = 0
		for ndir in 4:
			if grid.has(key(px + DX[ndir],  py + DY[ndir])):
				neighborCount += 1
		if !grid.has(gridKey) and (not config.isStrictMaze or neighborCount <= 1):
			frontierDecayRandomizer()
			var newCellIndex = cellCount
			cellX[newCellIndex] = px
			cellY[newCellIndex] = py
			cellDirection[newCellIndex] = dir
			grid[gridKey] = newCellIndex
			cellCount += 1;
			frontier.append(newCellIndex)
			connectCellToCell(cellIndex, newCellIndex, dir)
			return
	frontierRemove(frontierIndex)
	
func frontierDecayRandomizer() -> void:
	var frontierSize = frontier.size()
	if frontierSize > 1 and rng.randf() < config.frontierDecay:
		frontierRemove(
			rng.randi(0, frontierSize - 1)
		)

func frontierRemove(i):
	# Swap remove O(1) instead of .erase() O(n)
	var last = frontier.size() - 1
	frontier[i] = frontier[last]
	frontier.pop_back()

func socketRandomConnecter() -> void:
	if 0 >= config.loopChance:
		return;
	for idx in range(cellCount):
		var cx = cellX[idx]
		var cy = cellY[idx]
		
		for dir in 4:
			# Avoid double check
			if !config.canLoopDoubleCheck and (dir == Directions.DIR_LEFT or dir == Directions.DIR_RIGHT):
				continue
			if cellSocketMask[idx] & (1 << dir):
				continue
			if rng.randf() >= config.loopChance:
				continue
			var px = cx + DX[dir]
			var py = cy + DY[dir]
			var gridKey = key(px, py)
			if grid.has(gridKey):
				connectCellToCell(idx, grid[gridKey], dir)

func insideRoom(centerIndex, x, y, half):
	return (
		abs(x - cellX[centerIndex]) <= half
		and abs(y - cellY[centerIndex]) <= half
	)

func recomputeHeat():
	var startIndex = 0
	cellHeat[startIndex] = 0
	var queue = []
	var qi = 0
	queue.append(startIndex)
	while qi < queue.size():
		var currentIndex = queue[qi]
		qi += 1
		var cx = cellX[currentIndex]
		var cy = cellY[currentIndex]
		for dir in 4:
			if cellSocketMask[currentIndex] & (1 << dir):
				var nx = cx + DX[dir]
				var ny = cy + DY[dir]
				var gridKey = key(nx, ny)
				if !grid.has(gridKey):
					continue
				var neighborIndex = grid.get(gridKey)
				if cellHeat[neighborIndex] != -1:
					continue
				cellHeat[neighborIndex] = cellHeat[currentIndex] + 1
				queue.append(neighborIndex)

# Store x and y as only one int using bitwise operation to save performances and memory
# << 32 will move bits to "32 bit to left"
# & 0xffffffff is used to only keep the 32 last bits
# result layout : xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy
# 32 bit x and 32 bit y
# Used with a dictionary, eg :
# var grid = {}
# grid[key(x, y)] = value
# var value = grid.get(key(x, y), null) where null is a default value
# null != grid.get(key(x, y), null)
func key(x:int, y:int) -> int:
	return (x << 32) | (y & 0xffffffff)
