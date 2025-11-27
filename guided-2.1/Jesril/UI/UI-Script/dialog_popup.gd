extends CanvasLayer # Atau Control, sesuaikan dengan root node kamu

# --- REFERENSI NODE SESUAI GAMBAR ---
# Menggunakan path berdasarkan struktur pohon di screenshot
@onready var cat_box = $Control/MarginContainer/Cat
@onready var cat_label = $Control/MarginContainer/Cat/MarginContainer/RichTextLabel

@onready var fish_box = $Control/MarginContainer/fish
@onready var fish_label = $Control/MarginContainer/fish/MarginContainer/RichTextLabel

# --- VARIABEL LOGIC ---
var dialog_queue: Array = [] # Antrian dialog
var is_active: bool = false

func _ready():
	# Sembunyikan semua di awal
	visible = false
	cat_box.visible = false
	fish_box.visible = false

func _input(event):
	if not is_active:
		return
		
	# Tekan Spasi / Enter / Klik Kiri untuk lanjut dialog
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select") or (event is InputEventMouseButton and event.pressed):
		advance_dialog()

# --- FUNGSI UTAMA ---

# Fungsi untuk memulai percakapan
# Format data: [{"char": "Cat", "text": "Halo"}, {"char": "fish", "text": "Glub glub"}]
func start_dialog(data: Array):
	dialog_queue = data
	is_active = true
	visible = true
	get_tree().paused = true # Pause game saat dialog
	
	advance_dialog() # Tampilkan baris pertama

func advance_dialog():
	if dialog_queue.is_empty():
		end_dialog()
		return
		
	# Ambil data dialog paling depan
	var current_line = dialog_queue.pop_front()
	
	# Logic ganti kotak dialog (Toggle Visibility)
	if current_line["char"] == "Cat":
		show_cat_box(current_line["text"])
	elif current_line["char"] == "fish":
		show_fish_box(current_line["text"])

func show_cat_box(text_value):
	fish_box.visible = false # Sembunyikan ikan
	cat_box.visible = true   # Munculkan kucing
	cat_label.text = text_value # Update text

func show_fish_box(text_value):
	cat_box.visible = false  # Sembunyikan kucing
	fish_box.visible = true  # Munculkan ikan
	fish_label.text = text_value

func end_dialog():
	is_active = false
	visible = false
	get_tree().paused = false # Resume game
