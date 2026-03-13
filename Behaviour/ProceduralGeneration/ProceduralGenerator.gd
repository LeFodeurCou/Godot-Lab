extends Object

class_name ProceduralGenerator

var grid:= {}
#var gridWidth : int
var cells: Array = []
var frontier: Array = []
var config: ProceduralGeneratorConfig
var rng: RandomGenerator
var roomCounts = {}

func _init(inputConfig: ProceduralGeneratorConfig):
	cells.clear()
	frontier.clear()
	roomCounts.clear()
	grid.clear()
	
	config = inputConfig
	rng = config.seedHandler.dungeonRng.call(config.id)
	
	for size in config.roomCoefficient.keys():
		roomCounts[size] = 0

func create() -> void:
	# First cell generation and placement
	var startCell = Cell.new(config.cellNumber, config.cellNumber)
	grid[key(config.cellNumber, config.cellNumber)] = cells.size()
	frontier.append(cells.size())
	cells.append(startCell)
	
	# First phase : graph generation
	var frontierIndex
	while cells.size() < config.cellNumber:
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
	recomputeHeat(startCell)

func placeRoomIfPossible(cellIndex: int) -> bool:
	var cell = cells[frontier[cellIndex]]
	for size in config.roomCoefficient.keys():
		# Avoid overshooting the max cell number
		if cells.size() + size * size > config.cellNumber:
			continue
		var coef = config.roomCoefficient[size][0]
		var maxRooms = config.roomCoefficient[size][1]
		if roomCounts[size] >= maxRooms:
			continue
		if rng.randf() > coef:
			continue
		if canPlaceRoomXY(cell.x, cell.y, size):
			carveRoomXY(cell.x, cell.y, size)
			roomCounts[size] += 1
			return true
	return false

func canPlaceRoomXY(cx:int, cy:int, size:int) -> bool:
	var half = int(size / 2.0)
	var neighborCount = 0
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var px = cx + x
			var py = cy + y
			if grid.get(key(px, py), null) != null:
				neighborCount += 1
				# if less than size - 1 only the first cell become a room
				# size - 1 to avoid room collapsing
				if neighborCount > size - 1:
					return false
	return true
	
func carveRoomXY(cx:int, cy:int, size:int):
	var half = int(size / 2.0)
	var centerCell = cells[grid[key(cx,  cy)]]
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var nx = cx + x
			var ny = cy + y
			var gridKey = key(nx, ny)
			var cell
			if grid.get(gridKey, null) != null:
				cell = cells[grid[gridKey]]
			else:
				cell = Cell.new(nx, ny)
				grid[gridKey] = cells.size()
				if abs(x) == half or abs(y) == half:
					frontier.append(cells.size())
				cells.append(cell)
			# Connect internal neighbors
			for dir in 4:
				var px = cell.x + Directions.DIR_X[dir]
				var py = cell.y + Directions.DIR_Y[dir]
				if abs(px - cx) <= half and abs(py - cy) <= half:
					var newGridKey = key(px,  py)
					if grid.get(newGridKey, null) != null && insideRoom(centerCell, px, py, half):
						cell.connectToCell(cells[grid[newGridKey]], dir)

func placeNeighborCell(cellIndex: int) -> void:
	var cell = cells[frontier[cellIndex]]
	# O(1) Cyclic direction to avoid a O(n) shuffle
	var startDir = rng.randi(0, 3)
	for i in 4:
		var dir = (startDir + i) & 3
		if cell.direction != -1 and i == 0 and rng.randf() < config.directionMomentum:
			dir = cell.direction
		var px = cell.x + Directions.DIR_X[dir]
		var py = cell.y + Directions.DIR_Y[dir]
		var gridKey = key(px, py)
		if grid.get(gridKey, null) == null and (not config.isStrictMaze or countNeighbors(px, py) <= 1):
			frontierDecayRandomizer()
			var newCell = Cell.new(px, py)
			newCell.direction = dir
			grid[gridKey] = cells.size()
			frontier.append(cells.size())
			cells.append(newCell)
			cell.connectToCell(newCell, dir)
			return
	frontierRemove(cellIndex)

func countNeighbors(x: int, y: int) -> int:
	var count = 0
	for dir in 4:
		var px = x + Directions.DIR_X[dir]
		var py = y + Directions.DIR_Y[dir]
		if grid.get(key(px,  py), null) != null:
			count += 1
	return count
	
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
	for i in range(cells.size()):
		var cell = cells[i]
		for dir in 4:
			# Avoid double check
			if !config.canLoopDoubleCheck and (dir == Directions.DIR_LEFT or dir == Directions.DIR_RIGHT):
				continue
			if cell.socketMask & (1 << dir) > 0:
				continue
			if rng.randf() >= config.loopChance:
				continue
			var px = cell.x + Directions.DIR_X[dir]
			var py = cell.y + Directions.DIR_Y[dir]
			var neighborIndex = grid.get(key(px, py), null)
			if null != neighborIndex:
				cell.connectToCell(cells[neighborIndex], dir)

func insideRoom(center, x, y, half):
	return (
		abs(x - center.x) <= half
		and abs(y - center.y) <= half
	)

func recomputeHeat(start: Cell):
	start.heat = 0
	var queue = []
	var qi = 0
	queue.append(start)
	while qi < queue.size():
		var current = queue[qi]
		qi += 1
		
		for dir in 4:
			if current.socketMask & (1 << dir) > 0:
				var nx = current.x + Directions.DIR_X[dir]
				var ny = current.y + Directions.DIR_Y[dir]
				var neighborIndex = grid.get(key(nx, ny), null)
				if neighborIndex == null:
					continue
				var neighbor = cells[neighborIndex]
				if neighbor.heat != -1:
					continue
				neighbor.heat = current.heat + 1
				queue.append(neighbor)

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
