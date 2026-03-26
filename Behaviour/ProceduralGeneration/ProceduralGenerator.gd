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
var frontier: Array = PackedInt32Array()
var cellCount: int
var graphBuildProgression: float
# Noise bias direction
var dirNoise := FastNoiseLite.new()
# Perlin noise
var biomeNoise := FastNoiseLite.new()

var config: ProceduralGeneratorConfig
# Values from config
var cellNumber: int
var isFilled: bool
var shape: Callable
var isStrictMaze: bool
var frontierDecay: float
var directionMomentum: float
var rng: RandomGenerator
var roomCoefficient: Dictionary
var roomSizes: Array
var roomCounts: Dictionary
var loopChance: float
var canLoopDoubleCheck: float
var globalDirectionBias:= PackedFloat32Array()
var globalBiasStrength: float
var noiseBiasStrength: float

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

# Pre allocated variables for optimization
var frontierIndexChoice: int
var frontierCoefficient: float
var frontierSize: int
var frontierIndexChoosen: int
var choosenCellX: int
var choosenCellY: int
var bestIndex: int
var bestEntropy: int
var entropicFrontierIndex: int
var entropy: int
var neighborCount: int
var roomConfig:= PackedFloat32Array()
var roomBiome: float
var roomThreshold: float
var maxRooms: float # float instead int to avoid narrowing conversion
var roomCoef: float
var halfRoomSize: int
var roomXCheck: int
var roomYCheck: int
var roomXCarve: int
var roomYCarve: int
var roomGridKey: int
var roomCellIndex: int
var roomNeighborX: int
var roomNeighborY: int
var roomNeighborGridKey: int
var connectOpp: int
var connectAllIndex: int
var connectAllNeighborKey: int
var connectAllNeighborIndex: int
var neighborStartDir: int
var neighborDir: int
var neighborDirX: int
var neighborDirY: int
var neighborGridKey: int
var neighborX: int
var neighborY: int
var neighborWeight: float
var newNeighborIndex: int
var lastFrontierForRemoval: int
var absX: int
var absY: int

func _init(inputConfig: ProceduralGeneratorConfig):
	# Always configInit first !!!
	configInit(inputConfig)
	soaClearAndInit()
	internalValuesInit()

# Config initialization to avoid dereferences
func configInit(inputConfig: ProceduralGeneratorConfig) -> void:
	rng = inputConfig.rng
	cellNumber = inputConfig.cellNumber
	isFilled = inputConfig.isFilled
	shape = inputConfig.shape
	isStrictMaze = inputConfig.isStrictMaze
	frontierDecay = inputConfig.frontierDecay
	directionMomentum = inputConfig.directionMomentum
	roomCoefficient = inputConfig.roomCoefficient
	roomSizes = inputConfig.roomSizes
	roomCounts = {}
	for size in roomSizes:
		roomCounts[size] = 0
	loopChance = inputConfig.loopChance
	canLoopDoubleCheck = inputConfig.canLoopDoubleCheck
	globalDirectionBias = inputConfig.globalDirectionBias
	globalBiasStrength = inputConfig.globalBiasStrength
	noiseBiasStrength = inputConfig.noiseBiasStrength

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
	cellCount = 1
	graphBuildProgression = 0.0
	# Noise direction setup
	dirNoise.seed = rng.randi(0, 2147483647) # 2147483647 is the max int possible
	dirNoise.frequency = 0.05
	# Perlin noise setup
	biomeNoise.seed = rng.randi(0, 2147483647)
	biomeNoise.frequency = 0.02

func create() -> void:
	# First SoA Cell
	cellX[0] = cellNumber
	cellY[0] = cellNumber
	var startKey = key(cellNumber, cellNumber)
	cellKey[0] = startKey
	grid[startKey] = 0
	frontier.append(0)
	
	# First phase : graph generation
	# Here we check frontier size to avoid pathological seeds
	while cellCount < cellNumber and frontier.size() > 0:
		graphBuildProgression = float(cellCount) / float(cellNumber)
		frontierSize = frontier.size()
		# Branch Depth Bias
		frontierCoefficient = rng.randf()
		if isFilled or frontierCoefficient < 0.6:
			# Take the last frontier cell
			frontierIndexChoice = frontierSize - 1
		elif frontierCoefficient < 0.85:
			# Take a frontier by entropy, meaning less socketed are priorized
			frontierIndexChoice = highestEntropyFrontier()
		else:
			# Take the oldest frontier made
			frontierIndexChoice = int(frontierSize * rng.randf() * rng.randf())
		frontierIndexChoosen = frontier[frontierIndexChoice]
		choosenCellX = cellX[frontierIndexChoosen]
		choosenCellY = cellY[frontierIndexChoosen]
		if(!placeRoomIfPossible()):
			placeNeighborCell()

	# Second phase : optional loops and heat computation
	socketRandomConnecter()
	recomputeHeat()
	
	clearMemory()

