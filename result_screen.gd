extends Control

@onready var bubble = $Bubble
@onready var btn_frame = $ButtonContainer/BtnFrame
@onready var btn_inner = $ButtonContainer/BtnInner

# Сигнал, который сообщит игре, что кнопка нажата
signal ok_pressed

var is_pressed = false
var inner_start_y = 0.0

func _ready():
	# Запоминаем начальную позицию внутренней части кнопки
	inner_start_y = btn_inner.position.y
	# Подключаем клик мыши к функции нажатия
	btn_inner.gui_input.connect(_on_btn_inner_gui_input)

func setup(is_success: bool):
	# Эта функция будет вызываться из уровня, чтобы показать Success или Fail
	if is_success:
		bubble.texture = load("res://bubble_success.png")
	else:
		bubble.texture = load("res://bubble_fail.png")

func _on_btn_inner_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_pressed:
			is_pressed = true
			# Визуально утапливаем кнопку
			btn_inner.position.y = inner_start_y + 5
			btn_inner.modulate = Color(0.8, 0.8, 0.8) # Делаем чуть темнее
			
			# Ждем 0.1 секунды и возвращаем кнопку обратно
			await get_tree().create_timer(0.1).timeout
			btn_inner.position.y = inner_start_y
			btn_inner.modulate = Color(1, 1, 1)
			is_pressed = false
			
			# Сообщаем игре, что кнопка нажата
			ok_pressed.emit()
