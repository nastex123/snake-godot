extends Node
class_name EatEffects

const WAVE_DURATION := 0.6

@onready var game_area: Node2D = get_node("/root/Game/GameArea")
@onready var audio_manager: Node = get_node("/root/Game/AudioManager")
@onready var screen_shake_cam = get_node("/root/Game/Camera2D")
@onready var bg_shader: ColorRect = get_node("/root/Game/GameArea/GridBackgroundShader")

var floating_text_scene = preload("res://FloatingText.gd")

func play(pos: Vector2, streak: int) -> void:
	audio_manager.play_eat(streak)
	screen_shake_cam.shake((streak - 1) * 0.8 + 0.5)

	var ft := floating_text_scene.new()
	ft.play(pos, HUD.get_streak_color(streak), streak)
	game_area.add_child(ft)

	var exp := preload("res://ExplosionEffect.gd").new()
	game_area.add_child(exp)
	exp.play(pos, HUD.get_streak_color(streak), streak)

	trigger_wave(pos, streak)

func trigger_wave(pos: Vector2, streak: int) -> void:
	bg_shader.material.set("shader_parameter/wave_time", WAVE_DURATION)
	bg_shader.material.set("shader_parameter/wave_center", Vector2(
		float(pos.x) / 30.0, float(pos.y) / 18.0
	))
	if streak == 5:
		bg_shader.material.set("shader_parameter/wave_flash", 0.15)

func update_wave(delta: float, run_data) -> void:
	if run_data.get("wave_time", 0.0) > 0:
		run_data.wave_time = max(0.0, run_data.wave_time - delta)
		bg_shader.material.set("shader_parameter/wave_time", run_data.wave_time)

	if run_data.get("wave_flash", 0.0) > 0:
		run_data.wave_flash = max(0.0, run_data.wave_flash - delta)
		bg_shader.material.set("shader_parameter/wave_flash", run_data.wave_flash)
