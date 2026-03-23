extends SpawnPoint

@export var targetWorld: String

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
		
		var portal_forward = -global_transform.basis.z
		var portal_right = global_transform.basis.x

		var collisionSize = $StaticBody3D/Area3D/CollisionShape3D.shape.size

		# Move in local space
		var offset = \
			portal_forward * (collisionSize.z + Game.player.getPlayerCollisionSize()) * sign(velocity.dot(portal_forward)) + \
			portal_right * collisionSize.x * velocity.dot(portal_right)
		
		t.basis = Game.player.basis
		
		#t.origin += offset
		t.origin = find_safe_position(t.origin + offset)
		#t.origin.y = 0.5
	return t

func find_safe_position(origin: Vector3) -> Vector3:
	var space = get_world_3d().direct_space_state
	var player = Game.player

	# --- Use REAL player collider
	var shape = player.get_node("CollisionShape3D").shape

	# --- Directions relative to portal (not world axis!)
	var directions = [
		Vector3.ZERO,
		-global_transform.basis.z,
		global_transform.basis.z,
		global_transform.basis.x,
		-global_transform.basis.x
	]

	var best_pos = origin
	var best_score = -INF

	for dir in directions:
		var pos = origin + dir * (player.getPlayerCollisionSize() * 2.0)

		# --- Collision check
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis(), pos)

		if not space.intersect_shape(query).is_empty():
			continue

		# --- Ground check (long enough!)
		var ray = PhysicsRayQueryParameters3D.create(
			pos,
			pos + Vector3.DOWN * 20.0
		)

		var ground = space.intersect_ray(ray)
		if not ground:
			continue

		# --- Score = prefer stable / flat placement
		var height_diff = abs(pos.y - ground.position.y)
		var score = -height_diff

		if score > best_score:
			best_score = score
			best_pos = ground.position + Vector3.UP * player.getPlayerCollisionSize()

	return best_pos
