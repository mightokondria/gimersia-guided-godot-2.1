extends Control

var bgm_gameplay = preload("res://Audio/BGM/indoor_bgm.mp3")
@onready var pause_menu: Control = $PauseMenu2
@onready var restart_2: Button = $PauseMenu2/Panel2/Restart2
@onready var music_slider: HSlider = $PauseMenu2/Panel2/VBoxContainer/MarginContainer/VBoxContainer2/HBoxContainer3/HSlider
@onready var sfx_slider: HSlider = $PauseMenu2/Panel2/VBoxContainer/MarginContainer/VBoxContainer2/HBoxContainer2/HSlider

# Kita butuh index (urutan) dari Bus "Music" yang tadi kita buat
var music_bus_index : int
var sfx_bus_index : int # <-- Tambahan baru

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AudioManager.play_music(bgm_gameplay)
	modulate.a = 0
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)  # Fade in 1 detik
	# 1. Cari urutan bus bernama "Music"
	music_bus_index = AudioServer.get_bus_index("Music")
	
	# 2. Set nilai awal slider sesuai volume sekarang
	# Kita konversi dari dB (Audio) ke Linear (Slider) supaya slidernya pas
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))
	
	# 3. Hubungkan signal slider (value_changed) via kode (atau bisa via editor)
	music_slider.value_changed.connect(_on_music_slider_value_changed)
	
	# 2. Setup SFX (Kode BARU)
	# Cari index bus bernama "SFX"
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# Set posisi slider sesuai volume asli di Audio Panel
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	
	# Hubungkan signal
	sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Jesril/UI/UI-Scene/ui120/Loading.tscn")

func _on_settings_pressed() -> void:
	pause_menu.visible = true
	pass # Replace with function body.

func _on_credits_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_restart_2_pressed() -> void:
	pause_menu.visible = false
	
	print("button pressed")
	

func _on_main_menu_pressed() -> void:
	pause_menu.visible = false
	
# Fungsi yang jalan saat slider digeser
func _on_music_slider_value_changed(value: float):
	# AudioServer butuh nilai dB, tapi slider ngasih nilai 0.0 - 1.0
	# Gunakan fungsi bawaan linear_to_db() untuk konversi
	AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(value))
	
	# Opsional: Jika slider mentok kiri (0), mute total
	if value == 0:
		AudioServer.set_bus_mute(music_bus_index, true)
	else:
		AudioServer.set_bus_mute(music_bus_index, false)

func _on_sfx_slider_value_changed(value: float): # <-- Fungsi Baru
	AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(sfx_bus_index, value == 0)
