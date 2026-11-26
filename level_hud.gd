extends CanvasLayer

@onready var home_btn = $HomeButton
@onready var sound_btn = $SoundButton
@onready var exit_dialog = $ExitDialog
@onready var yes_btn = $ExitDialog/Box/YesButton
@onready var no_btn = $ExitDialog/Box/NoButton

var tex_sound_on = preload("res://btn_sound_on.png")
var tex_sound_off = preload("res://btn_sound_off.png")

func _ready():
	exit_dialog.visible = false
	
	# Синхронизируем иконку звука
	var is_muted = AudioServer.is_bus_mute(0)
	sound_btn.texture_normal = tex_sound_off if is_muted else tex_sound_on
	
	home_btn.pressed.connect(_on_home_pressed)
	sound_btn.pressed.connect(_on_sound_pressed)
	yes_btn.pressed.connect(_on_yes_pressed)
	no_btn.pressed.connect(_on_no_pressed)

func _animate_press(btn: Control) -> Tween:
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.07)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.07)
	return tween

func _on_home_pressed():
	await _animate_press(home_btn).finished
	exit_dialog.visible = true

func _on_sound_pressed():
	_animate_press(sound_btn)
	var is_muted = not AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0, is_muted)
	sound_icon_update(is_muted)

func sound_icon_update(is_muted: bool):
	sound_btn.texture_normal = tex_sound_off if is_muted else tex_sound_on

func _on_yes_pressed():
	await _animate_press(yes_btn).finished
	get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn")

func _on_no_pressed():
	await _animate_press(no_btn).finished
	exit_dialog.visible = false
