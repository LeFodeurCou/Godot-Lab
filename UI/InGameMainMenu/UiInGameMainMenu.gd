extends UiBase

class_name UiInGameMainMenu

var originalPosY: float

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/ResumeButton.pressed.connect(_onResumePressed)
	$VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitConfirmationDialog.confirmed.connect(_onQuitConfirmed)
	originalPosY = $VBoxContainer.position.y

func _onResumePressed() -> void:
	requestClose()

func _onQuitPressed() -> void:
	$ExitConfirmationDialog.popup_centered()

func _onQuitConfirmed() -> void:
	Game.quit()

func open() -> void:
	self.visible = true
	if pauseAllowed:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await enterAnimation()

	
func close() -> void:
	if pauseAllowed:
		get_tree().paused = false
	Input.set_mouse_mode(previousMouseMode)
	await outAnimation()
	$VBoxContainer.position.y = originalPosY
	self.visible = false
	
func enterAnimation() -> Signal:
	$VBoxContainer.position.y = -300
	var tween = create_tween()
	tween.tween_property($VBoxContainer, "position:y", originalPosY, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	return tween.finished

func outAnimation() -> Signal:
	var tween = create_tween()
	tween.tween_property($VBoxContainer, "position:y", -300, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	return tween.finished
