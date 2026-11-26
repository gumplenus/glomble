extends Control

@onready var back_btn = $BackButton
@onready var name_input = $NameInput
@onready var email_value = $EmailValue
@onready var support_btn = $SupportButton
@onready var delete_btn = $DeleteButton

@onready var support_dialog = $SupportDialog
@onready var message_input = $SupportDialog/Box/MessageInput
@onready var send_btn = $SupportDialog/Box/SendButton
@onready var cancel_support_btn = $SupportDialog/Box/CancelSupportButton

@onready var delete_dialog = $DeleteDialog
@onready var confirm_delete_btn = $DeleteDialog/Box/ConfirmDeleteButton
@onready var cancel_delete_btn = $DeleteDialog/Box/CancelDeleteButton

const SAVE_PATH = "user://profile.cfg"
# Сюда позже подставим реальный URL вашего сервера / Formspree / Supabase для отправки на почту поддержки
const SUPPORT_API_URL = "" 
const PROFILE_API_URL = ""

var player_name = "Player"
var player_email = "player@example.com"
var http_request: HTTPRequest

func _ready():
	support_dialog.visible = false
	delete_dialog.visible = false
	
	# Создаем узел для тихой отправки запросов на сервер без открытия почтового клиента
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_http_request_completed)
	
	_load_profile()
	name_input.text = player_name
	email_value.text = player_email
	
	# Сохраняем имя при вводе и при закрытии мобильной клавиатуры (focus_exited)
	name_input.text_changed.connect(_on_name_changed)
	name_input.text_submitted.connect(func(_new_text): name_input.release_focus())
	name_input.focus_exited.connect(_on_name_commit)
	
	# Кнопки главного экрана настроек
	back_btn.pressed.connect(_on_back_pressed)
	support_btn.pressed.connect(_on_support_pressed)
	delete_btn.pressed.connect(_on_delete_pressed)
	
	# Кнопки окна Support
	send_btn.pressed.connect(_on_send_support_pressed)
	cancel_support_btn.pressed.connect(_on_cancel_support_pressed)
	
	# Кнопки окна Delete Account
	confirm_delete_btn.pressed.connect(_on_confirm_delete_pressed)
	cancel_delete_btn.pressed.connect(_on_cancel_delete_pressed)

func _animate_press(btn: Control) -> Tween:
	btn.pivot_offset = btn.size / 2.0
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.07)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.07)
	return tween

func _load_profile():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		# Сюда при регистрации запишутся реальные имя и почта игрока
		player_name = config.get_value("user", "name", "Player")
		player_email = config.get_value("user", "email", "player@example.com")

func _save_profile():
	var config = ConfigFile.new()
	config.set_value("user", "name", player_name)
	config.set_value("user", "email", player_email)
	config.save(SAVE_PATH)

func _on_name_changed(new_text: String):
	var cleaned = new_text.strip_edges()
	if not cleaned.is_empty():
		player_name = cleaned
		_save_profile()

func _on_name_commit():
	if name_input.text.strip_edges().is_empty():
		name_input.text = player_name
	_sync_name_to_database()

func _sync_name_to_database():
	if PROFILE_API_URL.is_empty():
		return
	var payload = JSON.stringify({
		"email": player_email,
		"name": player_name
	})
	var headers = ["Content-Type: application/json"]
	http_request.request(PROFILE_API_URL, headers, HTTPClient.METHOD_POST, payload)

func _on_back_pressed():
	await _animate_press(back_btn).finished
	get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn")

# --- ЛОГИКА ОКНА SUPPORT (ТИХАЯ ОТПРАВКА БЕЗ ПОЧТОВОГО КЛИЕНТА) ---
func _on_support_pressed():
	await _animate_press(support_btn).finished
	message_input.text = ""
	support_dialog.visible = true

func _on_cancel_support_pressed():
	await _animate_press(cancel_support_btn).finished
	support_dialog.visible = false

func _on_send_support_pressed():
	var text = message_input.text.strip_edges()
	if text.is_empty():
		return
	await _animate_press(send_btn).finished
	
	# Формируем данные для отправки на почту поддержки с указанием email игрока для ответа
	var payload_dict = {
		"reply_to": player_email,
		"player_name": player_name,
		"message": text
	}
	
	if not SUPPORT_API_URL.is_empty():
		var headers = ["Content-Type: application/json"]
		http_request.request(SUPPORT_API_URL, headers, HTTPClient.METHOD_POST, JSON.stringify(payload_dict))
	else:
		# Пока бэкенд не подключен, выводим сформированный пакет в консоль отладки
		print("Support ticket queued: ", payload_dict)
		
	support_dialog.visible = false

func _on_http_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	if result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300:
		print("Server sync OK")


# --- ЛОГИКА ОКНА DELETE ACCOUNT ---
func _on_delete_pressed():
	await _animate_press(delete_btn).finished
	delete_dialog.visible = true

func _on_cancel_delete_pressed():
	await _animate_press(cancel_delete_btn).finished
	delete_dialog.visible = false

func _on_confirm_delete_pressed():
	await _animate_press(confirm_delete_btn).finished
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	Engine.remove_meta("level_2_failed")
	delete_dialog.visible = false
	get_tree().call_deferred("change_scene_to_file", "res://main_menu.tscn")
