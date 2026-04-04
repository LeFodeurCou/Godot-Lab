extends Node

# Game.gd (AutoLoad)
# Player
var player: Player
# UI
var contextUi: ContextUI
# Effects
var screenTransition: ScreenTransition
# States
var gameState: GameState
var isDebug = false
var timer: Timer
var loadedWorlds: Dictionary = {} # Resource -> Node
var currentWorld: World

# Game rules
var maxWorldCacheTimeBeforReset: int = 8 * 60 * 1000 # (8 minutes * 60 seconds * 1000 ms)

func _ready() -> void:
	gameState = GameState.new()	
	contextUi = ContextUI.new()
	add_child(contextUi)
	contextUi.loadOutGameMainMenu()
	timer = Timer.new()
	timer.wait_time = 5.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_onCleanupTimer)
	add_child(timer)
	screenTransition = ScreenTransition.new()
	add_child(screenTransition)

func loadNewGame() -> void:
	contextUi.resetUI()
	contextUi.loadInGameMainMenu()
	gameState.apply() # TODO see why we need to reaply settings here
	spawnPlayer()
	changeWorld(
		"res://World/Static/MainWorld.tscn"
	)

func _onCleanupTimer():
	cleanupWorlds(maxWorldCacheTimeBeforReset)

func changeWorld(
	path: String,
	data: Dictionary = {}
)-> void:
	await screenTransition.fade_out()
	var newWorld = getOrLoadWorld(path)
	# 👉 If switching world
	if currentWorld != newWorld:
		if currentWorld and currentWorld.get_parent():
			currentWorld.get_parent().remove_child.call_deferred(currentWorld)
		currentWorld = newWorld
		get_tree().root.add_child.call_deferred(currentWorld)
	
	# ✅ Inject data BEFORE ready
	for key in data:
		if currentWorld.has_method("set") or key in currentWorld:
			currentWorld.set(key, data[key])

	# ✅ Re-parent player into the world
	if player.get_parent():
		player.get_parent().remove_child(player)
	currentWorld.add_child.call_deferred(player)

	# After world is added
	await get_tree().process_frame  # ensure world is ready

	var t: Transform3D = currentWorld.getSpawnPointById(data)
	player.global_transform = t
	player.stopMovement()
	
	await screenTransition.fade_in()

func getOrLoadWorld(path: String) -> World:
	if loadedWorlds.has(path):
		loadedWorlds[path].last_used = Time.get_ticks_msec()
		return loadedWorlds[path].world
	var resource = load(path)
	var world: Node = null
	if resource is PackedScene:
		world = resource.instantiate()
	elif resource is Script:
		world = resource.new()
	else:
		push_error("Unsupported world type: " + str(resource))
		return null
	loadedWorlds[path] = {
		"world": world,
		"last_used": Time.get_ticks_msec()
	}
	return world

func cleanupWorlds(max_idle_time_ms := 60000): # 1 min
	var now = Time.get_ticks_msec()
	for path in loadedWorlds.keys():
		var entry = loadedWorlds[path]
		if entry.world == currentWorld:
			loadedWorlds[path].last_used = Time.get_ticks_msec()
			continue
		if now - entry.last_used > max_idle_time_ms:
			if entry.world.get_parent():
				entry.world.get_parent().remove_child(entry.world)
			if isDebug:
				print("World " + path + " reset")
			entry.world.queue_free()
			loadedWorlds.erase(path)

func spawnPlayer() -> void:
	var playerScene = preload("res://Player/Player.tscn")
	player = playerScene.instantiate()
	
func connectPlayerDebug(target: Object) -> void:
	if player:
		Game.player.connect("debugToggled", Callable(target, "_onDebugToggled"))

func quit() -> void:
	get_tree().quit()

func quitRun() -> void:
	await screenTransition.fade_out()
	contextUi.resetUI()
	contextUi.loadOutGameMainMenu()
	gameState.apply() # TODO see why we need to reaply settings here
	remove_child(player)
	player.queue_free()
	cleanupWorlds(0)
	await screenTransition.fade_in()

func applySettings(newGameState: GameState) -> void:
	gameState = newGameState
	gameState.apply()
