extends CanvasLayer

signal transition_finished # Sinyal untuk memberi tahu kalau layar sudah gelap total

@onready var anim_player = $AnimationPlayer
@onready var color_rect = $ColorRect

func _ready():
	# Pastikan transisi tidak terlihat saat game mulai
	color_rect.visible = false
	color_rect.modulate.a = 0

# Fungsi 1: Transisi Sederhana (Ganti Scene)
func transition_to_scene(target_scene_path: String):
	# 1. Mulai Fade Out (Layar jadi gelap)
	color_rect.visible = true
	anim_player.play("fade_to_black")
	
	# 2. Tunggu animasi selesai
	await anim_player.animation_finished
	
	# 3. Pindah Scene
	if GameManager:
		# Gunakan logika GameManager jika ada (untuk handle spawn ID dll)
		GameManager.request_change_scene(target_scene_path)
	else:
		# Fallback manual
		get_tree().change_scene_to_file(target_scene_path)
	
	# 4. Mulai Fade In (Layar jadi terang di scene baru)
	anim_player.play("fade_to_normal")
	await anim_player.animation_finished
	color_rect.visible = false

# Fungsi 2: Manual Fade Out (Hanya menggelapkan)
func fade_out():
	color_rect.visible = true
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	emit_signal("transition_finished")

# Fungsi 3: Manual Fade In (Hanya menerangkan)
func fade_in():
	anim_player.play("fade_to_normal")
	await anim_player.animation_finished
	color_rect.visible = false
	emit_signal("transition_finished")
