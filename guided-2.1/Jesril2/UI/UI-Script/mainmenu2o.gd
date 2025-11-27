extends Control
@onready var music: AudioStreamPlayer = $AudioStreamPlayer2D

var menu_music = preload("res://Audio/BGM/indoor_bgm.mp3") 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		# 2. PANGGIL AUDIO MANAGER
	# Karena AudioManager adalah Autoload, dia bisa dipanggil dari mana saja
	if AudioManager:
		AudioManager.play_music(menu_music)
	else:
		print("Error: AudioManager belum diload di Project Settings -> Globals")
	modulate.a = 0
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)  # Fade in 1 detik

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Jesril2/UI/UI-Scene/ui120/Loading.tscn")

func _on_settings_pressed() -> void:
	pass # Replace with function body.

func _on_credits_pressed() -> void:
	pass # Replace with function body.

func _on_exit_pressed() -> void:
	get_tree().quit()
