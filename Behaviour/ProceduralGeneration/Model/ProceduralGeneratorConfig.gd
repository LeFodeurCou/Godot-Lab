extends Object

class_name ProceduralGeneratorConfig

var id = "myFirstProceduralMaze"
var seedHandler: SeedHandler
var cellNumber = 150
# true : more corridor maze by counting neighbors
# false : more blob maze (no neighbors count)
var isStrictMaze = true
var frontierDecay = 0.1
var directionMomentum = 0.7

# Second phase variables

var loopChance = 0.05
var canLoopDoubleCheck = false # false is more optimized but lead to less loop
var roomCoefficient = { #size: [coefficient, maxNumber]
	3: [1, 4],
	5: [0.1, 1]
} # 0.05 of cells can become a room candidate TODO Need to be used in a roomExpansion
var deadEndPruneCoefficient = 0.05 # TODO Need to make a pruneDeadEnd engine if a cell neighbors = 1

func _init(seedHandlerInput: SeedHandler):
	seedHandler = seedHandlerInput
