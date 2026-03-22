extends SpawnPoint

@export var targetWorld: String
@export var exitOffset := 3.5

var rng = RandomNumberGenerator.new()

func _ready():
	$StaticBody3D/Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D and targetWorld != null:
		#if body.is_in_group("player"):
		var mesh = get_node("./StaticBody3D/MeshInstance3D")
		var material = mesh.get_active_material(0)
		material.albedo_color = Color(
			rng.randf_range(0.0, 1.0),
			rng.randf_range(0.0, 1.0),
			rng.randf_range(0.0, 1.0)
		)
			
		Game.changeWorld(
			targetWorld,
			{
				"portalBackTarget" : "res://World/Static/MainWorld.tscn",
				"spawnId" : spawnId,
				"targetSpawnId" : targetSpawnId,
				"entryDirection": Game.player.target_velocity
			}
		)

func getSpawnTransform(data := {}) -> Transform3D:
	var t = global_transform
	if data.has("entryDirection"):
		var velocity = data["entryDirection"]
		velocity.y = 0
		velocity = velocity.normalized()
		t.origin.x += $StaticBody3D/MeshInstance3D.mesh.size.x * velocity.x
		t.origin.z += $StaticBody3D/MeshInstance3D.mesh.size.z * velocity.z
		t.origin.y = 0.5
		# TODO fix two things :
		# Local portal : rotation
		# mesh size after rotation
	return t
