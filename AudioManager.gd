extends Node

const SAMPLE_RATE := 22050

var eat_players: Array[AudioStreamPlayer] = []
var harmony_player: AudioStreamPlayer
var eat_stream: AudioStreamWAV
var harmony_stream: AudioStreamWAV

func _ready() -> void:
	eat_stream = _make_square_wav(440.0, 0.12, 1.0)
	harmony_stream = _make_square_wav(220.0, 0.18, 0.35)

	for i in 4:
		var p := AudioStreamPlayer.new()
		p.name = "EatPlayer" + str(i)
		p.stream = eat_stream
		add_child(p)
		eat_players.append(p)

	harmony_player = AudioStreamPlayer.new()
	harmony_player.name = "HarmonyPlayer"
	harmony_player.stream = harmony_stream
	harmony_player.volume_db = -6.0
	add_child(harmony_player)

func _find_free_player() -> AudioStreamPlayer:
	for p in eat_players:
		if not p.playing:
			return p
	return eat_players[0]

func play_eat(streak_level: int) -> void:
	var pitch := 1.0 + (streak_level - 1) * 0.12
	var p := _find_free_player()
	p.pitch_scale = pitch
	p.play()

	if streak_level >= 4:
		harmony_player.pitch_scale = pitch * 0.5
		harmony_player.play()

func _make_square_wav(freq: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var num_samples := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(num_samples)

	for i in num_samples:
		var t := float(i) / SAMPLE_RATE
		var phase := fmod(t * freq, 1.0)
		var val := 1.0 if phase < 0.5 else -1.0
		var env := 1.0 - float(i) / num_samples
		val *= env * env
		val *= amplitude
		data[i] = wrapi(int(val * 127.0), 0, 256)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = data
	return wav
