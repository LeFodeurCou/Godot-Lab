extends Camera3D

var mouse_sensitivity := 0.002
var speed := 20.0

var yaw := 0.0
var pitch := 0.0
var pitch_limit := deg_to_rad(89)

var mouse_delta := Vector2.ZERO
var mouseNeedToBeCaptured := true

func playerProcess(player: CharacterBody3D, pivot: Node3D):

	# --- Rotation ---
	yaw -= mouse_delta.x * mouse_sensitivity
	pitch -= mouse_delta.y * mouse_sensitivity
	pitch = clamp(pitch, -pitch_limit, pitch_limit)
	mouse_delta = Vector2.ZERO

	rotation.y = yaw
	rotation.x = pitch

	# --- Movement ---
	var input_dir = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1
	if Input.is_action_pressed("move_back"):
		input_dir.z += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1

	# vertical movement
	if Input.is_action_pressed("jump"):
		input_dir.y += 1
	if Input.is_action_pressed("shift"): # or another key for down
		input_dir.y -= 1

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

		# Move relative to camera orientation
		var localBasis = global_transform.basis
		var direction = localBasis * input_dir

		global_position += direction * speed * get_process_delta_time()


func playerInput(event):
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

func onActivate(player: CharacterBody3D) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func onDeactivate() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func allowGlobalMovements() -> bool:
	return false
