extends World

var debugCanvas: CanvasLayer

var originSeed = 123
var generator: ProceduralGenerator

var config: ProceduralGeneratorConfig

# Timer
var start
var end
var elapsed

func _ready() -> void:
	Game.connectPlayerDebug(self)
	self.name = "World000004"
	
	var seedHandler = SeedHandler.new(originSeed)
	config = ProceduralGeneratorConfig.new(seedHandler)
	generator = ProceduralGenerator.new(config)
	var worldGenerator = WorldGenerator.new(generator)
	start = Time.get_ticks_usec()
	var origin = worldGenerator.generate(self)
	end = Time.get_ticks_usec()
	elapsed = (end - start) / 1000.0
	
	var lightFactory = preload("res://Environment/Component/Light.gd")
	self.add_child(
		lightFactory.create()
	)
	
	#Portal backp
	self.add_child(
		self.makePortal(
			Vector3(worldGenerator.roomWidth / 2.0 - worldGenerator.roomWidth / 4.0, 3.5, -worldGenerator.roomDepth / 2.0 + worldGenerator.roomDepth / 4.0)
		)
	)
	
	createDebugOverlay(self)
	
	super._ready()

func _onDebugToggled(value: bool) -> void:
	debugCanvas.visible = value

func createDebugOverlay(world: Node3D) -> void:
	debugCanvas = CanvasLayer.new()
	debugCanvas.visible = Game.player.isDebug
	var overlay = DebugOverlay.new()
	overlay.set_lines([
		"Cells: %d" % generator.cellCount,
		"Seed: %d" % originSeed,
		"Gen: %.2f ms" % elapsed,
		"FPS: %d" % Engine.get_frames_per_second(),
	])
	debugCanvas.add_child(overlay)
	world.add_child(debugCanvas)
