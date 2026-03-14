extends Node2D

var originSeed = 123
var generator: ProceduralGenerator
var grid
var max_heat := 0

# SoA (Structure of Arrays) : Replace Cell class
var cellX: Array = []
var cellY: Array = []
var cellDirection: Array = []
var cellHeat: Array = []
var cellSocketMask: Array = []
var cellStructureType: Array = []
var cellCount: int = 0;

var cell_scale := 20
var offset

# Timer
var start
var end
var elapsed

func _ready():
	# SoA Cell clear
	cellX.clear()
	cellY.clear()
	cellDirection.clear()
	cellHeat.clear()
	cellSocketMask.clear()
	cellStructureType.clear()
	
	max_heat = 0

	var seedHandler = SeedHandler.new(originSeed)
	var config = ProceduralGeneratorConfig.new(seedHandler)
	generator = ProceduralGenerator.new(config)
	offset = Vector2(-config.cellNumber, -config.cellNumber) * cell_scale + Vector2(500,350)

	start = Time.get_ticks_usec()
	generator.create()
	end = Time.get_ticks_usec()
	elapsed = (end - start) / 1000.0
	
	cellX = generator.cellX
	cellY = generator.cellY
	cellDirection = generator.cellDirection
	cellHeat = generator.cellHeat
	cellSocketMask = generator.cellSocketMask
	cellStructureType = generator.cellStructureType
	grid = generator.grid
	cellCount = generator.cellCount

	for heat in cellHeat:
		if heat > max_heat:
			max_heat = heat

	queue_redraw()


func _draw():
	
	# Draw links
	for cellIdx in cellCount:

		var p = offset + Vector2(cellX[cellIdx], cellY[cellIdx]) * cell_scale

		for dir in 4 :
			if cellSocketMask[cellIdx] & (1 << dir):
				var nx = cellX[cellIdx] + Directions.DIR_X[dir]
				var ny = cellY[cellIdx] + Directions.DIR_Y[dir]
				var neighborIndex = grid.get(generator.key(nx, ny), null)
				if neighborIndex == null:
					continue
				if cellHeat[neighborIndex] > cellHeat[cellIdx]:

					var p2 = offset + Vector2(cellX[neighborIndex], cellY[neighborIndex]) * cell_scale
					draw_line(p, p2, Color.GREEN, 2)
				
	# Draw cells above links
	for cellIdx in cellCount:
		var p = offset + Vector2(cellX[cellIdx], cellY[cellIdx]) * cell_scale
		var t = 0.0
		if max_heat > 0:
			t = float(cellHeat[cellIdx]) / max_heat # heat ratio
		var r = lerp(3.0, 6.0, t) # Cell size depending on the heat
		if cellHeat[cellIdx] == 0:
			draw_circle(p, r, Color.WHITE) # Start point
		else:
			var color = Color(t, 0, 1.0 - t) # blue to red from heat = 0 to max heat
			draw_circle(p, r, color)
	# Draw heat on top right of cells
	for cellIdx in cellCount:
		var p = offset + Vector2(cellX[cellIdx], cellY[cellIdx]) * cell_scale
		draw_string(
			ThemeDB.fallback_font,
			p + Vector2(6,-6),
			str(cellHeat[cellIdx]),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10
		)
	
	# Draw meta data
	draw_string(ThemeDB.fallback_font, Vector2(10,20), str("Cells : ", cellCount))
	draw_string(ThemeDB.fallback_font, Vector2(10,40), str("Seed : ", originSeed))
	draw_string(ThemeDB.fallback_font, Vector2(10,60), str("Gen in : ", elapsed, "ms"))
		
