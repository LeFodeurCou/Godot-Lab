extends Node3D

# TODO make it root global
var debug = true

var originSeed = 123
var generator: ProceduralGenerator

var config: ProceduralGeneratorConfig

# Timer
var start
var end
var elapsed

func generateWorld(portalBackTarget: String) -> Node3D:
	
	var world = Node3D.new()
	world.name = "World000004"
	
	var seedHandler = SeedHandler.new(originSeed)
	config = ProceduralGeneratorConfig.new(seedHandler)
	generator = ProceduralGenerator.new(config)
	var worldGenerator = WorldGenerator.new(generator)
	start = Time.get_ticks_usec()
	var origin = worldGenerator.generate(world)
	end = Time.get_ticks_usec()
	elapsed = (end - start) / 1000.0
	
	var lightFactory = preload("res://Environment/Component/Light.gd")
	world.add_child(
		lightFactory.create()
	)
	
	#player
	var playerScene = preload("res://Player/player.tscn")
	var player = playerScene.instantiate()
	player.position = origin
	world.add_child(player)
	
	debugOverlay(world)
	
	return world

func debugOverlay(world: Node3D) -> void:
	if (debug):
		var canvas = CanvasLayer.new()
		var overlay = DebugOverlay.new()
		overlay.set_lines([
			"Cells: %d" % generator.cellCount,
			"Seed: %d" % originSeed,
			"Gen: %.2f ms" % elapsed,
			"FPS: %d" % Engine.get_frames_per_second(),
		])
		canvas.add_child(overlay)
		world.add_child(canvas)
