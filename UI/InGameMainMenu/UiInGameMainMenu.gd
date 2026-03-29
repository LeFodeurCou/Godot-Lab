extends CanvasLayer

class_name UiInGameMainMenu

signal resume_requested
signal quit_requested

var pauseAllowed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/ResumeButton.pressed.connect(_onResumePressed)
	$VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitConfirmationDialog.confirmed.connect(_onQuitConfirmed)

func _onResumePressed() -> void:
	resume_requested.emit()

func _onQuitPressed() -> void:
	$ExitConfirmationDialog.popup_centered()

func _onQuitConfirmed() -> void:
	quit_requested.emit()

func open() -> void:
	self.visible = true
	if pauseAllowed:
		get_tree().paused = true
	
func close() -> void:
	self.visible = false
	if pauseAllowed:
		get_tree().paused = false
	
