extends UiBase

class_name UiInGameMainMenu

var originalPosY: float

var subMenus = {
	settings = "res://UI/Settings/UiSettingsPanel.tscn"
}

var uiSettingsPanel: UiBase

func _ready() -> void:
	add_to_group("UI")
	refreshLocalization()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBoxContainer/ResumeButton.pressed.connect(_onResumePressed)
	$VBoxContainer/SettingsButton.pressed.connect(_onSettingsPressed)
	$VBoxContainer/ExitToOutGameMainMenu.pressed.connect(_onQuitRunPressed)
	$ExitRunConfirmationDialog.confirmed.connect(_onQuitRunConfirmed)
	$VBoxContainer/ExitButton.pressed.connect(_onQuitPressed)
	$ExitGameConfirmationDialog.confirmed.connect(_onQuitConfirmed)
	originalPosY = $VBoxContainer.position.y

func _onResumePressed() -> void:
	requestClose()

func _onSettingsPressed() -> void:
	if uiSettingsPanel:
		Game.contextUi.closeUi(uiSettingsPanel)
	else:
		uiSettingsPanel = load(subMenus.settings).instantiate()
		Game.contextUi.openUi(
			uiSettingsPanel
		)

func _onQuitRunPressed() -> void:
	$ExitRunConfirmationDialog.popup_centered()

func _onQuitRunConfirmed() -> void:
	Game.quitRun()

func _onQuitPressed() -> void:
	$ExitGameConfirmationDialog.popup_centered()

func _onQuitConfirmed() -> void:
	Game.quit()

func open() -> void:
	self.visible = true
	if pauseAllowed:
		get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	await enterAnimation()

	
func close() -> Signal:
	if uiSettingsPanel:
		Game.contextUi.closeUi(uiSettingsPanel)
	if pauseAllowed:
		get_tree().paused = false
	Input.set_mouse_mode(previousMouseMode)
	var sig = outAnimation()
	await sig
	$VBoxContainer.position.y = originalPosY
	self.visible = false
	return sig
	
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

func refreshLocalization() -> void:
	$VBoxContainer/ResumeButton.text = tr('inGameMainMenu.resume')
	$VBoxContainer/SettingsButton.text = tr('settings')
	$VBoxContainer/ExitToOutGameMainMenu.text = tr('inGameMainMenu.exitToOutGameMainMenu')
	$ExitRunConfirmationDialog.title = tr('global.confirmationTitle')
	$ExitRunConfirmationDialog.dialog_text = tr('inGameMainMenu.exitToOutGameMainMenu.confirmation')
	$ExitRunConfirmationDialog.ok_button_text = tr('global.ok')
	$ExitRunConfirmationDialog.cancel_button_text = tr('global.cancel')
	$VBoxContainer/ExitButton.text = tr('global.exitGame')
	$ExitGameConfirmationDialog.title = tr('global.confirmationTitle')
	$ExitGameConfirmationDialog.dialog_text = tr('inGameMainMenu.exitGame.confirmation')
	$ExitGameConfirmationDialog.ok_button_text = tr('global.ok')
	$ExitGameConfirmationDialog.cancel_button_text = tr('global.cancel')
