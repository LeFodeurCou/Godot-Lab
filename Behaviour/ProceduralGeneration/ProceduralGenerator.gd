extends Object

class_name ProceduralGenerator

# SoA (Structure of Arrays) : Replace Cell class
var cellX: Array = PackedInt32Array()
var cellY: Array = PackedInt32Array()
var cellDirection: Array = PackedByteArray()
var cellNeighbors := PackedInt32Array()
var cellHeat: Array = PackedInt32Array()
var cellSocketMask: Array = PackedByteArray()
var cellKey := PackedInt64Array()
var cellStructureType: Array = PackedByteArray()

# Internal values
var grid: Dictionary
var frontier: Array
var cellCount: int
var graphBuildProgression: float

var config: ProceduralGeneratorConfig
# Values from config
var cellNumber: int
var isStrictMaze: bool
var frontierDecay: float
var directionMomentum: float
var corridorCoefficient:float
var rng: RandomGenerator
var roomCoefficient: Dictionary
var roomSizes: Array
var roomCounts: Dictionary
var loopChance: float
var canLoopDoubleCheck: float

# Directions
const DIR_TOP = 0
const DIR_RIGHT = 1
const DIR_DOWN = 2
const DIR_LEFT = 3

# Direction on axe x
# DX[DIR_DOWN] = 0
const DX = [0, 1, 0, -1]
# Direction on axe y
# DY[DIR_DOWN] = 1
const DY = [-1, 0, 1, 0]

# Opposinte Direction indexes
# DX[DOPP[1]] == DX[3]
# DY[DOPP[2]] == DY[0]
# dir = 0 (Top), DOPP[dir] = 2 (Bottom)
const DOPP = [2, 3, 0, 1] 

# Used to compute the adjacent key in the grid
const KEY_DIR = [
	-1,           # up    (y - 1)
	1 << 32,      # right (x + 1)
	1,            # down  (y + 1)
	-(1 << 32)    # left  (x - 1)
]

func _init(inputConfig: ProceduralGeneratorConfig):
	# Always configInit first !!!
	configInit(inputConfig)
	soaClearAndInit()
	internalValuesInit()

# Config initialization to avoid dereferences
func configInit(inputConfig: ProceduralGeneratorConfig) -> void:
	rng = inputConfig.seedHandler.dungeonRng.call(inputConfig.id)
	cellNumber = inputConfig.cellNumber
	isStrictMaze = inputConfig.isStrictMaze
	frontierDecay = inputConfig.frontierDecay
	directionMomentum = inputConfig.directionMomentum
	corridorCoefficient = inputConfig.corridorCoefficient
	roomCoefficient = inputConfig.roomCoefficient
	roomSizes = inputConfig.roomSizes
	roomCounts = {}
	for size in roomSizes:
		roomCounts[size] = 0
	loopChance = inputConfig.loopChance
	canLoopDoubleCheck = inputConfig.canLoopDoubleCheck

func soaClearAndInit() -> void:
	# SoA Cell clear
	cellX.clear()
	cellY.clear()
	cellDirection.clear()
	cellNeighbors.clear()
	cellHeat.clear()
	cellSocketMask.clear()
	cellKey.clear()
	cellStructureType.clear()
	
	# SoA Cell init size
	cellX.resize(cellNumber)
	cellY.resize(cellNumber)
	cellDirection.resize(cellNumber)
	cellNeighbors.resize(cellNumber * 4)
	cellNeighbors.fill(-1)
	cellHeat.resize(cellNumber)
	cellSocketMask.resize(cellNumber)
	cellKey.resize(cellNumber)
	cellStructureType.resize(cellNumber)
	
	# Soa Cell init values
	cellDirection.fill(-1)
	cellHeat.fill(-1)
	cellSocketMask.fill(0)
	
# Internal values initialization (avoid memory leak)
func internalValuesInit() -> void:
	grid = {}
	frontier = []
	cellCount = 1
	graphBuildProgression = 0.0

func create() -> void:
	# First SoA Cell
	cellX[0] = cellNumber
	cellY[0] = cellNumber
	var startKey = key(cellNumber, cellNumber)
	cellKey[0] = startKey
	grid[startKey] = 0
	frontier.append(0)
	
	# First phase : graph generation
	var frontierIndex
	# Here we check frontier size to avoid pathological seeds
	while cellCount < cellNumber and frontier.size() > 0:
		var frontierSize = frontier.size()
		if frontierSize == 1:
			# Take the last frontier it stay after some was removed
			frontierIndex = 0
		elif rng.randf() < 0.9:
			# Take the last frontier cell
			frontierIndex = frontierSize - 1
		else:
			# Take a random frontier cell
			frontierIndex = rng.randi(0, frontierSize - 1)
		if(!placeRoomIfPossible(frontierIndex)):
			placeNeighborCell(frontierIndex)
		graphBuildProgression = float(cellCount) / cellNumber

	# Second phase : optional loops and heat computation
	socketRandomConnecter()
	recomputeHeat()
	
	clearMemory()

