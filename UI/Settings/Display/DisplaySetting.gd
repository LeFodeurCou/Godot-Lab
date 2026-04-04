extends VBoxContainer

signal resolutionChanged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	refreshLocalization()
	updateDisplay(Game.gameState)
	$MarginContainer/HBoxContainer/OptionButton.item_selected.connect(_changeResolutionSetting)

func _changeResolutionSetting(index: int) -> void:
	resolutionChanged.emit(index)

func updateDisplay(state: GameState) -> void:
	var index = Game.gameState.ALL_RESOLUTIONS.find(state.currentResolution)
	$MarginContainer/HBoxContainer/OptionButton.select(index)

func refreshLocalization() -> void:
	var optionButton = $MarginContainer/HBoxContainer/OptionButton
	$MarginContainer/HBoxContainer/Label.text = tr('settings.display.resolution')
	optionButton.clear()
	optionButton.add_item(tr('settings.display.resolution.default'), 0)
	optionButton.add_item(tr('settings.display.resolution.fullScreen'), 1)
