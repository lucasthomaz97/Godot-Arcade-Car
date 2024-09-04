extends RayCast3D

@export var is_front: bool = false
@export var is_traction: bool = false

@onready var wheel_radius : float = 1
@onready var car: Car = get_parent().get_parent()
@onready var weight_factor: float = 20
@onready var starter_position: Vector3 = Vector3.ZERO

var tire_world_vel: Vector3 = Vector3.ZERO
var previous_spring_vlength: float = 0
var suspension_force:Vector3 = Vector3.ZERO
var collision_point: Vector3 = Vector3.ZERO
var distance: float = 0
var point: Vector3 = Vector3.ZERO

func calculate_suspension(delta) -> void:
	$MeshInstance3D.transform.origin = Vector3(0, $MeshInstance3D.position.y, 0)
	if is_colliding():
		var susp_dir: Vector3 = global_basis.y
		
		var raycast_origin: Vector3 = global_position
		var raycast_dist: Vector3 = collision_point
		distance = raycast_dist.distance_to(raycast_origin)
		
		var contact: Vector3 = raycast_dist - car.global_position
		var spring_length: float = clamp(distance - wheel_radius, 0, car.suspension_rest_dist)
		var spring_force: float = car.spring_strength * (car.suspension_rest_dist - spring_length)
		
		var spring_velocity: float = (previous_spring_vlength - spring_length) / delta
		var damper_force: float = car.spring_damper + spring_velocity
		suspension_force = basis.y * (spring_force * damper_force)
		
		previous_spring_vlength = spring_length

		car.apply_force(susp_dir*suspension_force * car.mass, point - car.global_position)
		$MeshInstance3D.global_position.y = lerp($MeshInstance3D.global_position.y, point.y - car.tires_pos_correcton, 0.9)
		$MeshInstance3D.global_position.y = clamp($MeshInstance3D.global_position.y, global_position.y + target_position.y, global_position.y)
	else:
		$MeshInstance3D.transform.origin.y = lerp($MeshInstance3D.transform.origin.y, position.y + target_position.y, 0.075)
	
	position = Vector3(starter_position.x, position.y, starter_position.z)

func accelerate() -> void:
	if !is_traction:
		return
	
	var accel_dir: Vector3 = -global_basis.z
	var torque: float = (car.brake_input - car.accel_input) * car.engine_power * (car.mass/(weight_factor*car.traction_wheels))

	if is_colliding():
		car.apply_force(accel_dir * torque, point - global_position)

func get_point_velocity() -> Vector3:
	return car.linear_velocity + car.angular_velocity.cross(point - car.global_position)

func apply_z_force() -> void:
	var dir: Vector3 = global_basis.z
	var z_force: float = dir.dot(tire_world_vel)* car.mass/10
	
	car.apply_force(-dir * z_force, collision_point - car.global_position)
	
func apply_x_force() -> void:
	var dir: Vector3 = global_basis.x
	tire_world_vel = get_point_velocity()
	var lateral_vel: float = dir.dot(tire_world_vel)
	var grip: float = car.front_tire_grip if is_front else car.rear_tire_grip
	
	var desired_vel_change: float = -lateral_vel * grip
	var x_force: float = desired_vel_change * car.mass/5
	
	car.apply_force(dir * x_force, collision_point - car.global_position)
	
	if car.debug:
		DebugDraw3D.draw_arrow(global_position, global_position + (dir * x_force), Color.YELLOW, 0.5, false)
	
func _ready() -> void:
	starter_position = position
	wheel_radius = $MeshInstance3D.get_aabb().size.z/2
	add_exception(car)
	
func _physics_process(delta: float) -> void:
	collision_point = get_collision_point()
	tire_world_vel = get_point_velocity()
	point = Vector3(collision_point.x, collision_point.y + wheel_radius, collision_point.z)

	accelerate()
	calculate_suspension(delta)
	apply_z_force()
	apply_x_force()
	
	if car.debug:
		DebugDraw3D.draw_arrow(global_position, to_global(position + Vector3(-position.x, suspension_force.y/2, -position.z)), Color.GREEN, 0.1, true)
		DebugDraw3D.draw_line_hit_offset(global_position, to_global(position + Vector3(-position.x, -1, -position.z)), true, distance, 0.2,Color.RED, Color.RED)
