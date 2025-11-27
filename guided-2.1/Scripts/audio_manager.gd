extends Node

@onready var music_player: AudioStreamPlayer = $AudioStreamPlayer2D
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer


#List SFX
var dash1 = preload("res://Audio/SFX/dash_001.wav")
var dash2 = preload("res://Audio/SFX/dash_002.wav")
var double_jump = preload("res://Audio/SFX/double jump.wav")
var jump = preload("res://Audio/SFX/jump.wav")
var run = preload("res://Audio/SFX/lari (outdoor).wav")



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
