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
		room.enemy_spawns = _generate_spawns(types[i], i)
		rooms.append(room)

func _generate_spawns(type: RoomData.Type, _index: int) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	match type:
		RoomData.Type.NORMAL:
			var count = 2 if _index < 3 else 3
			for j in count:
				spawns.append({"x": 8 + j * 3, "y": 9, "type": "slime"})
		RoomData.Type.BOSS:
			for j in 4:
				spawns.append({"x": 7 + j * 5, "y": 9, "type": "slime"})
	return spawns

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
