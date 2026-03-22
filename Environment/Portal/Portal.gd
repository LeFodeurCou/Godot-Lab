extends Node3D

@export var generateWorld: bool = false
@export var targetWorld: String

var rng = RandomNumberGenerator.new()

func _ready():
	print("Area ready")
	$StaticBody3D/Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body is CharacterBody3D and targetWorld != "":
		print(body, " entered")
		#if body.is_in_group("player"):
		var mesh = get_node("./StaticBody3D/MeshInstance3D")
		var material = mesh.get_active_material(0)
		material.albedo_color = Color(
			rng.randf_range(0.0, 1.0),
			rng.randf_range(0.0, 1.0),
			rng.randf_range(0.0, 1.0)
		)
		if generateWorld:
			Game.changeWorld(
				str("res://World/Dynamic/", targetWorld, ".gd"),
				Vector3(0, 0, 0),
				Game.player.rotation.y,
				{
					"portalBackTarget": "MainWorld"
				}
			)
		else:
			Game.changeWorld(
				str("res://World/Static/", targetWorld, ".tscn")
			)
