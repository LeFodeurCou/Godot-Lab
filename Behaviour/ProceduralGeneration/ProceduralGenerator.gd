extends Object

class_name ProceduralGenerator

var deadEndPruneCoefficient = 0.05 # TODO Need to make a pruneDeadEnd engine if a cell neighbors = 1

var grid: Array
var gridWidth : int
var cells: Array = []
var frontier: Array = []
var config: ProceduralGeneratorConfig
var rng: RandomGenerator
var roomCounts = {}

func _init(inputConfig: ProceduralGeneratorConfig):
	config = inputConfig
	rng = config.seedHandler.dungeonRng.call(config.id)

func create() -> Array:
	cells.clear()
	frontier.clear()
	roomCounts.clear()

	for size in config.roomCoefficient.keys():
		roomCounts[size] = 0
	
	gridWidth = config.cellNumber * 2 + 1
	grid = createGrid()
	var startCell = Cell.new(config.cellNumber, config.cellNumber)
	
	
	grid[config.cellNumber + config.cellNumber * gridWidth] = cells.size()
	cells.append(startCell)
	frontier.append(startCell)
	
	var base
	
	while cells.size() < config.cellNumber:
		if rng.randf() < config.corridorCoefficient:
			base = frontier.back()
		else:
			base = rng.pickRandom(frontier)
		if(!placeRoomIfPossible(base)):
			placeNeighborCell(base)
	socketRandomConnecter()
	
	recomputeHeat(startCell)
	return cells;
	
func createGrid() -> Array:
	grid = []
	grid.resize(gridWidth * gridWidth)
	return grid

func placeRoomIfPossible(currentCell: Cell) -> bool:
	for size in config.roomCoefficient.keys():
		var coef = config.roomCoefficient[size][0]
		var maxRooms = config.roomCoefficient[size][1]
		if roomCounts[size] >= maxRooms:
			continue
		if rng.randf() > coef:
			continue
		if canPlaceRoomXY(currentCell.x, currentCell.y, size):
			carveRoomXY(currentCell.x, currentCell.y, size)
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
			if px < 0 or py < 0 or px >= gridWidth or py >= gridWidth:
				return false
			var gridI = px + py * gridWidth
			if grid[gridI] != null:
				neighborCount += 1
				# if less than size - 1 only the first cell become a room
				# size - 1 to avoid room collapsing
				if neighborCount > size - 1:
					return false
	return true
	
func carveRoomXY(cx:int, cy:int, size:int):
	var half = int(size / 2.0)
	var centerCell = cells[grid[cx + cy * gridWidth]]
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var nx = cx + x
			var ny = cy + y
			var gi = nx + ny * gridWidth
			var cell
			if grid[gi] != null:
				cell = cells[grid[gi]]
			else:
				cell = Cell.new(nx, ny)
				grid[gi] = cells.size()
				cells.append(cell)
			# connect internal neighbors
			for dir in 4:
				var px = cell.x + Directions.DIR_X[dir]
				var py = cell.y + Directions.DIR_Y[dir]
				if abs(px - cx) <= half and abs(py - cy) <= half:
					var ngi = px + py * gridWidth
					if grid[ngi] != null && insideRoom(centerCell, px, py, half):
						cell.connectToCell(cells[grid[ngi]], dir)
					if abs(x) == half or abs(y) == half:
						frontier.append(cell)

func placeNeighborCell(currentCell: Cell) -> void:
	var shuffledDirections = rng.shuffle([
		Directions.DIR_UP,
		Directions.DIR_RIGHT,
		Directions.DIR_DOWN,
		Directions.DIR_LEFT
	])
	if currentCell.direction != -1 && rng.randf() < config.directionMomentum:
		shuffledDirections.erase(currentCell.direction)
		shuffledDirections.push_front(currentCell.direction)
	for dir in shuffledDirections:
		var px = currentCell.x + Directions.DIR_X[dir]
		var py = currentCell.y + Directions.DIR_Y[dir]
		var gridI = px + py * gridWidth
		if grid[gridI] == null and (not config.isStrictMaze or countNeighbors(px, py) <=1):
			frontierDecayRandomizer()
			var newCell = Cell.new(px, py)
			newCell.direction = dir
			grid[gridI] = cells.size()
			cells.append(newCell)
			frontier.append(newCell)
			currentCell.connectToCell(newCell, dir)
			return
	frontier.erase(currentCell)

func countNeighbors(x: int, y: int) -> int:
	var count = 0
	for dir in 4:
		var px = x + Directions.DIR_X[dir]
		var py = y + Directions.DIR_Y[dir]
		if grid[px + py * gridWidth] != null:
			count += 1
	return count
	
func frontierDecayRandomizer() -> void:
	var frontierSize = frontier.size()
	if frontierSize > 1 and rng.randf() < config.frontierDecay:
		var i = rng.randi(0, frontierSize - 1)
		var last = frontierSize - 1
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
			if cell.sockets[dir]:
				continue
			if rng.randf() >= config.loopChance:
				continue
			var px = cell.x + Directions.DIR_X[dir]
			var py = cell.y + Directions.DIR_Y[dir]
			var neighborIndex = grid[px + py * gridWidth]
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
		for neighbor in current.sockets:
			if neighbor == null:
				continue
			if neighbor.heat != -1:
				continue
			neighbor.heat = current.heat + 1
			queue.append(neighbor)
