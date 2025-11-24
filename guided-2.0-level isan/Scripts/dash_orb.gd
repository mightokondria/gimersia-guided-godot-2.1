extends AnimatedSprite2D

# Pengaturan untuk gerakan melingkar
@export var radius = 2.0
@export var speed = 10.0
# Offset untuk titik pusat putaran
@export var orbit_offset = Vector2(-10, 0)

# Variabel untuk melacak sudut dan status
var angle = 0.0
var is_available = true # Ini akan melacak apakah dash bisa digunakan

func _ready():
	play("static")

# _process berjalan di setiap frame, menggerakkan orb
func _process(delta):
	# Perbarui sudut putaran seiring waktu
	angle += speed * delta
	
	# PERBAIKAN POSISI: Tambahkan orbit_offset ke perhitungan
	position.x = orbit_offset.x + cos(angle) * radius
	position.y = orbit_offset.y + sin(angle) * radius

# --- Fungsi yang dipanggil oleh Pemain ---

# Fungsi ini dipanggil saat pemain menggunakan dash
func use_dash():
	# PERBAIKAN ANIMASI: Hanya jalankan jika dash memang tersedia
	if is_available:
		is_available = false
		play("breaks")

# Fungsi ini dipanggil saat dash pemain siap lagi
func reset_dash():
	# PERBAIKAN ANIMASI: Hanya jalankan jika dash sebelumnya tidak tersedia
	if not is_available:
		is_available = true
		play("formed")
		await animation_finished # Tunggu animasi selesai
		play("static") # Kembali ke state 'static'
