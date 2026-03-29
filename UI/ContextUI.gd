extends Node

class_name ContextUI

## Whether this game mode allows pausing (set false for multiplayer)
@export var pause_allowed: bool = true

var uiStack: Array = []
var inGameMainMenu: UiInGameMainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene = preload("res://UI/InGameMainMenu/UiInGameMainMenu.tscn")
	inGameMainMenu = scene.instantiate()
	add_child(inGameMainMenu)
	inGameMainMenu.resume_requested.connect(_onResume)
	inGameMainMenu.quit_requested.connect(_onQuit)
	inGameMainMenu.pauseAllowed = pause_allowed
	process_mode = Node.PROCESS_MODE_ALWAYS

	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_viewport().set_input_as_handled()
		if uiStack.is_empty():
			inGameMainMenu.open()
			uiStack.push_back(inGameMainMenu)
			return
		var lastUi = uiStack.pop_back()
		if lastUi.has_method("close"):
			lastUi.close()

func _onResume() -> void:
	inGameMainMenu.close()
	uiStack.clear()

func _onQuit() -> void:
	get_tree().quit()
