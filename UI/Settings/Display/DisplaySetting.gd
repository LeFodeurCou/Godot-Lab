extends VBoxContainer

signal resolutionChanged
signal languageChanged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(Constants.GROUP_UI)
	refreshLocalization()
	updateDisplay(Game.gameState)
	$MarginContainer/VBoxContainer/Resolution/OptionButton.item_selected.connect(_changeResolutionSetting)
	$MarginContainer/VBoxContainer/Language/OptionButton.item_selected.connect(_changeLanguageSetting)

func _changeResolutionSetting(index: int) -> void:
	resolutionChanged.emit(index)

func _changeLanguageSetting(index: int) -> void:
	languageChanged.emit(index)

func updateDisplay(state: GameState) -> void:
	var index = Game.gameState.ALL_RESOLUTIONS.find(state.currentResolution)
	$MarginContainer/VBoxContainer/Resolution/OptionButton.select(index)
	index = Game.gameState.ALL_LANGUAGES.find_key(state.currentLanguage)
	$MarginContainer/VBoxContainer/Language/OptionButton.select(index)
	
func refreshLocalization() -> void:
	var optionButton = $MarginContainer/VBoxContainer/Resolution/OptionButton
	$MarginContainer/VBoxContainer/Resolution/Label.text = tr('settings.display.resolution')
	optionButton.clear()
	optionButton.add_item(tr('settings.display.resolution.default'), 0)
	optionButton.add_item(tr('settings.display.resolution.fullScreen'), 1)
	# keep selection
	var index = Game.gameState.ALL_RESOLUTIONS.find(Game.gameState.currentResolution)
	optionButton.select(index)
	$MarginContainer/VBoxContainer/Language/Label.text = tr('settings.display.language')
