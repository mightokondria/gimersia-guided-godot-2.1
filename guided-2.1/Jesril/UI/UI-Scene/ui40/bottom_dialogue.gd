extends CanvasLayer

signal dialogue_finished

# --- REFERENSI NODE ---
# Pastikan path ini sesuai dengan Scene Tree kamu
@onready var cat_container = $Control/MarginContainer/Cat
@onready var cat_label = $Control/MarginContainer/Cat/MarginContainer/RichTextLabel

@onready var fish_container = $Control/MarginContainer/fish
@onready var fish_label = $Control/MarginContainer/fish/MarginContainer/RichTextLabel

# --- VARIABEL LOGIC ---
var dialogue_queue: Array = []
var current_dialogue: Dictionary = {}
var is_typing: bool = false

# Tween variables
var type_tween: Tween # Untuk animasi teks ngetik
var anim_tween: Tween # Untuk animasi pop-up karakter

# SAKLAR PENGAMAN (Supaya tidak kepencet sebelum dialog mulai)
var is_dialogue_active: bool = false

func _ready():
	# Setup awal: Kita pastikan pivot ada di tengah biar animasi scale-nya bagus
	# Kita pakai call_deferred supaya nunggu UI selesai digambar dulu baru hitung size
	call_deferred("_setup_initial_state")

func _setup_initial_state():
	_setup_pivot(cat_container)
	_setup_pivot(fish_container)
	
	_reset_state(cat_container)
	_reset_state(fish_container)
	
	is_dialogue_active = false

func start_dialogue(data: Array):
	# Nyalakan saklar: Input sekarang akan didengar
	is_dialogue_active = true
	
	dialogue_queue = data
	_show_next_line()

func _show_next_line():
	if dialogue_queue.is_empty():
		_end_dialogue()
		return
	
	current_dialogue = dialogue_queue.pop_front()
	is_typing = true
	
	# Tentukan siapa Active (muncul) dan Inactive (hilang)
	var active_node: Control
	var inactive_node: Control
	var active_label: RichTextLabel
	
	if current_dialogue["name"] == "Cat":
		active_node = cat_container
		inactive_node = fish_container
		active_label = cat_label
	else:
		active_node = fish_container
		inactive_node = cat_container
		active_label = fish_label
	
	# --- ANIMASI TRANSISI (The Juice) ---
	_animate_speaker_change(active_node, inactive_node)
	
	# --- TYPEWRITER EFFECT ---
	active_label.text = current_dialogue["text"]
	active_label.visible_ratio = 0.0
	
	# Hitung durasi: 0.03 detik per huruf
	var duration = current_dialogue["text"].length() * 0.03
	
	if type_tween: type_tween.kill()
	type_tween = create_tween()
	type_tween.tween_property(active_label, "visible_ratio", 1.0, duration)
	type_tween.finished.connect(func(): is_typing = false)

func _animate_speaker_change(show_node: Control, hide_node: Control):
	# Kill tween animasi sebelumnya jika ada, biar ga tabrakan
	if anim_tween: anim_tween.kill()
	anim_tween = create_tween().set_parallel(true) # Jalankan animasi secara paralel
	
	# 1. ANIMASI MUNCUL (Active)
	show_node.visible = true
	
	# Tween Alpha ke 1 (Muncul)
	anim_tween.tween_property(show_node, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Tween Scale ke normal (1, 1) -> Efek "Pop"
	anim_tween.tween_property(show_node, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. ANIMASI HILANG (Inactive)
	if hide_node.visible:
		# Tween Alpha ke 0 (Pudar)
		anim_tween.tween_property(hide_node, "modulate:a", 0.0, 0.3)
		# Tween Scale jadi agak kecil sedikit saat hilang (efek mundur)
		anim_tween.tween_property(hide_node, "scale", Vector2(0.8, 0.8), 0.3)
		
		# Setelah selesai animasi, sembunyikan (sequential step)
		# Kita pakai timer sederhana karena dalam parallel tween agak tricky
		get_tree().create_timer(0.3).timeout.connect(func(): hide_node.visible = false)

func _input(event):
	# [PENTING] Cek dulu apakah dialog aktif? Kalau tidak, abaikan semua klik.
	if not is_dialogue_active:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if is_typing:
			# Kalau sedang ngetik, langsung selesaikan (Skip typing animation)
			if type_tween: type_tween.kill()
			
			# Paksa visible ratio jadi penuh
			if cat_container.visible and cat_container.modulate.a > 0.1: 
				cat_label.visible_ratio = 1.0
			elif fish_container.visible:
				fish_label.visible_ratio = 1.0
			
			is_typing = false
		else:
			# Kalau sudah selesai ngetik, lanjut baris berikutnya
			_show_next_line()

func _end_dialogue():
	is_dialogue_active = false
	
	# Animasi tutup dialog (Fade out keduanya)
	var t = create_tween().set_parallel(true)
	if cat_container.visible:
		t.tween_property(cat_container, "modulate:a", 0.0, 0.2)
	if fish_container.visible:
		t.tween_property(fish_container, "modulate:a", 0.0, 0.2)
	
	await t.finished
	
	cat_container.visible = false
	fish_container.visible = false
	dialogue_finished.emit()

# --- HELPER UTILS ---
func _setup_pivot(node: Control):
	# Set pivot offset ke tengah node agar animasi scale membesar dari tengah
	node.pivot_offset = node.size / 2 

func _reset_state(node: Control):
	node.visible = false
	node.modulate.a = 0.0
	node.scale = Vector2(0.8, 0.8) # Mulai dari 80% ukuran
