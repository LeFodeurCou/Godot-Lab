extends Node2D

var originSeed = 123
var generator: ProceduralGenerator
var cells = []
var grid
var max_heat := 0

var cell_scale := 20
var offset

func _ready():
	max_heat = 0
	cells.clear()

	var seedHandler = SeedHandler.new(originSeed)
	var config = ProceduralGeneratorConfig.new(seedHandler)
	generator = ProceduralGenerator.new(config)
	offset = Vector2(-config.cellNumber, -config.cellNumber) * cell_scale + Vector2(500,350)

	generator.create()
	cells = generator.cells
	grid = generator.grid

	for c in cells:
		if c.heat > max_heat:
			max_heat = c.heat

	queue_redraw()


func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(10,20), str(cells.size()))
	draw_string(ThemeDB.fallback_font, Vector2(10,40), str(originSeed))
	
	for cell in cells:

		var p = offset + Vector2(cell.x, cell.y) * cell_scale

		for dir in 4 :
			if cell.socketMask & (1 << dir) > 0:
				var nx = cell.x + Directions.DIR_X[dir]
				var ny = cell.y + Directions.DIR_Y[dir]
				var neighborIndex = grid.get(generator.key(nx, ny), null)
				if neighborIndex == null:
					continue
				var neighbor = cells[neighborIndex]

				if neighbor != null and neighbor.heat > cell.heat:

					var p2 = offset + Vector2(neighbor.x, neighbor.y) * cell_scale
					draw_line(p, p2, Color.GREEN, 2)
				
	for cell in cells:
		var p = offset + Vector2(cell.x, cell.y) * cell_scale
		var t = 0.0
		if max_heat > 0:
			t = float(cell.heat) / max_heat # heat ratio
		var r = lerp(3.0, 6.0, t) # Cell size depending on the heat
		if cell.heat == 0:
			draw_circle(p, r, Color.WHITE) # Start point
		else:
			var color = Color(t, 0, 1.0 - t) # blue to red from heat = 0 to max heat
			draw_circle(p, r, color)
	for cell in cells:
		var p = offset + Vector2(cell.x, cell.y) * cell_scale
		draw_string(
			ThemeDB.fallback_font,
			p + Vector2(6,-6),
			str(cell.heat),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10
		)
