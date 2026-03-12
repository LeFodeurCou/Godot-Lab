extends Object

class_name SeedHandler

var terrainRng: Callable
var dungeonRng: Callable
var lootRng: Callable
var villageRng: Callable
var caveRng: Callable
# TODO add or remove some to have as many RNG as we need here
	
func _init(originSeed: Variant):
	terrainRng = func(localSeed: Variant) -> RandomGenerator:
		return RandomGenerator.new(
			hash(str(originSeed, "terrain", localSeed))
		)
	dungeonRng = func(localSeed: Variant) -> RandomGenerator:
		return RandomGenerator.new(
			hash(str(originSeed, "dungeon", localSeed))
		)
	lootRng = func(localSeed: Variant) -> RandomGenerator:
		return RandomGenerator.new(
			hash(str(originSeed, "loot", localSeed))
		)
	villageRng = func(localSeed: Variant) -> RandomGenerator:
		return RandomGenerator.new(
			hash(str(originSeed, "terrain", localSeed))
		)
	terrainRng = func(localSeed: Variant) -> RandomGenerator:
		return RandomGenerator.new(
			hash(str(originSeed, "cave", localSeed))
		)
