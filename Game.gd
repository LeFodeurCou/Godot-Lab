extends Node

# Game.gd (AutoLoad)
var player: CharacterBody3D
var currentWorld: Node

func _ready() -> void:
	spawnPlayer()
	changeWorld(
		"res://World/Static/MainWorld.tscn"
	)

func changeWorld(
	path: String,
	spawn_position: Vector3 = Vector3(0, 0, 0),
	spawn_rotation: float = 0.0,
	data: Dictionary = {}
)-> void:
	if currentWorld:
		currentWorld.queue_free()

	var resource = load(path)
	if resource is PackedScene:
		currentWorld = resource.instantiate()
	elif resource is Script:
		currentWorld = resource.new()
	else:
		push_error("Unsupported world type: " + path)
		return
	
	# ✅ Inject data BEFORE ready
	for key in data:
		currentWorld.set(key, data[key])
		
	get_tree().root.add_child.call_deferred(currentWorld)

	# ✅ Re-parent player into the world
	if player.get_parent():
		player.get_parent().remove_child(player)
	currentWorld.add_child.call_deferred(player)

	player.global_position = spawn_position
	player.rotation.y = spawn_rotation

func spawnPlayer() -> void:
	var playerScene = preload("res://Player/Player.tscn")
	player = playerScene.instantiate()
	
func connectPlayerDebug(target: Object) -> void:
	if player:
		Game.player.connect("debugToggled", Callable(target, "_onDebugToggled"))
