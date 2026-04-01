extends Object

class_name ContextCamera

var player

var cameras: Array[Camera3D]
var currentCameraIdx: int = 0
var isCameraForced = false

func _init(basePlayer: CharacterBody3D, forcedCamera: Variant = null):
	player = basePlayer
	var cameraPivot = player.get_node("CameraPivot")
	if null != forcedCamera and cameraPivot.has_node(forcedCamera):
		isCameraForced = true
		cameras = [
			cameraPivot.get_node(forcedCamera)
		]
	else:
		cameras = [
			cameraPivot.get_node("CameraBasic"),
			cameraPivot.get_node("CameraFP"),
			cameraPivot.get_node("CameraTP"),
			cameraPivot.get_node("CameraHS"),
			cameraPivot.get_node("CameraTactical"),
			cameraPivot.get_node("CameraCinematic"),
			cameraPivot.get_node("CameraDebug"),
		]
		cameras[0].current = true
		if cameras[0].has_method("onActivate"):
			cameras[0].onActivate(basePlayer)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func process(delta: float) -> void:
	cameras[currentCameraIdx].playerProcess(player, player.get_node("Pivot"))
	if !cameras[currentCameraIdx].has_method("allowGlobalMovements") || cameras[currentCameraIdx].allowGlobalMovements():
			globalMovements(delta)

func input(event):
	if !isCameraForced and event.is_action_pressed("camera_switch"):
		if cameras[currentCameraIdx].has_method("onDeactivate"):
			cameras[currentCameraIdx].onDeactivate()
		cameras[currentCameraIdx].current = false
		currentCameraIdx = (currentCameraIdx + 1) % cameras.size()
		cameras[currentCameraIdx].current = true
		if cameras[currentCameraIdx].has_method("onActivate"):
			cameras[currentCameraIdx].onActivate(player)
	if cameras[currentCameraIdx].has_method("playerInput"):
		cameras[currentCameraIdx].playerInput(event)

func globalMovements(delta: float) -> void:
	if player.isCreativeMode:
		var input_dir = Vector3.ZERO
		# vertical movement
		if Input.is_action_pressed("jump"):
			input_dir.y += 1
		# TODO add a way to double clic on shift to fall instead
		if Input.is_action_pressed("shift"): # or another key for down
			input_dir.y -= 1
			
		if input_dir != Vector3.ZERO:
			input_dir = input_dir.normalized()

			# Move relative to camera orientation
			var localBasis = player.global_transform.basis
			var direction = localBasis * input_dir

			player.global_position += direction * player.speed * player.get_process_delta_time()
	else:
		# Vertical Velocity
		if not player.is_on_floor(): # If in the air, fall towards the floor. Literally gravity
			player.target_velocity.y = player.target_velocity.y - (player.fall_acceleration * delta)

		# Jumping.
		if player.is_on_floor() and Input.is_action_just_pressed("jump"):
			player.target_velocity.y = player.jump_impulse

	# Moving the Character
	player.velocity = player.target_velocity
	player.move_and_slide()
	
func getCurrentCamera() -> Camera3D:
	return cameras[currentCameraIdx]
