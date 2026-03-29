extends Node

class_name ContextUI

## Whether this game mode allows pausing (set false for multiplayer)
@export var pause_allowed: bool = true

var uiStack: Array[UiBase] = []
var previousMouseMode
var inGameMainMenu: UiInGameMainMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var scene = preload("res://UI/InGameMainMenu/UiInGameMainMenu.tscn")
	inGameMainMenu = scene.instantiate()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		get_viewport().set_input_as_handled()
		if uiStack.is_empty():
			_openUi(inGameMainMenu)
			return
		var lastUi = uiStack.pop_back()
		if lastUi.has_method("close"):
			lastUi.close()

func _openUi(ui: UiBase) -> void:
	add_child(ui)
	uiStack.push_back(ui)
	ui.previousMouseMode = Input.get_mouse_mode()
	ui.pauseAllowed = pause_allowed
	if ui.has_signal("closeRequest"):
		ui.closeRequest.connect(_closeUi.bind(ui))
	ui.open()


func _closeUi(ui: UiBase) -> void:
	if uiStack.is_empty():
		return
	uiStack.pop_at(
		uiStack.find(ui)
	)
	if ui.has_method("close"):
		ui.close.call_deferred()
