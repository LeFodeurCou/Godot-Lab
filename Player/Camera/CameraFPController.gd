extends Camera3D

var mouse_delta := Vector2.ZERO
var mouse_sensitivity := 0.002
var yaw := 0.0
var pitch := 0.0
var pitch_limit := deg_to_rad(80)

func _ready() -> void:
	self.position = Vector3(0, 1.6, 0)

func playerProcess(player: CharacterBody3D, playerPivot: Node3D) -> void:
	
	# --- Rotation ---
	yaw -= mouse_delta.x * mouse_sensitivity
	pitch -= mouse_delta.y * mouse_sensitivity
	pitch = clamp(pitch, -pitch_limit, pitch_limit)
	mouse_delta = Vector2.ZERO
	
	# Rotate player (Y axis)
	player.rotation.y = yaw
	# Rotate camera (X axis)
	get_parent().rotation.x = pitch
		
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
		# ✅ KEY: use player orientation (yaw)
		var localBasis = playerPivot.global_transform.basis
		var direction = (localBasis.x * inputDir.x + localBasis.z * inputDir.z)
		direction.y = 0
		direction = direction.normalized()
		player.target_velocity.x = direction.x * player.speed
		player.target_velocity.z = direction.z * player.speed
	else:
		player.target_velocity.x = 0
		player.target_velocity.z = 0
	
func playerInput(event) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func onActivate(player: CharacterBody3D) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.get_node("Pivot").rotation.y = yaw
