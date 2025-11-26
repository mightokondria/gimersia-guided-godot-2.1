extends Area2D

# Pilih skill lewat Inspector nanti
@export_enum("dash", "double_jump", "wall_grab") var skill_to_unlock: String = "dash"

# Opsional: Dialog box untuk pesan "Skill Didapatkan!"
@export var dialog_box_scene: PackedScene 

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# 1. Buka skill di GameManager
		GameManager.unlock_skill(skill_to_unlock)
		
		# 2. (Opsional) Efek visual/suara
		# AudioPlayer.play("powerup")
		# create_particles()
		
		# 3. Hapus item ini agar tidak bisa diambil lagi
		queue_free()
		
		# 4. (Opsional) Logika pindah scene kembali ke Race atau tampilkan dialog
		print("Kembali ke balapan!")
