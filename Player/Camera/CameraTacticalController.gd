extends Camera3D

func _ready() -> void:
	self.position = Vector3(0, 25, 00)
	self.rotation_degrees = Vector3(-90, 0, 0)

func playerProcess(player: CharacterBody3D, playerPivot: Node3D) -> void:
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
		var angle = atan2(-inputDir.x, -inputDir.z)
		playerPivot.rotation.y = angle
	player.target_velocity.x = inputDir.x * player.speed
	player.target_velocity.z = inputDir.z * player.speed

func onActivate(player: CharacterBody3D) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Reset player rotation
	player.rotation = Vector3.ZERO
	# Reset pivot rotation
	player.get_node("Pivot").rotation = Vector3.ZERO
	# Reset camera pivot if you have one
	var camPivot = get_parent()
	if camPivot:
		camPivot.rotation = Vector3.ZERO
