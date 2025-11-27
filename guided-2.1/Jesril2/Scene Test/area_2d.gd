extends Area2D
@onready var dialog_ui: CanvasLayer = $"../DialogUi"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
			var dialog_data = [
			{
				"name": "Sensei",
				"text": "Lihatlah ke belakang. Rintangan yang dulu tampak mustahil, kini hanya menjadi jejak langkahmu."
			},
			{
				"name": "Cat",
				"text": "Semua berkat teknik yang Sensei ajarkan. Aku akhirnya berhasil melampauimu di rintangan terakhir ini."
			},
			{
				"name": "Sensei",
				"text": "Kau tidak hanya melampauiku. Kau telah menyempurnakan setiap gerakan yang kuajarkan. Tidak ada lagi yang tersisa untuk kuajarkan."
			},
			{
				"name": "Cat",
				"text": "Lalu, ke mana arah selanjutnya? Skill apa lagi yang menantiku di depan? Aku siap untuk stage berikutnya."
			},
			{
				"name": "Sensei",
				"text": "Tidak ada stage selanjutnya. Tugas seorang pemandu berakhir saat sang murid sudah mampu berdiri sendiri."
			},
			{
				"name": "Cat",
				"text": "Jadi... mulai sekarang aku tidak lagi mengejar bayanganmu?"
			},
			{
				"name": "Sensei",
				"text": "Benar. Sekarang giliranmu untuk menentukan garis finish-mu sendiri. Pergilah, tunjukkan jalan baru yang belum pernah kulihat."
			},
			{
				"name": "Cat",
				"text": "Saya mengerti. Terima kasih atas bimbingannya selama ini... Sensei."
			}
		]
		
		# Jalankan Dialog
		bottom_dialogue.start_dialogue(dialog_data)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
