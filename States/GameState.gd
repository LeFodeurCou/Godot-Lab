extends Object

class_name GameState

enum ResolutionType {
	DEFAULT,
	FULL_SCREEN
}

const ALL_RESOLUTIONS = [
	ResolutionType.DEFAULT,
	ResolutionType.FULL_SCREEN
]

var currentResolution: ResolutionType

func _ready():
	defaultStates() # TODO : here to load player settings if they exist from files

func defaultStates() -> void:
	currentResolution = ResolutionType.DEFAULT

func clone() -> GameState:
	var c = GameState.new()
	c.fromDict(toDict())
	return c

func equals(other: GameState) -> bool:
	return toDict() == other.toDict()

func apply() -> void:
	match currentResolution:
		ResolutionType.DEFAULT:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		ResolutionType.FULL_SCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# Dictionary for maintainance

func toDict() -> Dictionary:
	return {
		"currentResolution": currentResolution
	}

func fromDict(data: Dictionary) -> void:
	currentResolution = data.get("currentResolution", ResolutionType.DEFAULT)
