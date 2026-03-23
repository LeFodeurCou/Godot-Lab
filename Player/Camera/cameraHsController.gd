extends Camera3D

var target_position: Vector3 = Vector3.ZERO
var has_target := false

func _ready() -> void:
	self.position = Vector3(0, 20, 20)
	self.rotation_degrees = Vector3(-45, 0, 0)

func playerProcess(player: CharacterBody3D, playerPivot: Node3D) -> void:
	if not has_target:
		player.target_velocity.x = 0
		player.target_velocity.z = 0
		return
	var dir = target_position - player.global_position
	dir.y = 0
	# Stop condition
	if dir.length() < 0.2:
		has_target = false
		player.target_velocity = Vector3.ZERO
		return
	dir = dir.normalized()
	# Rotate player toward target (nice polish)
	var angle = atan2(-dir.x, -dir.z)
	playerPivot.rotation.y = angle
	player.target_velocity.x = dir.x * player.speed
	player.target_velocity.z = dir.z * player.speed

func playerInput(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var pos = get_click_position()
			if pos != null:
				target_position = pos
				has_target = true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			has_target = false

func get_click_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_dir = camera.project_ray_normal(mouse_pos)
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_dir * 1000
	)
	var result = space.intersect_ray(query)
	if result:
		return result.position
	return null

func onActivate(player: CharacterBody3D) -> void:
	# Reset player rotation
	player.rotation = Vector3.ZERO
	# Reset pivot rotation
	player.get_node("Pivot").rotation = Vector3.ZERO
	# Reset camera pivot if you have one
	var camPivot = get_parent()
	if camPivot:
		camPivot.rotation = Vector3.ZERO

func clearTarget():
	has_target = false