func highestEntropyFrontier()-> int:
	bestIndex = -1
	# 64 because 63 in binary represent 111111 which means socket for 6 directions
	# 6 directions is made for 3D plan, x/-x, y/-y and z/-z
	bestEntropy = 64
	for i in 5:
		entropicFrontierIndex = rng.randi(0, frontierSize-1)
		entropy = cellSocketMask[frontier[entropicFrontierIndex]]
		if entropy < bestEntropy:
			bestEntropy = entropy
			bestIndex = entropicFrontierIndex
	return bestIndex

func placeRoomIfPossible() -> bool:
	if (isFilled):
		return false
	for size in roomSizes:
		halfRoomSize = size >> 1
		# Avoid overshooting the max cell number
		if cellCount + size * size > cellNumber:
			continue
		roomConfig = roomCoefficient[size]
		roomBiome = (biomeNoise.get_noise_2d(choosenCellX, choosenCellY) + 1.0) * 0.5
		roomThreshold = roomConfig[2] * roomBiome
		if graphBuildProgression <= roomThreshold:
			continue
		maxRooms = roomConfig[1]
		if roomCounts[size] >= maxRooms:
			continue
		roomCoef = roomConfig[0]
		if rng.randf() > roomCoef:
			continue
		if canPlaceRoomXY(size):
			carveRoomXY()
			roomCounts[size] += 1
			return true
	return false

func canPlaceRoomXY(size:int) -> bool:
	# a bit shift to the right is a division by 2
	# eg. 4 is 100, 2 is 10 then 4 >> 1 == 2
	neighborCount = 0
	for x in range(-halfRoomSize, halfRoomSize + 1):
		for y in range(-halfRoomSize, halfRoomSize + 1):
			roomXCheck = choosenCellX + x
			roomYCheck = choosenCellY + y
			if grid.has(key(roomXCheck, roomYCheck)):
				neighborCount += 1
				# if less than size - 1 only the first cell become a room
				# size - 1 to avoid room collapsing
				if neighborCount > size - 1:
					return false
	return true
	
func carveRoomXY():
	for x in range(-halfRoomSize, halfRoomSize + 1):
		for y in range(-halfRoomSize, halfRoomSize + 1):
			roomXCarve = choosenCellX + x
			roomYCarve = choosenCellY + y
			roomGridKey = key(roomXCarve, roomYCarve)
			if grid.has(roomGridKey):
				roomCellIndex = grid[roomGridKey]
			else:
				roomCellIndex = cellCount
				cellX[roomCellIndex] = roomXCarve
				cellY[roomCellIndex] = roomYCarve
				grid[roomGridKey] = roomCellIndex
				cellKey[roomCellIndex] = roomGridKey
				cellCount += 1
				absX = x
				if absX < 0: absX = -absX
				absY = y
				if absY < 0: absY = -absY
				if absX == halfRoomSize or absY == halfRoomSize:
					if roomCellIndex not in frontier:
						frontier.append(roomCellIndex)
			# Connect internal neighbors
			for dir in 4:
				roomNeighborX = roomXCarve + DX[dir]
				roomNeighborY = roomYCarve + DY[dir]
				absX = roomNeighborX - choosenCellX
				if absX < 0: absX = -absX
				absY = roomNeighborY - choosenCellY
				if absY < 0: absY = -absY
				if absX <= halfRoomSize and absY <= halfRoomSize:
					roomNeighborGridKey = cellKey[roomCellIndex] + KEY_DIR[dir]
					if grid.has(roomNeighborGridKey) && insideRoom(frontierIndexChoosen, roomNeighborX, roomNeighborY, halfRoomSize):
						connectCellToCell(roomCellIndex, grid[roomNeighborGridKey], dir)

func connectCellToCell(idxCellSource: int, idxCellTarget: int, dir: int):
	if cellSocketMask[idxCellSource] & (1 << dir):
		return
	connectOpp = DOPP[dir]
	cellSocketMask[idxCellSource] |= (1 << dir)
	cellSocketMask[idxCellTarget] |= (1 << connectOpp)
	cellNeighbors[(idxCellSource << 2 ) + dir] = idxCellTarget
	cellNeighbors[(idxCellTarget << 2 ) + connectOpp] = idxCellSource

