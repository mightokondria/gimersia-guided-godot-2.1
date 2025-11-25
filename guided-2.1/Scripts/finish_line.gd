extends Area2D

var has_winner = false # Variabel untuk memastikan tidak ada juara ganda

func _ready():
	# Hubungkan sinyal jika belum
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Jika sudah ada pemenang, abaikan yang masuk belakangan
	if has_winner:
		return

	# Cek siapa yang masuk?
	
	# 1. JIKA PLAYER (Cek Grup atau Layer 2)
	if body.is_in_group("player"):
		has_winner = true
		print(">>> PLAYER MENANG! <<<")
		_game_over(true)

	# 2. JIKA GHOST (Cek Layer 3)
	# FIX: Kita cek dulu apakah body punya method 'get_collision_layer_value'
	# TileMapLayer tidak punya method ini, jadi akan error tanpa pengecekan.
	elif body.has_method("get_collision_layer_value") and body.get_collision_layer_value(3): 
		has_winner = true
		print(">>> PLAYER KALAH! (Ghost Menang) <<<")
		_game_over(false)

func _game_over(player_won: bool):
	# Di sini nanti Anda bisa tambahkan UI (Menang/Kalah)
	# Untuk sekarang kita print dulu dan mungkin stop game
	if player_won:
		modulate = Color.GREEN # Ubah warna tiang jadi hijau
	else:
		modulate = Color.RED   # Ubah warna tiang jadi merah
