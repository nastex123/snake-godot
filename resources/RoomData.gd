extends Resource
class_name RoomData

enum Type { NORMAL, ELITE, EVENT, REST, TREASURE, SHOP, BOSS }

@export var room_type: Type = Type.NORMAL
@export var room_index: int = 0
@export var is_cleared: bool = false
@export var is_boss: bool = false
@export var connections: Array[int] = []
