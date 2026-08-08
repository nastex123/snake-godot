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
			var towers: Array[Dictionary] = [
				{"x": 3, "y": 3, "type": "tower", "pattern": 1},
				{"x": 26, "y": 14, "type": "tower", "pattern": 5},
				{"x": 20, "y": 14, "type": "tower", "pattern": 4},
			]
			var t = towers[_index % towers.size()]
			if _index >= 2:
				spawns.append(t)
			else:
				spawns.append({"x": 26, "y": 3, "type": "tower", "pattern": t["pattern"]})
		RoomData.Type.EVENT:
			spawns.append({"x": 6, "y": 8, "type": "tower", "pattern": 4})
		RoomData.Type.SHOP:
			spawns.append({"x": 12, "y": 15, "type": "tower", "pattern": 3})
			spawns.append({"x": 20, "y": 6, "type": "tower", "pattern": 5})
		RoomData.Type.BOSS:
			for j in 4:
				spawns.append({"x": 7 + j * 5, "y": 9, "type": "slime"})
			spawns.append({"x": 2, "y": 4, "type": "tower", "pattern": 6})
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
