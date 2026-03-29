extends CharacterBody3D

class_name Player

signal debugToggled(value)

var contextCamera: ContextCamera

# Hard coded for now, later it can be a command based on a game configuration like "isCreativeModeAllowed"
var isCreativeMode = false

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_impulse = 20
var target_velocity = Vector3.ZERO

func _ready():
	#contextCamera = ContextCamera.new(self, "CameraHS")
	contextCamera = ContextCamera.new(self, "toto")

func _physics_process(delta):
	contextCamera.process(delta)

func _input(event):
	contextCamera.input(event)
	if Input.is_action_just_pressed("switchDebug"):
			Game.isDebug = !Game.isDebug
			emit_signal("debugToggled", Game.isDebug)

func stopMovement() -> void:
	if contextCamera:
		var camera = contextCamera.getCurrentCamera()
		if camera.has_method("clearTarget"):
			camera.clearTarget()
	target_velocity = Vector3.ZERO

func getPlayerCollisionSize() -> float:
	var shape = $CollisionShape3D.shape
	# Assuming it stays a SphereShape for now
	return shape.radius + shape.margin
