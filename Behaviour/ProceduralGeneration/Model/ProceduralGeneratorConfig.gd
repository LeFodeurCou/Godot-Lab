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
var cellNumber: int = 100
# true : more corridor maze by counting neighbors
# false : more blob maze (no neighbors count)
var isStrictMaze: bool = true
var frontierDecay: float = 0.1
var directionMomentum: float = 0.7
var corridorCoefficient:float = 0.6
# We need to start by greater rooms first
# to avoid erasing smallest one after they was generated
# size: [coefficient, maxNumber, threshold]
# coefficient : chances rooms can appear during generation
# maxNumber : room limit in one generation
# threshold : rooms can't apear before a threshold based on the graph build progression
# -> can quickly hard limit rooms on smaller cellNumber
var roomCoefficient: Dictionary = {
	5: [
		1,
		1, 
		0.7,
	],
	3: [
		0.3, 
		4, 
		0.2,
	],
} # 0.05 of cells can become a room candidate
var roomSizes: Array = PackedInt32Array()

# Second phase variables

var loopChance: float = 0.05
var canLoopDoubleCheck: float = false # false is more optimized but lead to less loop

func _init(seedHandlerInput: SeedHandler):
	seedHandler = seedHandlerInput
	roomSizes = roomCoefficient.keys()
