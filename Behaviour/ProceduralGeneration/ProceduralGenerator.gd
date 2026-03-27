extends Object

class_name ProceduralGenerator

# SoA (Structure of Arrays) : Replace Cell class
var cellX := PackedInt32Array()
var cellY := PackedInt32Array()
var cellDirection := PackedByteArray()
var cellNeighbors := PackedInt32Array()
var cellHeat := PackedInt32Array()
var cellSocketMask := PackedByteArray()
var cellKey := PackedInt64Array()
var cellStructureType := PackedByteArray()

# Internal values
var grid: Dictionary
var frontier := PackedInt32Array()
var frontierHead := 0
var frontierTail := 0
var frontierCount := 0
var inFrontier := PackedByteArray()  # sized to cellNumber, 0 or 1
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

const FULL_MASK = (1 << 4) - 1

# Pre allocated variables for optimization
var frontierIndexChoice: int
var frontierCoefficient: float
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
	cellDirection.fill(255) # Initialy initialized to -1, implicitely 255
	cellHeat.fill(-1)
	cellSocketMask.fill(0)
	
# Internal values initialization (avoid memory leak)
func internalValuesInit() -> void:
	grid = {}
	frontier.resize(cellNumber) # max possible
	frontierHead = 0
	frontierTail = 0
	frontierCount = 0
	inFrontier.resize(cellNumber)
	inFrontier.fill(0)
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
	cellDirection[0] = rng.randi(0, 3)
	inFrontier[0] = 1
	frontier_push(0)
	
	# First phase : graph generation
	# Here we check frontier size to avoid pathological seeds
	while cellCount < cellNumber and frontierCount > 0:
		graphBuildProgression = float(cellCount) / float(cellNumber)
		# Branch Depth Bias
		frontierCoefficient = rng.randf()
		if isFilled or frontierCoefficient < 0.6:
			# Take the last frontier cell
			frontierIndexChoice = frontierCount - 1
		elif frontierCoefficient < 0.85:
			# Take a frontier by entropy, meaning less socketed are priorized
			frontierIndexChoice = highestEntropyFrontier()
		else:
			# Take the oldest frontier made
			frontierIndexChoice = int(frontierCount * rng.randf() * rng.randf())
		frontierIndexChoosen = frontier_get(frontierIndexChoice)
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
		entropicFrontierIndex = rng.randi(0, frontierCount-1)
		entropy = cellSocketMask[frontier_get(entropicFrontierIndex)]
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

func canPlaceRoomXY(size: int) -> bool:
	neighborCount = 0
	var diameter = size  # -half to +half inclusive
	var baseKey = key(choosenCellX - halfRoomSize, choosenCellY - halfRoomSize)
	var rowKey: int
	for x in diameter + 1:
		rowKey = baseKey + (x << 32)  # step x by incrementing upper 32 bits
		for y in diameter + 1:
			if grid.has(rowKey + y):  # step y by incrementing lower 32 bits
				neighborCount += 1
				if neighborCount > size - 1:
					return false
	return true
	
func carveRoomXY():
	var baseKey = key(choosenCellX - halfRoomSize, choosenCellY - halfRoomSize)
	var rowKey: int
	var cellGridKey: int
	for x in range(0, halfRoomSize * 2 + 1):
		rowKey = baseKey + (x << 32)
		for y in range(0, halfRoomSize * 2 + 1):
			cellGridKey = rowKey + y
			roomXCarve = choosenCellX - halfRoomSize + x
			roomYCarve = choosenCellY - halfRoomSize + y
			if grid.has(cellGridKey):
				roomCellIndex = grid[cellGridKey]
			else:
				roomCellIndex = cellCount
				cellX[roomCellIndex] = roomXCarve
				cellY[roomCellIndex] = roomYCarve
				grid[cellGridKey] = roomCellIndex
				cellKey[roomCellIndex] = cellGridKey
				cellCount += 1
				absX = x - halfRoomSize
				if absX < 0: absX = -absX
				absY = y - halfRoomSize
				if absY < 0: absY = -absY
				if absX == halfRoomSize or absY == halfRoomSize:
					if inFrontier[roomCellIndex] == 0:
						inFrontier[roomCellIndex] = 1
						frontier_push(roomCellIndex)
			# Connect internal neighbors
			for dir in 4:
				roomNeighborX = roomXCarve + DX[dir]
				roomNeighborY = roomYCarve + DY[dir]
				absX = roomNeighborX - choosenCellX
				if absX < 0: absX = -absX
				absY = roomNeighborY - choosenCellY
				if absY < 0: absY = -absY
				if absX <= halfRoomSize and absY <= halfRoomSize:
					var neighborKey = cellGridKey + KEY_DIR[dir]
					if grid.has(neighborKey):
						connectCellToCell(roomCellIndex, grid[neighborKey], dir)

