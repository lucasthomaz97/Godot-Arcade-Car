extends RigidBody3D

class_name Car

@export var debug: bool = false

@export_group('Engine')
@export var engine_power: float = 300

@export_group('Steering')
@export var steer_angle: float = 45
@export var front_tire_grip: float = 1
@export var rear_tire_grip: float = 1
@export var steer_speed: float = 0.7

@export_group('Suspension')
@export var suspension_rest_dist: float = 0.5
@export var spring_strength : float = 10
@export var spring_damper: float = 3
@export var tires_pos_correcton: float = 0

@onready var accel_input: float = 0
@onready var brake_input: float = 0
@onready var steer_input: float = 0
@onready var boost_input: float = 0
@onready var traction_wheels: int = 0
@onready var fl = $Wheels/FL
@onready var fr = $Wheels/FR

func steer(delta) -> void:
	var steering_rotation = steer_input * steer_angle
	var fl_angle: float = clamp(fl.rotation.y +steering_rotation, -steer_angle, steer_angle)
	var fr_angle: float = clamp(fr.rotation.y +steering_rotation, -steer_angle, steer_angle)
	var fl_new_rotation: float = fl_angle * delta
	var fr_new_rotation: float = fr_angle * delta
	fl.rotation.y = lerp(fl.rotation.y, fl_new_rotation, steer_speed)
	fr.rotation.y = lerp(fr.rotation.y, fr_new_rotation, steer_speed)

func _ready() -> void:
	center_of_mass = Vector3(0, -1, 0.75)
	for wheel in $Wheels.get_children():
		traction_wheels += int(wheel.is_traction)

func _process(delta: float) -> void:
	if steer_input != 0:
		steer(delta)
	else:
		fl.rotation.y = lerp(fl.rotation.y, 0.0, steer_speed)
		fr.rotation.y = lerp(fr.rotation.y, 0.0, steer_speed)
