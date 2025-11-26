extends Area2D

@export var lose_popup: Control
signal body_finished(body_node, stage_id)

@export var is_active: bool = true
@export var current_stage_id: int = 1

var is_cleared = false
var game_over_triggered = false

func _ready():
	# hubungkan body_entered (jika belum terhubung)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		connect("body_entered", Callable(self, "_on_body_entered"))
	if lose_popup:
		lose_popup.visible = false

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return

	if not body:
		return

	# hanya player atau sensei
	if body.is_in_group("player") or body.name == "Sensei":
		# emit local signal (opsional)
		emit_signal("body_finished", body, current_stage_id)

		# disable area safely
		set_deferred("monitoring", false)
		set_deferred("process_mode", false)

		# panggil GameManager secara deferred agar aman (hindari physics-callback issues)
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			# gunakan call_deferred supaya eksekusi pindah scene di frame berikutnya (aman)
			gm.call_deferred("request_change_scene_with_transition", true, current_stage_id)
		else:
			# fallback: lakukan deferred change langsung
			call_deferred("_fallback_change")

func _fallback_change() -> void:
	# fallback behavior: misalnya pindah ke scene kalah/menang default
	print("finish_line: fallback change (no GameManager found)")
