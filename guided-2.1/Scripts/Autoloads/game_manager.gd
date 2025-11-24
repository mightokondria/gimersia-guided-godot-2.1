# GameManager.gd (dipakai sebagai Autoload, Name: GameManager)
extends Node

var player: Node = null
var start_position: Node2D = null
var transition: Node = null
var after_image_container: Node = null
var is_transitioning: bool = false



func _ready() -> void:
	print("GameManager (autoload) ready. Waiting for level/player registration...")

# Panggil dari level root saat level ready:
func register_level(level_root: Node) -> void:
	start_position = level_root.get_node_or_null("StartPosition")
	transition = level_root.get_node_or_null("transition")
	after_image_container = level_root.get_node_or_null("AfterImageContainer")
	if not start_position:
		push_warning("GameManager: StartPosition not found in level_root")
	print("GameManager: level registered")

# Panggil dari Player._ready()
func register_player(p: Node) -> void:
	player = p
	var cb = Callable(self, "_on_player_create_after_image")
	if not player.is_connected("create_after_image", cb):
		player.connect("create_after_image", cb)
	print("GameManager: player registered:", player)

func _on_player_create_after_image(texture, spawn_pos, is_flipped) -> void:
	if after_image_container:
		print("after image")
		var s = Sprite2D.new()
		s.texture = texture
		s.global_position = spawn_pos
		s.flip_h = is_flipped
		after_image_container.add_child(s)
		s.modulate = Color(0.5,0.7,1,0.7)
		var tw = create_tween()
		tw.tween_property(s, "modulate", Color(0.5,0.7,1,0), 0.4)
		tw.tween_callback(Callable(s, "queue_free"))
	else:
		push_warning("GameManager: no after_image_container set")
