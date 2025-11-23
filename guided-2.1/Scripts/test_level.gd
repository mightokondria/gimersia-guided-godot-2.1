extends Node2D

@onready var player: CharacterBody2D = $player
@onready var start_position = $StartPosition
@onready var transition = $transition
@onready var after_image_container = $AfterImageContainer

var camera_positions = {}
var current_camera_index = 1
var is_transitioning = false

func _ready():
	# Muat semua posisi kamera ke dalam dictionary
	player.global_position = start_position.global_position

# --- Logika Reset ---
func _on_finish_area_body_entered(body):
	if body == player and not is_transitioning:
		transition.start_transition()

func _on_transition_transition_midpoint_reached():
	player.global_position = start_position.global_position
	player.velocity = Vector2.ZERO


func _on_player_create_after_image(texture, spawn_pos, is_flipped):
	# 1. Buat node Sprite2D baru dari kode
	var after_image = Sprite2D.new()

	# 2. Atur propertinya berdasarkan data dari pemain
	after_image.texture = texture
	after_image.global_position = spawn_pos
	after_image.flip_h = is_flipped
	
	# 3. Tambahkan ke adegan di dalam kontainer
	after_image_container.add_child(after_image)
	
	# 4. Atur warna awal (biru semi-transparan seperti Celeste)
	after_image.modulate = Color(0.5, 0.7, 1, 0.7)
	
	# 5. Buat Tween untuk memudarkannya
	var tween = create_tween()
	# Animasikan properti 'modulate' dari warna saat ini ke warna transparan total
	tween.tween_property(after_image, "modulate", Color(0.5, 0.7, 1, 0), 0.4)
	
	# 6. Setelah animasi pudar selesai, hapus node tersebut
	tween.tween_callback(after_image.queue_free)
