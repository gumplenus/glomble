extends Node

var is_dragging = false
var max_pull_distance = 200.0
var launch_power = 8.0

var start_pos = Vector2.ZERO
@onready var ball = get_parent().get_node("Ball")

func _ready():
	start_pos = ball.global_position

func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			# Проверяем клик по шару
			var mouse_pos = get_viewport().get_mouse_position()
			if mouse_pos.distance_to(ball.global_position) < 150:
				is_dragging = true
				# Отключаем гравитацию, чтобы шар не падал, пока мы его тянем
				ball.gravity_scale = 0 
		else:
			if is_dragging:
				is_dragging = false
				# Включаем гравитацию обратно
				ball.gravity_scale = 1
				
				# Вычисляем натяжение по оси X
				var pull_distance = start_pos.x - ball.global_position.x
				pull_distance = clamp(pull_distance, 0.0, max_pull_distance)
				
				# Если оттянули слишком слабо, просто возвращаем на место
				if pull_distance < 10.0:
					ball.global_position = start_pos
					ball.linear_velocity = Vector2.ZERO
				else:
					# Вычисляем силу
					var force = pull_distance * launch_power
					# Запускаем шар (задаем скорость напрямую)
					ball.linear_velocity = Vector2(force, 0)

	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			var mouse_pos = get_viewport().get_mouse_position()
			# Ограничиваем движение
			var new_x = clamp(mouse_pos.x, start_pos.x - max_pull_distance, start_pos.x)
			
			# Вместо global_position задаем скорость, с которой шар должен двигаться к пальцу
			var target_velocity = (Vector2(new_x, start_pos.y) - ball.global_position) * 10.0
			ball.linear_velocity = target_velocity
