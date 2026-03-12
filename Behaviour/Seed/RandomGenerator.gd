extends Object

class_name RandomGenerator

var generator: RandomNumberGenerator

func _init(localSeed: int):
	generator = RandomNumberGenerator.new()
	generator.seed = localSeed
	
func randf() -> float:
	return generator.randf()

func randi(min_val: int, max_val: int) -> int:
	return generator.randi_range(min_val, max_val)
	
func pickRandom(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[generator.randi_range(0, array.size() - 1)]

func shuffle(array: Array) -> Array:
	var result = array.duplicate()

	for i in range(result.size() - 1, 0, -1):
		var j = generator.randi_range(0, i)

		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp

	return result
