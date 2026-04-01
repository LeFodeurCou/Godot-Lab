extends Node

class_name ContextUI

## Whether this game mode allows pausing (set false for multiplayer)
@export var pause_allowed: bool = true

var uiStack: Array[UiBase] = []
var inGameMainMenu: UiInGameMainMenu
var outGameMainMenu: UiOutGameMainMenu

enum UIType {
	OUT_GAME_MENU,
	IN_GAME_MENU
}

const UI_SCENES = {
	UIType.OUT_GAME_MENU: "res://UI/OutGameMainMenu/UiOutGameMainMenu.tscn",
	UIType.IN_GAME_MENU: "res://UI/InGameMainMenu/UiInGameMainMenu.tscn"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func loadOutGameMainMenu() -> void:
	var scene = preload(UI_SCENES[UIType.OUT_GAME_MENU])
	outGameMainMenu = scene.instantiate()
	add_child(outGameMainMenu)
	_openUi(outGameMainMenu)
	
func loadInGameMainMenu() -> void:
	var scene = preload(UI_SCENES[UIType.IN_GAME_MENU])
	inGameMainMenu = scene.instantiate()
	add_child(inGameMainMenu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		print('toto')
		get_viewport().set_input_as_handled()
		# 🔥 CLEAN DEAD REFERENCES
		while not uiStack.is_empty() and not is_instance_valid(uiStack.back()):
			uiStack.pop_back()
		if uiStack.is_empty():
			_openUi(inGameMainMenu)
			return
		uiStack.back().requestClose()

func _openUi(ui: UiBase) -> void:
	if ui.get_parent() == null:
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
	var index = uiStack.find(ui)
	if index == -1:
		return
	uiStack.remove_at(index)
	await ui.close()
	if ui.get_parent() and _canBeFree(ui):
		ui.queue_free.call_deferred()

func _canBeFree(ui: UiBase) -> bool:
	return ui != inGameMainMenu and ui != outGameMainMenu

func resetUI() -> void:
	for ui in uiStack:
		if is_instance_valid(ui):
			ui.requestClose() # close brutally breaking animations
			#await _closeUi(ui) # close smoothly, but animation can leak in another scene
			ui.queue_free.call_deferred()
	uiStack.clear()
