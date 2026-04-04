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

enum Languages {
	EN = 0,
	FR = 1
}

const ALL_LANGUAGES = {
	Languages.EN: 'en',
	Languages.FR: 'fr'
}

var currentResolution: ResolutionType
var currentLanguage: String

func _init():
	defaultStates() # TODO : here to load player settings if they exist from files

func defaultStates() -> void:
	currentResolution = ResolutionType.DEFAULT
	currentLanguage = ALL_LANGUAGES[Languages.EN]
	TranslationServer.set_locale(currentLanguage)

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
	TranslationServer.set_locale(currentLanguage)
	Game.get_tree().call_group(Constants.GROUP_UI, "refreshLocalization")

# Dictionary for maintainance

func toDict() -> Dictionary:
	return {
		"currentResolution": currentResolution,
		"currentLanguage": currentLanguage
	}

func fromDict(data: Dictionary) -> void:
	currentResolution = data.get("currentResolution", ResolutionType.DEFAULT)
	currentLanguage = data.get("currentLanguage", ALL_LANGUAGES[Languages.EN])
