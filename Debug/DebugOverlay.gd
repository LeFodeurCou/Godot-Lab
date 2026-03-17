extends Node2D

class_name DebugOverlay

var text_lines: Array[String] = []

func set_lines(lines: Array[String]) -> void:
	text_lines = lines
	queue_redraw()

func _draw():
	var y := 20
	for line in text_lines:
		draw_string(
			ThemeDB.fallback_font,
			Vector2(10, y),
			line,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			14
		)
		y += 20
