extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_impulse = 20
var target_velocity = Vector3.ZERO

var cameras: Array[Camera3D]
var currentCameraIdx: int = 0

var mouse_sensitivity := 0.002
var yaw := 0.0 # Player Rotation
var pitch := 0.0 # CameraPivot rotation
var pitch_limit := deg_to_rad(80)

var target_position: Vector3
var has_target := false

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cameras = [
		$CameraPivot/CameraBasic,
		$CameraPivot/CameraFP,
		$CameraPivot/CameraTP, # TODO prevent camera going through walls
		$CameraPivot/CameraTop,
		$CameraPivot/CameraTactical,
		$CameraPivot/CameraCinematic
	]
	#cameraSetup()
	set_active_camera(0)

func _physics_process(delta):
	#if target_position != Vector3.ZERO:
		#var dir = (target_position - global_position)
		#dir.y = 0
		#if dir.length() < 0.5:
			#target_position = Vector3.ZERO
		#else:
			#dir = dir.normalized()
			#velocity.x = dir.x * speed
			#velocity.z = dir.z * speed
	# We create a local variable to store the input direction.
	#var inputDir = Vector3.ZERO
#
	## We check for each move input and update the direction accordingly.
	#if Input.is_action_pressed("move_right"):
		#inputDir.x += 1
	#if Input.is_action_pressed("move_left"):
		#inputDir.x -= 1
	#if Input.is_action_pressed("move_back"):
		## Notice how we are working with the vector's x and z axes.
		## In 3D, the XZ plane is the ground plane.
		#inputDir.z += 1
	#if Input.is_action_pressed("move_forward"):
		#inputDir.z -= 1
#
	#inputDir = inputDir.normalized()
#
	#if inputDir != Vector3.ZERO:
		#var basis = $CameraPivot.global_transform.basis
		#
		#var direction = (basis.z * inputDir.z + basis.x * inputDir.x)
		#direction.y = 0
		#direction = direction.normalized()
		## Setting the basis property will affect the rotation of the node.
		#$Pivot.basis = Basis.looking_at(direction)
	#
		## Ground Velocity
		#target_velocity.x = direction.x * speed
		#target_velocity.z = direction.z * speed

	cameras[currentCameraIdx].playerProcess(self, $Pivot)

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	#if currentCameraIdx == 3 and has_target:
		#var dir = (target_position - global_position)
		#if dir.length() < 0.1:
			#has_target = false
		#else:
			#global_position += dir.normalized() * speed * delta

func _input(event):
	#if event is InputEventMouseMotion:
		#handle_mouse_look(event)
	if event.is_action_pressed("camera_switch"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		currentCameraIdx = (currentCameraIdx + 1) % cameras.size()
		set_active_camera(currentCameraIdx)
	cameras[currentCameraIdx].playerInput(event)

func cameraSetup():
	$CameraPivot/CameraTP.position = Vector3(0, 2, 10)
	#$CameraPivot/CameraTop.position = Vector3(0, 20, 20)
	#$CameraPivot/CameraTop.rotation_degrees = Vector3(-45, 0, 0)
	$CameraPivot/CameraTop.global_position = self.global_position + Vector3(0, 20, 0)
	$CameraPivot/CameraTop.look_at(self.global_position, Vector3.UP)
	$CameraPivot/CameraTactical.position = Vector3(0, 25, 0)
	$CameraPivot/CameraTactical.rotation_degrees = Vector3(-90, 0, 0)

func set_active_camera(idx:int):
	for i in range(cameras.size()):
		## TODO those two next lines can be used to make a transition between cameras
		#var tween = create_tween()
		#tween.tween_property(camera, "global_transform", target_transform, 0.5)
		cameras[i].current = (i == idx)
		if i == idx and i == cameras.size() - 1:
			cameras[i].position = cameras[0].position
			cameras[i].rotation = cameras[0].rotation
			var tween = create_tween()
			tween.tween_property($CameraPivot/CameraCinematic, "position", Vector3(10,200,200), 5)
			#tween.tween_property($CameraPivot/CameraCinematic, "position", Vector3(0,200,200), 5)
			#tween.finished.connect(func():
				#set_active_camera(0)
			#)

func handle_mouse_look(event):
	if currentCameraIdx == 3 and event is InputEventMouseButton and event.pressed:
		target_position = get_click_position()
	# Only for FP and TP
	if ![1, 2].has(currentCameraIdx):
		return
	yaw -= event.relative.x * mouse_sensitivity
	pitch -= event.relative.y * mouse_sensitivity
	pitch = clamp(pitch, -pitch_limit, pitch_limit)
	# Rotate player (Y axis)
	rotation.y = yaw
	# Rotate pivot (X axis)
	$CameraPivot.rotation.x = pitch

func get_click_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_dir * 1000
	)
	var result = space_state.intersect_ray(query)
	if result:
		return result.position
	return null
