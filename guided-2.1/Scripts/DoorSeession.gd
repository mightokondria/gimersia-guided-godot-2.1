# DoorSession.gd
extends Node

# Runtime-only door usage tracker (no file saving)
var used_doors: Dictionary = {}

func _ready() -> void:
	print("DoorSession ready (runtime-only).")

# Tandai door sebagai sudah dipakai
func mark_used(door_id: String) -> void:
	if door_id == "":
		return
	used_doors[door_id] = true
	print("DoorSession: mark_used ->", door_id)

# Cek apakah door sudah dipakai
func is_used(door_id: String) -> bool:
	if door_id == "":
		return false
	return used_doors.get(door_id, false)

# Debug helper: clear all (useful for testing)
func clear_all() -> void:
	used_doors.clear()
	print("DoorSession: cleared all used doors")
