extends CharacterBody3D

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