func connectAllNeighbors(cellIndex:int) -> void:
	connectAllIndex = cellKey[cellIndex]
	for dir in 4:
		connectAllNeighborKey = connectAllIndex + KEY_DIR[dir]
		if !grid.has(connectAllNeighborKey):
			continue
		connectAllNeighborIndex = grid[connectAllNeighborKey]
		connectCellToCell(cellIndex, connectAllNeighborIndex, dir)

func placeNeighborCell() -> void:
	# O(1) Cyclic direction to avoid a O(n) shuffle
	neighborStartDir = rng.randi(0, 3) # remove after direction bias done
	for i in 4:
		neighborDir = (neighborStartDir + i) & 3
		neighborDirX = DX[neighborDir]
		neighborDirY = DY[neighborDir]
		neighborGridKey = cellKey[frontierIndexChoosen] + KEY_DIR[neighborDir]
		if (grid.has(neighborGridKey)):
			continue
		if !isFilled:
			# countNeighbors inlined here
			neighborCount = 0
			for ndir in 4:
				if grid.has(neighborGridKey + KEY_DIR[ndir]):
					neighborCount += 1
					if neighborCount > 1:
						break
			if isStrictMaze and neighborCount > 1:
				continue
		neighborX = choosenCellX + neighborDirX
		neighborY = choosenCellY + neighborDirY
		if isFilled and !shape.call(neighborX, neighborY):
			continue
		directionWeight()
		if isFilled or rng.randf() < neighborWeight:
			frontierDecayRandomizer()
			newNeighborIndex = cellCount
			cellX[newNeighborIndex] = neighborX
			cellY[newNeighborIndex] = neighborY
			cellDirection[newNeighborIndex] = neighborDir
			grid[neighborGridKey] = newNeighborIndex
			cellKey[newNeighborIndex] = neighborGridKey
			cellCount += 1;
			frontier.append(newNeighborIndex)
			if isFilled:
				connectAllNeighbors(newNeighborIndex)
			else:
				connectCellToCell(frontierIndexChoosen, newNeighborIndex, neighborDir)
			return
	frontierRemove(frontierIndexChoice)

func directionWeight() -> void:
	neighborWeight = 1.0
	neighborWeight += (
		neighborDirX * globalDirectionBias[0] +
		neighborDirY * globalDirectionBias[1]
	) * globalBiasStrength + (
		neighborDirX * dirNoise.get_noise_2d(neighborX, neighborY) +
		neighborDirY * dirNoise.get_noise_2d(neighborX + 1000, neighborY + 1000)
	) * noiseBiasStrength
	if neighborDir == cellDirection[frontierIndexChoosen]:
		neighborWeight += directionMomentum
	neighborWeight = max(neighborWeight, 0.05)

func frontierDecayRandomizer() -> void:
	if frontierSize > 1 and rng.randf() < frontierDecay:
		frontierRemove(
			rng.randi(0, frontierSize - 1)
		)

func frontierRemove(i):
	# Swap remove O(1) instead of .erase() O(n)
	lastFrontierForRemoval = frontierSize - 1
	frontier[i] = frontier[lastFrontierForRemoval]
	frontier.pop_back()

func socketRandomConnecter() -> void:
	if 0 >= loopChance:
		return;
	var neighborIndex: int
	for idx in range(cellCount):
		for dir in 4:
			# Avoid double check
			if !canLoopDoubleCheck and (dir == DIR_LEFT or dir == DIR_RIGHT):
				continue
			if cellSocketMask[idx] & (1 << dir):
				continue
			if rng.randf() >= loopChance:
				continue
			neighborIndex = cellNeighbors[(idx << 2)+dir]
			if -1 != neighborIndex:
				connectCellToCell(idx, neighborIndex, dir)

func insideRoom(centerIndex, x, y, half):
	absX = x - cellX[centerIndex]
	if absX < 0: absX = -absX
	absY = y - cellY[centerIndex]
	if absY < 0: absY = -absY
	return (absX <= half and absY <= half)

func recomputeHeat():
	var startIndex = 0
	cellHeat[startIndex] = 0
	var queue = []
	var qi = 0
	queue.append(startIndex)
	
	# Pre allocation for opti
	var currentIndex: int
	var neighborIndex: int
	while qi < queue.size():
		currentIndex = queue[qi]
		qi += 1
		for dir in 4:
			if cellSocketMask[currentIndex] & (1 << dir):
				neighborIndex = cellNeighbors[(currentIndex << 2) + dir]
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
	globalDirectionBias.clear()
