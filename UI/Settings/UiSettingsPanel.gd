extends UiBase

var localGameState: GameState

signal localStateChanged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Constants.GROUP_UI)
	refreshLocalization()
	localGameState = Game.gameState.clone()
	find_child('ExitButton').pressed.connect(requestClose)
	var applyButton = find_child('ApplyButton')
	applyButton.pressed.connect(_applySettings)
	applyButton.set_meta("baseModulate", applyButton.modulate)
	find_child('ResetButton').pressed.connect(_resetDefaultSettings)
	var cancelButton = find_child('CancelButton')
	cancelButton.pressed.connect(_cancel)
	cancelButton.set_meta("baseModulate", cancelButton.modulate)
	var displayNode = find_child('Display')
	displayNode.resolutionChanged.connect(_changeResolution)
	displayNode.languageChanged.connect(_changeLanguage)
	localStateChanged.connect(displayNode.updateDisplay)

func _applySettings() -> void:
	Game.applySettings(localGameState.clone())
	localGameState = Game.gameState.clone()
	_updateButtonsState()

func _resetDefaultSettings() -> void:
	localGameState.defaultStates()
	localStateChanged.emit(localGameState)
	_updateButtonsState()
	
func _cancel():
	localGameState = Game.gameState.clone()
	localStateChanged.emit(localGameState)
	_updateButtonsState()

func _changeResolution(index: int) -> void:
	localGameState.currentResolution = Game.gameState.ALL_RESOLUTIONS[index]
	_updateButtonsState()

func _changeLanguage(index: int) -> void:
	localGameState.currentLanguage = Game.gameState.ALL_LANGUAGES[index]
	_updateButtonsState()

func _updateButtonsState() -> void:
	var dirty = !localGameState.equals(Game.gameState)

	_setButtonActive(find_child("ApplyButton"), dirty, Color.GREEN)
	_setButtonActive(find_child("CancelButton"), dirty, Color.RED)

func _setButtonActive(button: Button, active: bool, color: Color) -> void:
	var base = button.get_meta("baseModulate")
	button.modulate = color if active else base

func refreshLocalization() -> void:
	var tabs = find_child('TabContainer')
	for i in tabs.get_tab_count():
		match tabs.get_child(i).name:
			"Display":
				tabs.set_tab_title(i, tr('settings.display'))
			#"Audio": # TODO for later
				#tabs.set_tab_title(i, tr("settings.audio"))
			#"Controls":
				#tabs.set_tab_title(i, tr("settings.controls"))
	
	find_child('PanelName').text = tr('settings')
	find_child('ApplyButton').text = tr('settings.apply')
	find_child('ResetButton').text = tr('settings.reset')
	find_child('CancelButton').text = tr('global.cancel')
