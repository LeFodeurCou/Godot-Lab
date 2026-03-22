extends Node3D

class_name World

var spawnPoints := {}
var portalBackTarget: String
var targetSpawnId: String
var spawnId: String

func _ready():
	for child in get_children():
		if child is SpawnPoint:
			spawnPoints[child.spawnId] = child
			print("Current world spawn id : " + child.spawnId)

func getSpawnPointById(data: Dictionary) -> Transform3D:
	if data.has("targetSpawnId"):
		print(data["targetSpawnId"])
	if data.has("targetSpawnId") and spawnPoints.has(data["targetSpawnId"]):
		return spawnPoints[data["targetSpawnId"]].getSpawnTransform(data)

	#push_warning("Spawn point not found: " + data["targetSpawnId"])
	return Transform3D(Basis(), Vector3(0, 0.5, 0))

func makePortal(pos: Vector3) -> SpawnPoint:
	var portalScene = preload("res://Environment/Component/Portal/portal.tscn")
	var portal = portalScene.instantiate()
	portal.targetWorld = portalBackTarget
	portal.spawnId = targetSpawnId
	portal.targetSpawnId = spawnId
	portal.position = pos
	return portal
