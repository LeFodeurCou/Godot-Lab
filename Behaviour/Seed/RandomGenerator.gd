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

func positionalRng(x:int, y:int, originSeed:int) -> int:
	# mix x coordinate with large prime
	var h = x * 374761393
	# mix y coordinate with another large prime
	h += y * 668265263
	# combine world seed with coordinates
	h ^= originSeed
	# spread high bits into low bits
	h = (h ^ (h >> 13)) * 1274126177
	# final avalanche mixing
	return h ^ (h >> 16)

# Usage if positional_randf(cx,cy,seed) < 0.1:
#	spawn_loot()
func positionalRandf(x:int, y:int, originSeed:int) -> float:
	var r = positionalRng(x,y,originSeed)
	return float(r & 0xffff) / 65535.0
