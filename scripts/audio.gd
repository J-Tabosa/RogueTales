extends Node
## Small original synthesized loop and interface/combat cues; no network or external samples.
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var music_gain := 0.45
var effects_gain := 0.65
var voice_cursor := 0


func _ready() -> void:
	music = AudioStreamPlayer.new()
	var theme: AudioStreamWAV = preload("res://assets/audio/camp_theme.wav").duplicate()
	theme.loop_mode = AudioStreamWAV.LOOP_FORWARD
	theme.loop_begin = 0
	theme.loop_end = theme.data.size() / 2
	music.stream = theme
	add_child(music)
	for index in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	for id in ["click", "hit", "upgrade", "win", "loss"]:
		effects[id] = make_tone(id)
	apply_volume(music_gain, effects_gain)


func apply_volume(music_value: float, effects_value: float) -> void:
	music_gain = clampf(music_value, 0, 1)
	effects_gain = clampf(effects_value, 0, 1)
	if music != null:
		music.volume_db = linear_to_db(maxf(0.0001, music_gain * 0.5))
		music.stream_paused = music_gain <= 0
		if music_gain > 0 and not music.playing and AudioServer.get_driver_name() != "Dummy":
			music.play()


func play_effect(id: String) -> void:
	if (
		AudioServer.get_driver_name() == "Dummy"
		or effects_gain <= 0
		or not effects.has(id)
		or voices.is_empty()
	):
		return
	var player: AudioStreamPlayer = voices[voice_cursor % voices.size()]
	voice_cursor += 1
	player.stream = effects[id]
	player.volume_db = linear_to_db(maxf(0.0001, effects_gain * 0.3))
	player.play()


func make_tone(id: String) -> AudioStreamWAV:
	var notes: Array = {
		"click": [760.0],
		"hit": [180.0, 110.0],
		"upgrade": [523.25, 659.25, 783.99],
		"win": [523.25, 659.25, 783.99, 1046.5],
		"loss": [330.0, 261.63, 196.0]
	}[id]
	var length := 0.045 if id == "click" else (0.045 if id == "hit" else 0.11)
	var count := int(22050 * length * notes.size())
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for index in count:
		var step := mini(int(index / (22050 * length)), notes.size() - 1)
		var local := fmod(index / 22050.0, length)
		var envelope := sin(PI * local / length) * exp(-local * 12)
		var value := sin(TAU * float(notes[step]) * local) * envelope
		bytes.encode_s16(index * 2, int(value * 17000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream


func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player in voices:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	effects.clear()
