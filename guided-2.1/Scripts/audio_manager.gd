extends Node

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer2D
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer





# Fungsi untuk memutar musik
func play_music(audio_stream: AudioStream):
	# 1. Cek apakah ada lagu yang sedang diputar
	if music_player.stream == audio_stream and music_player.playing:
		return # Jika lagunya SAMA, jangan di-restart. Biarkan lanjut.
	
	# 2. Jika lagunya BEDA, ganti stream dan mainkan
	music_player.stream = audio_stream
	music_player.play()
	
# Fungsi untuk stop musik (opsional)
func stop_music():
	music_player.stop()
	
# FUNGSI BARU UNTUK SFX
func play_sfx(audio_stream: AudioStream):
	# SFX beda dengan music, tidak perlu cek "sedang main atau tidak"
	# Kita timpa saja suaranya, atau gunakan logic lain
	sfx_player.stream = audio_stream
	sfx_player.play()
