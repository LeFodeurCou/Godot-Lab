extends CanvasLayer

class_name ScreenTransition

var rect: ColorRect

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 🔥 Create full screen black rect
	rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.visible = false
	# 🔥 Important: full screen anchors
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(rect)

func fade_out(duration: float = 0.3) -> void:
	get_tree().paused = true
	rect.visible = true
	rect.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration: float = 0.3) -> void:
	rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished
	rect.visible = false
	get_tree().paused = false
