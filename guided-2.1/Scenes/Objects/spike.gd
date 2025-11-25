extends Area2D

func _ready():
	# --- PERBAIKAN OTOMATIS MASK ---
	# Karena Player dipindah ke Layer 2, kita pastikan Duri bisa melihat Layer 2.
	# Set bit ke-2 (nilai 2) pada mask agar aktif mendeteksi Player.
	set_collision_mask_value(2, true) 
	
	# Hubungkan sinyal secara otomatis
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node):
	# DEBUG: Cek apakah sinyal masuk sama sekali
	# print("Spike disentuh oleh: ", body.name) 

	# 1. Cek apakah yang menginjak adalah Player
	if body.is_in_group("player"):
		# Cek apakah player sedang dalam proses respawn (controls_enabled == false)
		# Ini mencegah fungsi dipanggil berkali-kali dalam 1 detik
		if "controls_enabled" in body and body.controls_enabled == false:
			# print("Spike: Player kena tapi sedang kebal (Frozen/Respawning)")
			return
			
		print("Auch! Kena duri.")
		_start_death_sequence(body)

func _start_death_sequence(player_node):
	# Cek dulu apakah tujuan respawn ada (diset oleh Level Controller via GameManager)
	if not (GameManager and GameManager.start_position):
		push_warning("Spike: Gagal respawn. StartPosition belum terdaftar!")
		return

	# A. Bekukan Player (Stop Gerak & Input)
	if player_node.has_method("freeze"):
		player_node.freeze()
	
	# B. Setup Tween untuk Animasi Getar
	var tw = create_tween()
	
	# Kita ambil sprite anak dari player untuk digoyangkan
	var sprite = player_node.get_node_or_null("AnimatedSprite2D")
	var original_sprite_pos = Vector2.ZERO
	if sprite:
		original_sprite_pos = sprite.position
	
	# 1. Ubah warna jadi Merah (Indikasi sakit)
	tw.tween_property(player_node, "modulate", Color(1, 0.2, 0.2), 0.05)
	
	# 2. Efek Getar (Shake) selama kurang lebih 0.3 detik
	var shake_power = 5.0
	for i in range(6):
		var random_offset = Vector2(randf_range(-shake_power, shake_power), randf_range(-shake_power, shake_power))
		if sprite:
			# Goyang sprite-nya
			tw.tween_property(sprite, "position", original_sprite_pos + random_offset, 0.05)
	
	# 3. Kembalikan kondisi normal (Warna putih & Posisi sprite reset)
	tw.tween_property(player_node, "modulate", Color.WHITE, 0.1)
	if sprite:
		tw.tween_property(sprite, "position", original_sprite_pos, 0.01)
	
	# 4. Panggil fungsi teleport SETELAH semua animasi selesai
	tw.tween_callback(Callable(self, "_finish_respawn").bind(player_node))

func _finish_respawn(player_node):
	# Pindahkan posisi player ke Start Position
	if GameManager and GameManager.start_position:
		player_node.global_position = GameManager.start_position.global_position
		# Reset momentum jatuh agar tidak 'terbang'
		player_node.velocity = Vector2.ZERO
	
	# Kembalikan kontrol ke pemain
	if player_node.has_method("unfreeze"):
		player_node.unfreeze()
