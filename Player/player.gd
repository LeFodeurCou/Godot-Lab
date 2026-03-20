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
	cameras = [
		$CameraPivot/CameraBasic,
		$CameraPivot/CameraFP,
		$CameraPivot/CameraTP,
		$CameraPivot/CameraHS,
		$CameraPivot/CameraTactical,
		$CameraPivot/CameraCinematic
	]
	cameras[0].current = true

func _physics_process(delta):
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

func _input(event):
	if event.is_action_pressed("camera_switch"):
		## TODO those two next lines can be used to make a transition between cameras
		#var tween = create_tween()
		#tween.tween_property(camera, "global_transform", target_transform, 0.5)
		if cameras[currentCameraIdx].has_method("onDeactivate"):
			cameras[currentCameraIdx].onDeactivate()
		currentCameraIdx = (currentCameraIdx + 1) % cameras.size()
		cameras[currentCameraIdx].current = true
		if cameras[currentCameraIdx].has_method("onActivate"):
			cameras[currentCameraIdx].onActivate(self)
	if cameras[currentCameraIdx].has_method("playerInput"):
		cameras[currentCameraIdx].playerInput(event)
