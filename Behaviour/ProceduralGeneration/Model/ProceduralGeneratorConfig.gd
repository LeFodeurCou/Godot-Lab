extends Object

class_name ProceduralGeneratorConfig

var id: Variant = "myFirstProceduralMaze"
var seedHandler: SeedHandler
# max cellNumber limit tested 10M
# 100 ~1-2+ ms
# 1000 ~15-20ms
# 10K ~150ms
# 100K ~1.5s
# 1M ~16s
var cellNumber: int = 150
#var cellNumber: int = 10000000 # Hardest stress test
# true : more corridor maze by counting neighbors
# false : more blob maze (no neighbors count)
var isStrictMaze: bool = true
var frontierDecay: float = 0.1
var directionMomentum: float = 0.3
# We need to start by greater rooms first
# to avoid erasing smallest one after they was generated
# size: [coefficient, maxNumber, threshold, heatMin]
# coefficient : chances rooms can appear during generation
# maxNumber : room limit in one generation
# threshold : rooms can't appear before a threshold based on the graph build progression
# -> can quickly hard limit rooms on smaller cellNumber
# heatMin : a heat ration when rooms can start to appear
var roomCoefficient: Dictionary = {
	5: [
		1,
		1, 
		0.79,
		0.8,
	],
	3: [
		0.3, 
		4, 
		0.05,
		0.1,
	],
} # 0.05 of cells can become a room candidate
var roomSizes: Array = PackedInt32Array()
# Direction bias
# globalDirectionBias[0] is the x axe with West(-1) and East(1)
# globalDirectionBias[1] is the y axe with North(-1) and Sound(1)
var globalDirectionBias := PackedFloat32Array([0.4,-0.5])
# the coefficient of the direction bias
var globalBiasStrength := 0.8
# the coefficient of the nois bias
var noiseBiasStrength := 0.5

# Second phase variables

var loopChance: float = 0.05
var canLoopDoubleCheck: float = false # false is more optimized but lead to less loop

func _init(seedHandlerInput: SeedHandler):
	seedHandler = seedHandlerInput
	roomSizes = roomCoefficient.keys()
