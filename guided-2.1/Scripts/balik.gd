extends Area2D

# Path tujuan sesuai request kamu
var target_scene_path: String = "res://Scenes/Stages-experimental/race_stage.tscn"

# Signal ini harus dihubungkan via tab Node -> body_entered
func _on_body_entered(body: Node) -> void:
	# Cek apakah yang menyentuh adalah Player
	# (Sesuaikan string "Player" dengan nama node player kamu di Scene Tree)
	if body.name == "Player" or body.is_in_group("player"):
		print("Balik Area: Tersentuh player, pindah ke race_stage...")
		
		# Menggunakan GameManager agar transisi lebih aman
		if GameManager:
			# Parameter kedua kosong ("") karena kita belum set spawn point khusus di sana
			GameManager.request_change_scene(target_scene_path, "")
		else:
			# Fallback jika GameManager error (Jaga-jaga)
			get_tree().change_scene_to_file(target_scene_path)
