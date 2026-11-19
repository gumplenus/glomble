extends Node

var is_dragging = false
var max_pull_distance = 200.0
var launch_power = 3.0

var start_pos = Vector2.ZERO
@onready var ball = get_parent().get_node("Ball")

func _ready():
	start_pos = ball.global_position

func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			if mouse_pos.distance_to(ball.global_position) < 150:
				is_dragging = true
				ball.gravity_scale = 0 
		else:
			if is_dragging:
				is_dragging = false
				ball.gravity_scale = 1
				
				var pull_distance = start_pos.x - ball.global_position.x
				pull_distance = clamp(pull_distance, 0.0, max_pull_distance)
				
				var force = pull_distance * launch_power
				
				# Запускаем шар (линейная скорость)
				ball.linear_velocity = Vector2(force, 0)
				
				# ДОБАВЛЕНО: Задаем вращение пропорционально силе
				# Чем сильнее толчок, тем быстрее крутится
				ball.angular_velocity = force * 0.05 

	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			var mouse_pos = get_viewport().get_mouse_position()
			var new_x = clamp(mouse_pos.x, start_pos.x - max_pull_distance, start_pos.x)
			
			var target_velocity = (Vector2(new_x, start_pos.y) - ball.global_position) * 10.0
			ball.linear_velocity = target_velocity
			
			# Фиксируем высоту, чтобы не взлетал
			ball.global_position.y = start_pos.y
