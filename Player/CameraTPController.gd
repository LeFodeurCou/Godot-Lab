extends Camera3D

var mouse_sensitivity := 0.002
var yaw := 0.0
var pitch := 0.0
var pitch_limit := deg_to_rad(80)

var mouse_delta := Vector2.ZERO
var mouseNeedToBeCaptured := true

# Distance from player
var distance := 6.0
var height := 2.0

func _ready():
	position = Vector3(0, height, distance)

func playerProcess(player: CharacterBody3D, pivot: Node3D):

	# --- Rotation ---
	yaw -= mouse_delta.x * mouse_sensitivity
	pitch -= mouse_delta.y * mouse_sensitivity
	pitch = clamp(pitch, -pitch_limit, pitch_limit)
	mouse_delta = Vector2.ZERO

	# Rotate player (Y)
	player.rotation.y = yaw

	# Rotate pivot (X)
	pivot.rotation.x = pitch

	# --- Camera follow (BEHIND player) ---
	var offset = Vector3(0, height, distance)

	# Rotate offset around player
	offset = offset.rotated(Vector3.UP, yaw)

	# Final camera position # TODO see how it interact whit the next part to avoid clipping
	global_position = player.global_position + offset
	
	# Avoid seeing the void
	# TODO it's still some rare clipping to the void in some situation
	var from = player.global_position + Vector3(0, 1.5, 0)
	var to = global_position
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	var result = space.intersect_ray(query)
	if result:
		global_position = result.position + (from - result.position).normalized() * 0.2

	# Always look at player
	look_at(player.global_position + Vector3(0, 1.5, 0), Vector3.UP)

	# --- Movement (same as FP) ---
	var inputDir = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		inputDir.x += 1
	if Input.is_action_pressed("move_left"):
		inputDir.x -= 1
	if Input.is_action_pressed("move_back"):
		inputDir.z += 1
	if Input.is_action_pressed("move_forward"):
		inputDir.z -= 1

	if inputDir != Vector3.ZERO:
		inputDir = inputDir.normalized()

		var localBasis = player.global_transform.basis
		var direction = (localBasis.x * inputDir.x + localBasis.z * inputDir.z)
		direction.y = 0
		direction = direction.normalized()

		player.target_velocity.x = direction.x * player.speed
		player.target_velocity.z = direction.z * player.speed
	else:
		player.target_velocity.x = 0
		player.target_velocity.z = 0

func playerInput(event):

	if mouseNeedToBeCaptured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouseNeedToBeCaptured = false

	if event is InputEventMouseMotion:
		mouse_delta += event.relative
