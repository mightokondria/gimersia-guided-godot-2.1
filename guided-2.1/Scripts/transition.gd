extends CanvasLayer

# Sinyal ini akan kita pancarkan tepat di tengah transisi
signal transition_midpoint_reached

@onready var animation_player = $AnimationPlayer

# Fungsi ini akan kita panggil dari level
func start_transition():
	# Putar animasi masuk dan tunggu sampai selesai
	animation_player.play("slide_in")
	await animation_player.animation_finished

	# Pancarkan sinyal bahwa layar sudah sepenuhnya hitam
	emit_signal("transition_midpoint_reached")

	# Putar animasi keluar dan tunggu sampai selesai
	animation_player.play("slide_out")
	await animation_player.animation_finished
