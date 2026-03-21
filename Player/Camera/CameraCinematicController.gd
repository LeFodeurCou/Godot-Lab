extends Camera3D

var tween: Tween
var isMovementAllowed = false

func _ready() -> void:
	self.position = Vector3(0, 20, 20)
	self.rotation_degrees = Vector3(-45, 0, 0)

func playerProcess(player: CharacterBody3D, playerPivot: Node3D) -> void:
	if !isMovementAllowed:
		player.target_velocity.x = 0
		player.target_velocity.z = 0
		return
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
	# Reset player rotation
	player.rotation = Vector3.ZERO
	# Reset pivot rotation
	player.get_node("Pivot").rotation = Vector3.ZERO
	# Reset camera pivot if you have one
	var camPivot = get_parent()
	if camPivot:
		camPivot.rotation = Vector3.ZERO
	cinematic()

func cinematic() -> void:
	# TODO see how to reset the position after changing for another camera (may be with a OnDeactivate function ?)
	#var initialPosition = self.position
	#var initialRotation = self.rotation
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	tween = create_tween()
	tween.tween_property(self, "position", Vector3(10,200,200), 5)
	# see to move the camera around a point instead of turning on itself x)
	#tween.tween_property(self, "rotation_degrees", Vector3(0,180,0), 5)
	tween.finished.connect(func():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		isMovementAllowed = true
		#self.position = initialPosition
		#self.rotation = initialRotation
	)

func onDeactivate() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	tween.kill()
	isMovementAllowed = false
	self.position = Vector3(0, 20, 20)
	self.rotation_degrees = Vector3(-45, 0, 0)

func allowGlobalMovements() -> bool:
	return isMovementAllowed
