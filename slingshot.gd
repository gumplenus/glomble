extends Node

var is_dragging = false
var is_dragging_domino = false
var max_pull_distance = 200.0
var launch_power = 3.0
var hint_time = 0.0
var hint_active = true
var hint_start_pos = Vector2.ZERO
var is_level_2 = false
var has_launched = false 
var check_timer = 0.0
var launch_elapsed = 0.0
var start_pos = Vector2.ZERO
var last_result_success = false

@onready var ball = get_parent().get_node("Ball")
@onready var domino3 = get_parent().get_node_or_null("Domino3")

var stretch_player = AudioStreamPlayer.new()
var sound_length = 0.0
var launch_player = AudioStreamPlayer.new()
var ambient_player = AudioStreamPlayer.new()
var result_player = AudioStreamPlayer.new()

@onready var hit_player = get_parent().get_node("HitSound")
@onready var fall_player = get_parent().get_node("FallSound")
@onready var power_bar = get_parent().get_node("CanvasLayer/PowerBarUI")
@onready var power_fill = power_bar.get_node("Fill")
@onready var hand_hint = get_parent().get_node("HandHint")

var result_screen_scene = preload("res://result_screen.tscn")
var result_screen_instance = null

func _ready():
	start_pos = ball.global_position
	
	if get_parent().name == "Level2":
		is_level_2 = true
	
	add_child(stretch_player)
	stretch_player.stream = load("res://sounds/stretch.wav")
	sound_length = stretch_player.stream.get_length()
	if stretch_player.stream is AudioStreamWAV:
		stretch_player.stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		
	add_child(launch_player)
	launch_player.stream = load("res://sounds/launch.wav")
	
	# Фоновый шум ветра, травы и птиц (тихий, -16 dB, только в уровне)
	add_child(ambient_player)
	var amb_stream = load("res://sounds/ambient_nature.wav")
	if amb_stream:
		if amb_stream is AudioStreamWAV:
			amb_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			amb_stream.loop_begin = 0
			amb_stream.loop_end = int(amb_stream.get_length() * amb_stream.mix_rate)
		ambient_player.stream = amb_stream
		ambient_player.volume_db = -6.0
		ambient_player.play()
		
	add_child(result_player)
	result_player.volume_db = -2.0
	
	power_bar.visible = false
	
	if hand_hint:
		hint_start_pos = hand_hint.position
		if is_level_2:
			if Engine.has_meta("level_2_failed") and Engine.get_meta("level_2_failed") == true:
				hand_hint.visible = true
				hint_active = true
			else:
				hand_hint.visible = false
				hint_active = false
		else:
			hand_hint.visible = true
			hint_active = true


func _input(event):
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			var mouse_pos = ball.get_global_mouse_position()
			
			# 1. ПРОВЕРКА ПЕРЕТАСКИВАНИЯ DOMINO3
			if is_level_2 and domino3 and not has_launched:
				if abs(mouse_pos.x - domino3.global_position.x) < 70 and abs(mouse_pos.y - domino3.global_position.y) < 130:
					is_dragging_domino = true
					domino3.freeze = true
					if hand_hint:
						hand_hint.visible = false
						hint_active = false
					return
			
			# 2. ПРОВЕРКА НАЖАТИЯ НА ШАР
			if mouse_pos.distance_to(ball.global_position) < 160 and not has_launched:
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
			if is_dragging_domino:
				is_dragging_domino = false
				if domino3:
					domino3.freeze = false
					
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
					launch_elapsed = 0.0

	if event is InputEventScreenDrag or event is InputEventMouseMotion:
		if is_dragging:
			var mouse_pos = ball.get_global_mouse_position()
			var new_x = clamp(mouse_pos.x, start_pos.x - max_pull_distance, start_pos.x)
			
			var pull_ratio = (start_pos.x - new_x) / max_pull_distance
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
		var cycle_speed = 1.2 if is_level_2 else 1.0
		var cycle = fmod(hint_time, cycle_speed) / cycle_speed
		
		if cycle < 0.8:
			var progress = cycle / 0.8
			hand_hint.visible = true
			if is_level_2:
				hand_hint.position.x = hint_start_pos.x - (200.0 * progress)
				hand_hint.position.y = hint_start_pos.y
			else:
				hand_hint.position.x = hint_start_pos.x - (120.0 * progress)
		else:
			hand_hint.visible = false
			hand_hint.position = hint_start_pos

	if is_dragging_domino and domino3:
		var mouse_pos = ball.get_global_mouse_position()
		domino3.global_position.x = mouse_pos.x

	if is_dragging:
		var mouse_pos = ball.get_global_mouse_position()
		var new_x = clamp(mouse_pos.x, start_pos.x - max_pull_distance, start_pos.x)
		
		var current_x = ball.global_position.x
		var smoothed_x = lerp(current_x, new_x, 20.0 * delta)
		ball.global_position = Vector2(smoothed_x, start_pos.y)
		
		ball.linear_velocity = Vector2.ZERO
		ball.angular_velocity = 0

func _physics_process(delta):
	if has_launched and not is_dragging and result_screen_instance == null:
		launch_elapsed += delta
		if launch_elapsed < 0.8:
			return
			
		var all_fallen = true
		var dominoes_moving = false
		for child in get_parent().get_children():
			if child.name.begins_with("Domino"):
				if abs(child.rotation_degrees) < 45:
					all_fallen = false
				if child.linear_velocity.length() > 15 or abs(child.angular_velocity) > 0.6:
					dominoes_moving = true
		
		if not dominoes_moving:
			if not all_fallen and ball.linear_velocity.length() > 120.0:
				check_timer = 0.0
				return
				
			check_timer += delta
			if check_timer > 0.45:
				check_timer = 0.0
				show_result(all_fallen)
		else:
			check_timer = 0.0

func show_result(is_success):
	if result_screen_instance != null:
		return
		
	last_result_success = is_success
	
	# Проигрываем звук победы или поражения
	var res_stream = load("res://sounds/win.wav") if is_success else load("res://sounds/lose.wav")
	if res_stream:
		result_player.stream = res_stream
		result_player.play()
		
	if is_level_2:
		Engine.set_meta("level_2_failed", not is_success)
		
	result_screen_instance = result_screen_scene.instantiate()
	get_parent().add_child(result_screen_instance)
	
	result_screen_instance.setup(is_success)
	result_screen_instance.ok_pressed.connect(_on_result_ok_pressed)

func _on_result_ok_pressed():
	if last_result_success:
		if not is_level_2:
			get_tree().call_deferred("change_scene_to_file", "res://level_2.tscn")
		else:
			get_tree().call_deferred("change_scene_to_file", "res://main.tscn")
	else:
		get_tree().call_deferred("reload_current_scene")

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
