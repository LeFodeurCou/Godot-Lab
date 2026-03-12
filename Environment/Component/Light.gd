extends Object

static func create(
	position: Vector3 = Vector3(0, 1, 0),
	rotation: Vector3 = Vector3(-150, 0, 0),
	color: Color = Color(1, 1, 1, 1)
) -> DirectionalLight3D:

	var light = DirectionalLight3D.new()
	light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	light.light_color = color
	light.position = position
	light.rotation_degrees = rotation

	return light
