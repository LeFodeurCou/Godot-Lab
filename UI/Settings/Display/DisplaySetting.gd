extends VBoxContainer

signal resolutionChanged

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	updateDisplay(Game.gameState)
	$MarginContainer/HBoxContainer/OptionButton.item_selected.connect(_changeResolutionSetting)

func _changeResolutionSetting(index: int) -> void:
	resolutionChanged.emit(index)

func updateDisplay(state: GameState) -> void:
	var index = Game.gameState.ALL_RESOLUTIONS.find(state.currentResolution)
	$MarginContainer/HBoxContainer/OptionButton.select(index)
