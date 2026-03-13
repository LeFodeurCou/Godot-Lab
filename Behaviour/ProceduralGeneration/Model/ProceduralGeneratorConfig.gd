extends Object

class_name ProceduralGeneratorConfig

var id = "myFirstProceduralMaze"
var seedHandler: SeedHandler
var cellNumber = 100
# true : more corridor maze by counting neighbors
# false : more blob maze (no neighbors count)
var isStrictMaze = true
var frontierDecay = 0.1
var directionMomentum = 0.7
var corridorCoefficient = 0.6
var roomCoefficient = { #size: [coefficient, maxNumber]
	3: [0.3, 6, 0.2],
	5: [0.1, 1, 0.9]
} # 0.05 of cells can become a room candidate

# Second phase variables

var loopChance = 0.05
var canLoopDoubleCheck = false # false is more optimized but lead to less loop

func _init(seedHandlerInput: SeedHandler):
	seedHandler = seedHandlerInput
