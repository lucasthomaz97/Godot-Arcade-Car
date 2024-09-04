extends Node3D

@export var car: Car
@export_group('Camera Options')
@export var max_camera_rotation: float = 0.4
@export var camera_move_delta_multiplier: float = 20
@export var camera_rotation_delta_multiplier: float = 5
	
func read_input() -> void:
	car.accel_input = Input.get_action_strength("Accel")
	car.brake_input = Input.get_action_strength("Brake")
	car.steer_input = -Input.get_axis("Left","Right")
	car.boost_input = Input.get_action_strength("Boost")

func _process(delta: float) -> void:
	read_input()

func _physics_process(delta: float) -> void:
	global_position = global_position.lerp(car.global_position, delta* camera_move_delta_multiplier)
	transform = transform.interpolate_with(car.transform, delta * camera_rotation_delta_multiplier)
	rotation.x = clamp(rotation.x, -max_camera_rotation, max_camera_rotation)
	rotation.z = clamp(rotation.z, -max_camera_rotation, max_camera_rotation)
