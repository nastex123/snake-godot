extends Node
class_name GameManager

enum State { MENU, LOADING, PLAYING, UPGRADE, SHOP, BOSS, PAUSED, GAME_OVER, VICTORY }

signal state_changed(new_state: State)
signal game_started()
signal game_ended(reason: String)
signal room_entered(room_type: String)
signal boss_defeated(boss_id: String)
signal level_up(new_level: int)

var current_state: State = State.MENU

func change_state(new_state: State) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func start_run() -> void:
	change_state(State.PLAYING)
	game_started.emit()

func end_run(reason: String) -> void:
	change_state(State.GAME_OVER)
	game_ended.emit(reason)