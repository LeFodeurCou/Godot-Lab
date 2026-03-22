extends Node3D
class_name SpawnPoint

@export var spawnId: String
@export var targetSpawnId: String

func getSpawnTransform(data := {}) -> Transform3D:
	return global_transform
