extends Area2D

# Nama kunci (Harus sama dengan yang diminta pintu!)
@export var key_id: String = "key_dash_room" 

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# 1. Simpan kunci ke GameManager
		if has_node("/root/GameManager"):
			GameManager.add_key(key_id)
		
		# 2. (Opsional) Efek suara/partikel di sini
		print("Dapat kunci: ", key_id)
		
		# 3. Hapus item
		queue_free()