func placeRoomIfPossible(frontierIndex: int) -> bool:
	var cellIndex = frontier[frontierIndex]
	var cx = cellX[cellIndex]
	var cy = cellY[cellIndex]
	for size in roomSizes:
		# Avoid overshooting the max cell number
		if cellCount + size * size > cellNumber:
			continue
		var roomConfig = roomCoefficient[size]
		var threshold = roomConfig[2]
		if graphBuildProgression <= threshold:
			continue
		var maxRooms = roomConfig[1]
		if roomCounts[size] >= maxRooms:
			continue
		var coef = roomConfig[0]
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
				cellKey[cellIndex] = gridKey
				cellCount += 1
				if abs(x) == half or abs(y) == half:
					frontier.append(cellIndex)
			# Connect internal neighbors
			for dir in 4:
				var px = nx + DX[dir]
				var py = ny + DY[dir]
				if abs(px - cx) <= half and abs(py - cy) <= half:
					var newGridKey = cellKey[cellIndex] + KEY_DIR[dir]
					if grid.has(newGridKey) && insideRoom(centerCellIndex, px, py, half):
						connectCellToCell(cellIndex, grid[newGridKey], dir)

func connectCellToCell(idxCellSource: int, idxCellTarget: int, dir: int):
	if cellSocketMask[idxCellSource] & (1 << dir):
		return
	var opp = DOPP[dir]
	cellSocketMask[idxCellSource] |= (1 << dir)
	cellSocketMask[idxCellTarget] |= (1 << opp)
	cellNeighbors[idxCellSource * 4 + dir] = idxCellTarget
	cellNeighbors[idxCellTarget * 4 + opp] = idxCellSource

func placeNeighborCell(frontierIndex: int) -> void:
	var cellIndex = frontier[frontierIndex]
	var cx = cellX[cellIndex]
	var cy = cellY[cellIndex]
	# O(1) Cyclic direction to avoid a O(n) shuffle
	var startDir = rng.randi(0, 3)
	for i in 4:
		var dir = (startDir + i) & 3
		if cellDirection[cellIndex] != -1 and i == 0 and rng.randf() < directionMomentum:
			dir = cellDirection[cellIndex]
		var px = cx + DX[dir]
		var py = cy + DY[dir]
		var gridKey = cellKey[cellIndex] + KEY_DIR[dir]
		# countNeighbors inlined here
		var neighborCount = 0
		for ndir in 4:
			if grid.has(key(px + DX[ndir],  py + DY[ndir])):
				neighborCount += 1
		if !grid.has(gridKey) and (not isStrictMaze or neighborCount <= 1):
			frontierDecayRandomizer()
			var newCellIndex = cellCount
			cellX[newCellIndex] = px
			cellY[newCellIndex] = py
			cellDirection[newCellIndex] = dir
			grid[gridKey] = newCellIndex
			cellKey[newCellIndex] = gridKey
			cellCount += 1;
			frontier.append(newCellIndex)
			connectCellToCell(cellIndex, newCellIndex, dir)
			return
	frontierRemove(frontierIndex)
	
func frontierDecayRandomizer() -> void:
	var frontierSize = frontier.size()
	if frontierSize > 1 and rng.randf() < frontierDecay:
		frontierRemove(
			rng.randi(0, frontierSize - 1)
		)

func frontierRemove(i):
	# Swap remove O(1) instead of .erase() O(n)
	var last = frontier.size() - 1
	frontier[i] = frontier[last]
	frontier.pop_back()

func socketRandomConnecter() -> void:
	if 0 >= loopChance:
		return;
	for idx in range(cellCount):
		for dir in 4:
			# Avoid double check
			if !canLoopDoubleCheck and (dir == DIR_LEFT or dir == DIR_RIGHT):
				continue
			if cellSocketMask[idx] & (1 << dir):
				continue
			if rng.randf() >= loopChance:
				continue
			var neighborIndex = cellNeighbors[idx*4+dir]
			if -1 != neighborIndex:
				connectCellToCell(idx, neighborIndex, dir)

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
		for dir in 4:
			if cellSocketMask[currentIndex] & (1 << dir):
				var neighborIndex = cellNeighbors[currentIndex * 4 + dir]
				if -1 == neighborIndex:
					continue
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

# Used in the creat() method at the end to free memory after generatoin ends
# NEVER clear any SoA value here to avoid external bugs :
# SoA value will be used outside the generator by some renderer
func clearMemory() -> void:
	# Internal values clear
	frontier.clear()
	grid.clear()
	
	# Config values clear
	roomCoefficient.clear()
	roomSizes.clear()
	roomCounts.clear()
