extends Node2D

var originSeed = 123
var cells = []
var max_heat := 0

var cell_scale := 20
var offset

func _ready():

	var seedHandler = SeedHandler.new(originSeed)
	var config = ProceduralGeneratorConfig.new(seedHandler)
	var generator := ProceduralGenerator.new(config)
	offset = Vector2(-config.cellNumber, -config.cellNumber) * cell_scale + Vector2(500,500)

	cells = generator.create()

	for c in cells:
		if c.heat > max_heat:
			max_heat = c.heat

	queue_redraw()


func _draw():
	draw_string(ThemeDB.fallback_font, Vector2(10,20), str(cells.size()))
	draw_string(ThemeDB.fallback_font, Vector2(10,40), str(originSeed))
	
	for cell in cells:

		var p = offset + Vector2(cell.position) * cell_scale

		for dir in cell.sockets.keys():

			var neighbor = cell.sockets[dir]

			if neighbor != null and neighbor.heat > cell.heat:

				var p2 = offset + Vector2(neighbor.position) * cell_scale
				draw_line(p, p2, Color.GREEN, 2)
				
	for cell in cells:
		var p = offset + Vector2(cell.position) * cell_scale
		var t = float(cell.heat) / max_heat # heat ratio
		var r = lerp(3.0, 6.0, t) # Cell size depending on the heat
		if cell.heat == 0:
			draw_circle(p, r, Color.WHITE) # Start point
		else:
			var color = Color(t, 0, 1.0 - t) # blue to red from heat = 0 to max heat
			draw_circle(p, r, color)
	for cell in cells:
		var p = offset + Vector2(cell.position) * cell_scale
		draw_string(
			ThemeDB.fallback_font,
			p + Vector2(6,-6),
			str(cell.heat),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10
		)
