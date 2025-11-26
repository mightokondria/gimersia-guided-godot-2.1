# training_area_direct.gd
extends Area2D

@export var skill_name: String = "dash"      # "dash" | "wall_grip" | "double_jump"
@export var only_once: bool = true
@export var feedback_node: NodePath = NodePath("")

var _triggered: bool = false

func _ready() -> void:
	var cb := Callable(self, "_on_body_entered")
	if not is_connected("body_entered", cb):
		connect("body_entered", cb)

func _on_body_entered(body: Node) -> void:
	if _triggered and only_once:
		return
	if not body:
		return
	if not body.is_in_group("player"):
		return

	# 1) Aktifkan skill langsung pada player instance (paling penting)
	match skill_name:
		"dash":
			if body.has_method("enable_dash"):
				body.enable_dash()
				print("TrainingArea: enabled dash ON PLAYER directly")
		"wall_grip":
			if body.has_method("enable_wall_grip"):
				body.enable_wall_grip()
				print("TrainingArea: enabled wall_grip ON PLAYER directly")
		"double_jump":
			if body.has_method("enable_double_jump"):
				body.enable_double_jump()
				print("TrainingArea: enabled double_jump ON PLAYER directly")
		_:
			print("TrainingArea: unknown skill_name:", skill_name)

	# 2) Persist: simpan ke GameManager bila ada (agar skill tetap ada saat pindah scene)
	if Engine.has_singleton("GameManager"):
		var gm := Engine.get_singleton("GameManager")
		match skill_name:
			"dash":
				if gm.has_method("unlock_dash"):
					gm.unlock_dash()
			"wall_grip":
				if gm.has_method("unlock_wall_grip"):
					gm.unlock_wall_grip()
			"double_jump":
				if gm.has_method("unlock_double_jump"):
					gm.unlock_double_jump()

	# 3) feedback dan flag
	_triggered = true
	_show_feedback()

func _show_feedback() -> void:
	if feedback_node != NodePath(""):
		var n := get_node_or_null(feedback_node)
		if n and n is Control:
			n.visible = true
			var lbl := n.get_node_or_null("Label")
			if lbl and lbl is Label:
				lbl.text = "Skill unlocked: %s" % skill_name
			await get_tree().create_timer(1.5).timeout
			n.visible = false
	else:
		print("TrainingArea: unlocked ->", skill_name)
