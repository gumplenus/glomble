extends Node

var is_dragging = false
var max_pull_distance = 200.0
var launch_power = 3.0

var hint_time = 0.0
var hint_active = true
var hint_start_pos = Vector2.ZERO

# Флаг, запускали ли шар
var has_launched = false 
var check_timer = 0.0

var start_pos = Vector2.ZERO
@onready var ball = get_parent().get_node("Ball")

var stretch_player = AudioStreamPlayer.new()
var sound_length = 0.0
var launch_player = AudioStreamPlayer.new()

@onready var hit_player = get_parent().get_node("HitSound")
@onready var fall_player = get_parent().get_node("FallSound")

@onready var power_bar = get_parent().get_node("CanvasLayer/PowerBarUI")
@onready var power_fill = power_bar.get_node("Fill")
@onready var hand_hint = get_parent().get_node("HandHint")

# Переменные для UI результата
var result_panel: ColorRect
var result_label: Label
var result_button: Button

func _ready():
	start_pos = ball.global_position
	
	add_child(stretch_player)
	stretch_player.stream = load("res://sounds/stretch.wav")
	sound_length = stretch_player.stream.get_length()
	if stretch_player.stream is AudioStreamWAV:
		stretch_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		
	add_child(launch_player)
	launch_player.stream = load("res://sounds/launch.wav")
	
	power_bar.visible = false
	
	if hand_hint:
		hand_hint.visible = true
		hint_start_pos = hand_hint.position
		
	# Создаем UI результата
	result_panel = ColorRect.new()
	result_panel.color = Color(0, 0, 0, 0.7)
	result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_panel.visible = false
	add_child(result_panel)
	
	result_label = Label.new()
	result_label.text = "SUCCESS"
	result_label.add_theme_font_size_override("font_size", 80)
	result_label.set_anchors_preset(Control.PRESET_CENTER)
	result_label.position = Vector2(-150, -100)
	result_panel.add_child(result_label)
	
	result_button = Button.new()
	result_button.text = "OK"
	result_button.set_anchors_preset(Control.PRESET_CENTER)
	result_button.position = Vector2(-50, 50)
	result_button.custom_minimum_size = Vector2(100, 50)
	result_panel.add_child(result_button)
	
	result_button.pressed.connect(_on_result_button_pressed)

func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			if mouse_pos.distance_to(ball.global_position) < 150:
				is_dragging = true
				ball.gravity_scale = 0 
				stretch_player.play()
				stretch_player.stream_paused = true
				power_bar.visible = true
				power_fill.size.x = 0
				if hand_hint:
					hand_hint.visible = false
					hint_active = false
		else:
			if is_dragging:
				is_dragging = false
				ball.gravity_scale = 1
				stretch_player.stop()
				power_bar.visible = false
				
				var pull_distance = start_pos.x - ball.global_position.x
				pull_distance = clamp(pull_distance, 0.0, max_pull_distance)
				
				if pull_distance > 10.0:
					launch_player.play() 
					var force = pull_distance * launch_power
					ball.linear_velocity = Vector2(force, 0)
					ball.angular_velocity = force * 0.05
					
					has_launched = true 
					check_timer = 0.0

	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			var mouse_pos = get_viewport().get_mouse_position()
			var new_x = clamp(mouse_pos.x, start_pos.x - max_pull_distance, start_pos.x)
			
			var target_velocity = (Vector2(new_x, start_pos.y) - ball.global_position) * 10.0
			ball.linear_velocity = target_velocity
			ball.global_position.y = start_pos.y
			
			var pull_ratio = (start_pos.x - ball.global_position.x) / max_pull_distance
			stretch_player.seek(pull_ratio * sound_length)
			if pull_ratio > 0.0:
				stretch_player.stream_paused = false
				stretch_player.pitch_scale = 0.8 + (pull_ratio * 0.5)
			else:
				stretch_player.stream_paused = true
			
			power_fill.size.x = pull_ratio * 200.0
			power_fill.color = Color(1.0, 1.0 - pull_ratio, 0.0)

func _process(delta):
	if hint_active and hand_hint:
		hint_time += delta
		var cycle_speed = 1.0
		var cycle = fmod(hint_time, cycle_speed) / cycle_speed
		
		if cycle < 0.8:
			hand_hint.visible = true
			hand_hint.position.x = hint_start_pos.x - (120.0 * (cycle / 0.8))
		else:
			hand_hint.visible = false
			hand_hint.position.x = hint_start_pos.x

func _physics_process(delta):
	# Проверяем только если шар запущен и панель не показана
	if has_launched and not is_dragging and not result_panel.visible:
		# Если шар все еще катится - не проверяем результат
		if ball.linear_velocity.length() > 10.0:
			check_timer = 0.0
			return
			
		# Если шар остановился, начинаем отсчет (чтобы доминошки успели упасть)
		check_timer += delta
		if check_timer > 2.0: # Ждем 2 секунды после остановки шара
			check_timer = 0
			check_result()

func check_result():
	var dominoes = get_parent().get_children()
	var all_fallen = true
	var any_moving = false
	
	for child in dominoes:
		if child.name.begins_with("Domino"):
			if abs(child.rotation_degrees) < 45:
				all_fallen = false
			if child.linear_velocity.length() > 10 or abs(child.angular_velocity) > 0.5:
				any_moving = true
	
	# Если доминошки все еще падают - ждем
	if any_moving:
		return
		
	if all_fallen:
		show_result(true)
	else:
		show_result(false)

func show_result(is_success):
	result_panel.visible = true
	if is_success:
		result_label.text = "SUCCESS"
		result_label.modulate = Color.GREEN
	else:
		result_label.text = "FAIL"
		result_label.modulate = Color.RED

func _on_result_button_pressed():
	get_tree().reload_current_scene()

# --- ЗВУКИ СТОЛКНОВЕНИЙ ---
func _on_hit_area_body_entered(body):
	if body.name.begins_with("Domino"):
		if not hit_player.playing:
			hit_player.play()

func _on_hit_area_2_body_entered(body):
	if body.name.begins_with("Domino3"):
		if not hit_player.playing:
			hit_player.play()
		var area = get_parent().get_node("Domino2/HitArea2")
		area.set_deferred("monitoring", false)

func _on_hit_area_1_body_entered(body):
	if body.name.begins_with("Domino2"):
		if not hit_player.playing:
			hit_player.play()

func _on_fall_zone_body_entered(body):
	if body.name == "Domino3":
		if not fall_player.playing:
			fall_player.play()
