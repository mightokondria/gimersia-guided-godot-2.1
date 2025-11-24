# portal_area.gd
extends Area2D

@export var target_scene_path: String = ""   # isi dari Inspector
var triggered := false

func _ready():
	var cb = Callable(self, "_on_body_entered")
	if not is_connected("body_entered", cb):
		connect("body_entered", cb)

func _on_body_entered(body):
	if triggered:
		return

	# pastikan yang masuk Player
	if not body.is_in_group("player"):
		return

	triggered = true
	print("PortalArea: player masuk portal")
	call_deferred("_do_change_scene")

	# minta GameManager yang meng-handle scene change
	if Engine.has_singleton("GameManager"):
		GameManager.change_scene(target_scene_path)
	else:
		push_warning("GameManager not found (autoload missing)")

func _do_change_scene():
	get_tree().change_scene_to_file("res://Scenes/Stages/tutorial_stage_2.tscn")
