extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_impulse = 20
var target_velocity = Vector3.ZERO

var cameras: Array[Camera3D]
var currentCameraIdx: int = 0

func _ready():
	cameras = [
		$CameraPivot/CameraBasic,
		$CameraPivot/CameraFP,
		$CameraPivot/CameraTP, # TODO prevent camera going through walls
		$CameraPivot/CameraTop,
		$CameraPivot/CameraTactical,
		$CameraPivot/CameraCinematic
	]
	set_active_camera(0)

func _physics_process(delta):
	# We create a local variable to store the input direction.
	var direction = Vector3.ZERO

	# We check for each move input and update the direction accordingly.
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		# Notice how we are working with the vector's x and z axes.
		# In 3D, the XZ plane is the ground plane.
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Setting the basis property will affect the rotation of the node.
		$Pivot.basis = Basis.looking_at(direction)
		
			# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Jumping.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# Moving the Character
	velocity = target_velocity
	move_and_slide()

func _input(event):
	if event.is_action_pressed("camera_switch"):
		currentCameraIdx = (currentCameraIdx + 1) % cameras.size()
		set_active_camera(currentCameraIdx)
		
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
