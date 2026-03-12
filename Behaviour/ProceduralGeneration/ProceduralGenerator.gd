extends Object

class_name ProceduralGenerator

var deadEndPruneCoefficient = 0.05 # TODO Need to make a pruneDeadEnd engine if a cell neighbors = 1

var grid: Array
var cells: Array = []
var frontier: Array = []
var config: ProceduralGeneratorConfig
var rng: RandomGenerator

func _init(inputConfig: ProceduralGeneratorConfig):
	config = inputConfig
	rng = config.seedHandler.dungeonRng.call(config.id)

func create() -> Array:
	grid = createGrid(config.cellNumber)
	var startCell = Cell.new(Vector2i(config.cellNumber, config.cellNumber))
	
	cells.append(startCell)
	frontier.append(startCell)
	grid[config.cellNumber][config.cellNumber] = startCell
	
	var base
	var corridorCoefficient = 0.6
	
	while cells.size() < config.cellNumber:
		if rng.randf() < corridorCoefficient:
			base = frontier.back()
		else:
			base = rng.pickRandom(frontier)
		placeNeighborCell(base)
	socketRandomConnecter()
	expandRooms()
	
	recomputeHeat(startCell)
	return cells;
	
func createGrid(size: int) -> Array:
	grid = []
	
	for x in range(size * 2 + 1):
		grid.append([])
		for y in range(size * 2 + 1):
			grid[x].append(null)
	
	return grid
	
func placeNeighborCell(currentCell: Cell) -> void:
	var directions = Directions.Cardinal.duplicate()
	rng.shuffle(directions)
	if currentCell.direction != Vector2i.ZERO && rng.randf() < config.directionMomentum:
		directions.erase(currentCell.direction)
		directions.push_front(currentCell.direction)
	for dir in directions:
		var newPos = currentCell.position + dir
		if grid[newPos.x][newPos.y] == null and (not config.isStrictMaze or countNeighbors(newPos) <=1):
			frontierDecayRandomizer()
			var newCell = Cell.new(newPos)
			newCell.direction = dir
			cells.append(newCell)
			frontier.append(newCell)
			grid[newPos.x][newPos.y] = newCell
			currentCell.connectToCell(newCell, dir)
			return
	frontier.erase(currentCell)

func countNeighbors(pos: Vector2i) -> int:

	var count = 0
	for d in Directions.Cardinal:
		var p = pos + d
		if grid[p.x][p.y] != null:
			count += 1
	return count
	
func frontierDecayRandomizer() -> void:
	if frontier.size() > 1 and rng.randf() < config.frontierDecay:
		frontier.erase(rng.pickRandom(frontier))

func socketRandomConnecter() -> void:
	if 0 >= config.loopChance:
		return;
	for i in range(cells.size()):
		var cell = cells[i]
		for dir in Directions.Cardinal:
			# Avoid double check
			if !config.canLoopDoubleCheck and (dir == Vector2i.LEFT or dir == Vector2i.UP):
				continue
			if cell.sockets[dir]:
				continue
			if rng.randf() >= config.loopChance:
				continue
			var p = cell.position + dir
			var neighbor = grid[p.x][p.y]
			if null != neighbor:
				cell.connectToCell(neighbor, dir)
			
func canPlaceRoom(center: Cell, size: int) -> bool:
	var half = int(size / 2.0)
	var neighborCount = 0
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var p = center.position + Vector2i(x, y)
			if 0 > p.x or p.x >= grid.size() or 0 > p.y or p.y >= grid.size():
				return false
			if grid[p.x][p.y] != null:
				neighborCount += 1
				if size < neighborCount:
					return false
	return true
	
func carveRoom(center: Cell, size: int):
	var half = int(size / 2.0)
	for x in range(-half, half + 1):
		for y in range(-half, half + 1):
			var nx = center.position.x + x
			var ny = center.position.y + y
			var cell
			if (grid[nx][ny]):
				cell = grid[nx][ny]
			else:
				cell = Cell.new(Vector2i(nx, ny))
				cells.append(cell)
				grid[nx][ny] = cell
			for dir in Directions.Cardinal:
				var p = cell.position + dir
				var neighbor = grid[p.x][p.y]
				if neighbor != null && insideRoom(center, neighbor.position, half):
					cell.connectToCell(neighbor, dir)

func insideRoom(center, pos, half):
	return (
		abs(pos.x - center.position.x) <= half
		and abs(pos.y - center.position.y) <= half
	)

func expandRooms():
	for size in config.roomCoefficient.keys():
		var coef = config.roomCoefficient[size][0] # TODO use it
		var maxRooms = config.roomCoefficient[size][1]
		var created = 0
		
		# index shuffling insted graph shuffling int < Cell in memory :)
		var order = []
		for i in cells.size():
			order.append(i)
		rng.shuffle(order)
		
		#var baseCells = rng.shuffle(cells) # TODO make a bias by heat here may be ? OR in the config
		for idx in order:
			var cell = cells[idx]
			if created >= maxRooms:
				break
			if canPlaceRoom(cell, size):
				carveRoom(cell, size)
				created += 1

func recomputeHeat(start: Cell):
	for c in cells:
		c.heat = -1
	var queue = [start]
	start.heat = 0
	while queue.size() > 0:
		var current = queue.pop_front()
		for neighbor in current.sockets.values():
			if neighbor == null:
				continue
			if neighbor.heat != -1:
				continue
			neighbor.heat = current.heat + 1
			queue.append(neighbor)
