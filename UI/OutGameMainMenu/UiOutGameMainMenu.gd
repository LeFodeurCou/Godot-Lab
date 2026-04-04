extends UiBase

class_name UiOutGameMainMenu

var subMenus = {
	settings = "res://UI/Settings/UiSettingsPanel.tscn"
}

var uiSettingsPanel: UiBase

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("UI")
	refreshLocalization()
	$ColorRect/VBoxContainer/NewGameButton.pressed.connect(_onNewGamePressed)
	$ColorRect/VBoxContainer/SettingsButton.pressed.connect(_onSettingsPressed)
	$ColorRect/VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitConfirmationDialog.confirmed.connect(_onQuitConfirmed)

func _onNewGamePressed() -> void:
	Game.loadNewGame()
	
func _onSettingsPressed() -> void:
	if uiSettingsPanel:
		Game.contextUi.closeUi(uiSettingsPanel)
	else:
		uiSettingsPanel = load(subMenus.settings).instantiate()
		Game.contextUi.openUi(
			uiSettingsPanel
		)

func _onQuitPressed() -> void:
	$ExitConfirmationDialog.popup_centered()
	
func _onQuitConfirmed() -> void:
	Game.quit()
	
func open() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func requestClose():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_onQuitPressed()

func refreshLocalization() -> void:
	$ColorRect/VBoxContainer/NewGameButton.text = tr('outGameMainMenu.newGame')
	$ColorRect/VBoxContainer/SettingsButton.text = tr('settings')
	$ColorRect/VBoxContainer/ExitButton.text = tr('global.exitGame')
	$ExitConfirmationDialog.title = tr('global.confirmationTitle')
	$ExitConfirmationDialog.dialog_text = tr('outGameMainMenu.exitGame.confirmation')
	$ExitConfirmationDialog.ok_button_text = tr('global.ok')
	$ExitConfirmationDialog.cancel_button_text = tr('global.cancel')
	
