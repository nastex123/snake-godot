extends Node
class_name MapManager

var rooms: Array[RoomData] = []
var current_room_index: int = 0

func generate_map() -> void:
	rooms.clear()
	current_room_index = 0
	var types := [
		RoomData.Type.NORMAL,
		RoomData.Type.NORMAL,
		RoomData.Type.NORMAL,
		RoomData.Type.EVENT,
		RoomData.Type.NORMAL,
		RoomData.Type.SHOP,
		RoomData.Type.BOSS,
	]
	for i in types.size():
		var room := RoomData.new()
		room.room_type = types[i]
		room.room_index = i
		room.is_boss = types[i] == RoomData.Type.BOSS
		if i < types.size() - 1:
			room.connections = [i + 1]
		rooms.append(room)

func get_current_room() -> RoomData:
	if current_room_index < rooms.size():
		return rooms[current_room_index]
	return null

func has_next_room() -> bool:
	return current_room_index < rooms.size() - 1

func advance_room() -> bool:
	if not has_next_room():
		return false
	current_room_index += 1
	return true

func mark_room_cleared() -> void:
	var room := get_current_room()
	if room:
		room.is_cleared = true