func connectCellToCell(idxCellSource: int, idxCellTarget: int, dir: int):
	if cellSocketMask[idxCellSource] & (1 << dir):
		return
	connectOpp = DOPP[dir]
	cellSocketMask[idxCellSource] |= (1 << dir)
	cellSocketMask[idxCellTarget] |= (1 << connectOpp)
	if (
		cellSocketMask[idxCellSource] == FULL_MASK
		and inFrontier[idxCellSource] != -1
	):
		frontier_remove(inFrontier[idxCellSource])
	if (
		cellSocketMask[idxCellTarget] == FULL_MASK
		and inFrontier[idxCellTarget] != -1
	):
		frontier_remove(inFrontier[idxCellTarget])
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
	var noiseX = dirNoise.get_noise_2d(choosenCellX, choosenCellY)
	var noiseY = dirNoise.get_noise_2d(choosenCellX + 1000, choosenCellY + 1000)
	var frontierKeyChoosen =  cellKey[frontierIndexChoosen]
	var dir = cellDirection[frontierIndexChoosen]
	var forbidden = -1
	if dir < 4:
		forbidden = DOPP[dir]
	# O(1) Cyclic direction to avoid a O(n) shuffle
	neighborStartDir = rng.randi(0, 3) # remove after direction bias done
	for i in 4:
		neighborDir = (neighborStartDir + i) & 3
		if forbidden != -1 and  neighborDir == forbidden:
			continue
		neighborDirX = DX[neighborDir]
		neighborDirY = DY[neighborDir]
		neighborGridKey = frontierKeyChoosen + KEY_DIR[neighborDir]
		if (grid.has(neighborGridKey)):
			continue
		if !isFilled:
			# countNeighbors inlined here TOP, RIGHT, DOWN, LEFT
			var mask = int(grid.has(neighborGridKey - 1)) \
				| (int(grid.has(neighborGridKey + (1 << 32))) << 1) \
				| (int(grid.has(neighborGridKey + 1)) << 2) \
				| (int(grid.has(neighborGridKey - (1 << 32))) << 3)
			if isStrictMaze and (mask & (mask - 1)) != 0:
				continue
		neighborX = choosenCellX + neighborDirX
		neighborY = choosenCellY + neighborDirY
		if isFilled and !shape.call(neighborX, neighborY):
			continue
		directionWeight(noiseX, noiseY)
		if isFilled or rng.randf() < neighborWeight:
			frontierDecayRandomizer()
			newNeighborIndex = cellCount
			cellX[newNeighborIndex] = neighborX
			cellY[newNeighborIndex] = neighborY
			cellDirection[newNeighborIndex] = neighborDir
			grid[neighborGridKey] = newNeighborIndex
			cellKey[newNeighborIndex] = neighborGridKey
			cellCount += 1;
			inFrontier[newNeighborIndex] = 1
			frontier_push(newNeighborIndex)
			if isFilled:
				connectAllNeighbors(newNeighborIndex)
			else:
				connectCellToCell(frontierIndexChoosen, newNeighborIndex, neighborDir)
			return
	frontier_remove(frontierIndexChoice)

func directionWeight(noiseX: float, noiseY: float) -> void:
	neighborWeight = 1.0
	neighborWeight += (
		neighborDirX * globalDirectionBias[0] +
		neighborDirY * globalDirectionBias[1]
	) * globalBiasStrength + (
		neighborDirX * noiseX +
		neighborDirY * noiseY
	) * noiseBiasStrength
	if neighborDir == cellDirection[frontierIndexChoosen]:
		neighborWeight += directionMomentum
	neighborWeight = max(neighborWeight, 0.05)

func frontierDecayRandomizer() -> void:
	if frontierCount > 1 and rng.randf() < frontierDecay:
		frontier_remove(rng.randi(0, frontierCount - 1))

func socketRandomConnecter() -> void:
	if 0 >= loopChance:
		return;
	var neighborIndex: int
	# Avoid double check
	var dirCount = 4 if canLoopDoubleCheck else 2
	for idx in range(cellCount):
		for dir in dirCount:
			if cellSocketMask[idx] & (1 << dir):
				continue
			if rng.randf() >= loopChance:
				continue
			neighborIndex = cellNeighbors[(idx << 2)+dir]
			if -1 != neighborIndex:
				connectCellToCell(idx, neighborIndex, dir)

func recomputeHeat():
	var queue := PackedInt32Array()
	queue.append(0)  # let it grow naturally
	cellHeat[0] = 0
	var qi = 0
	var currentIndex: int
	var neighborIndex: int
	var qSize = 1
	while qi < qSize:
		currentIndex = queue[qi]
		qi += 1
		for dir in 4:
			if cellSocketMask[currentIndex] & (1 << dir):
				neighborIndex = cellNeighbors[(currentIndex << 2) + dir]
				if neighborIndex == -1 or cellHeat[neighborIndex] != -1:
					continue
				cellHeat[neighborIndex] = cellHeat[currentIndex] + 1
				queue.append(neighborIndex)
				qSize += 1

func frontier_push(v: int):
	frontier[frontierTail] = v
	frontierTail = (frontierTail + 1) % cellNumber
	frontierCount += 1
	
func frontier_pop() -> int:
	var v = frontier[frontierHead]
	frontierHead = (frontierHead + 1) % cellNumber
	frontierCount -= 1
	return v
	
func frontier_get(i: int) -> int:
	return frontier[(frontierHead + i) % cellNumber]
	
func frontier_remove(i: int):
	# i = logical index (0 → frontierCount-1)

	var real = (frontierHead + i) % cellNumber
	var last = (frontierHead + frontierCount - 1) % cellNumber

	frontier[real] = frontier[last]
	frontierTail = (frontierTail - 1 + cellNumber) % cellNumber
	frontierCount -= 1

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
	inFrontier.clear()
	grid.clear()
	
	# Config values clear
	roomCoefficient.clear()
	roomSizes.clear()
	roomCounts.clear()
	globalDirectionBias.clear()
