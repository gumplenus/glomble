extends Control

@onready var play_btn = $PlayButton
@onready var settings_btn = $SettingsButton

func _ready():
	# Устанавливаем центр масштабирования кнопок для красивой анимации нажатия
	play_btn.pivot_offset = play_btn.size / 2.0
	settings_btn.pivot_offset = settings_btn.size / 2.0
	
	play_btn.pressed.connect(_on_play_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)

func _on_play_pressed():
	var tween = create_tween()
	tween.tween_property(play_btn, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	get_tree().call_deferred("change_scene_to_file", "res://main.tscn")

func _on_settings_pressed():
	var tween = create_tween()
	tween.tween_property(settings_btn, "scale", Vector2(0.92, 0.92), 0.08)
	tween.tween_property(settings_btn, "scale", Vector2(1.0, 1.0), 0.08)
	await tween.finished
	get_tree().call_deferred("change_scene_to_file", "res://settings_screen.tscn")
