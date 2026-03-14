extends Object

class_name ProceduralGeneratorConfig

var id = "myFirstProceduralMaze"
var seedHandler: SeedHandler
# max cellNumber limit for now : ~250K
var cellNumber = 100
# true : more corridor maze by counting neighbors
# false : more blob maze (no neighbors count)
var isStrictMaze = true
var frontierDecay = 0.1
var directionMomentum = 0.7
var corridorCoefficient = 0.6
# Below we need to start by greater rooms first, to avoid erasing smallest one near the start
var roomCoefficient = { #size: [coefficient, maxNumber, completionRatio]
	5: [1, 1, 0.9],
	3: [0.3, 4, 0.2],
} # 0.05 of cells can become a room candidate
var roomSizes

# Second phase variables

var loopChance = 0.05
var canLoopDoubleCheck = false # false is more optimized but lead to less loop

func _init(seedHandlerInput: SeedHandler):
	seedHandler = seedHandlerInput
	roomSizes = roomCoefficient.keys()
