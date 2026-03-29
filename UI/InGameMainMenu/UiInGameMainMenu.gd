extends UiBase

class_name UiInGameMainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/ResumeButton.pressed.connect(_onResumePressed)
	$VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitConfirmationDialog.confirmed.connect(_onQuitConfirmed)

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
	enterAnimation()

	
func close() -> void:
	if pauseAllowed:
		get_tree().paused = false
	Input.set_mouse_mode(previousMouseMode)
	outAnimation()
	
func enterAnimation() -> void:
	var originalPosY = $VBoxContainer.position.y
	$VBoxContainer.position.y = -300
	var tween = create_tween()
	tween.tween_property($VBoxContainer, "position:y", originalPosY, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func outAnimation() -> void:
	var originalPosY = $VBoxContainer.position.y
	var tween = create_tween()
	tween.tween_property($VBoxContainer, "position:y", -300, 0.3)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	tween.finished.connect(func():
		$VBoxContainer.position.y = originalPosY
		self.visible = false
	)
