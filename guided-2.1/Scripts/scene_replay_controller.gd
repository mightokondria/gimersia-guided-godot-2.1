extends Node2D

# Script ini dipasang di Root Node dari Scene yang ingin memutar replay secara otomatis.

func _ready():
	# 1. Pastikan ReplayManager ada
	var ReplayManager = null
	if Engine.has_singleton("ReplayManager"):
		ReplayManager = Engine.get_singleton("ReplayManager")
	elif has_node("/root/ReplayManager"):
		ReplayManager = get_node("/root/ReplayManager")
		
	# 2. Mulai Playback Otomatis
	if ReplayManager:
		# Tunggu sebentar agar GhostPlayer siap di tree
		await get_tree().create_timer(0.1).timeout
		
		print("Scene Baru: Meminta ReplayManager untuk memulai playback...")
		ReplayManager.start_playback()
	else:
		push_error("Gagal memulai replay: ReplayManager tidak ditemukan.")

# (Opsional) Jika ingin tombol kembali ke menu
func _input(event):
	if event.is_action_pressed("ui_cancel"): # Tombol Escape
		get_tree().change_scene_to_file("res://MainMenu.tscn") # Ganti dengan path menu Anda
