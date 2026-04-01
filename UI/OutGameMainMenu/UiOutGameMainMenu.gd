extends UiBase

class_name UiOutGameMainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/VBoxContainer/NewGameButton.pressed.connect(_onNewGamePressed)
	$ColorRect/VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitConfirmationDialog.confirmed.connect(_onQuitConfirmed)

func _onNewGamePressed() -> void:
	Game.loadNewGame()
	
func _onQuitPressed() -> void:
	$ExitConfirmationDialog.popup_centered()
	
func _onQuitConfirmed() -> void:
	Game.quit()
	
func open() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func requestClose():
	Input.set_mouse_mode(previousMouseMode)
	_onQuitPressed()
