extends Node
## Cached original effects and synthetic calls; fixed player pools cap overlapping audio.
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var effects: Dictionary = {}
var music_gain := 0.45
var effects_gain := 0.65
var voice_cursor := 0
var attack_players: Array[AudioStreamPlayer] = []
var calls: Dictionary = {}
var call_next: Dictionary = {}
var global_call_next := 0.0
var attack_gain := 0.5
const COMBAT_CUES = {
	"explosion": preload("res://assets/audio/explosion.wav"),
	"win": preload("res://assets/audio/victory.wav"),
	"achievement": preload("res://assets/audio/achievement.wav")
}
const ATTACK_CALLS = {
	"scarlet": preload("res://assets/audio/attack_scarlet.wav"),
	"rapunzel": preload("res://assets/audio/attack_rapunzel.wav"),
	"snow_white": preload("res://assets/audio/attack_snow_white.wav"),
	"mulan": preload("res://assets/audio/attack_mulan.wav"),
	"ariel": preload("res://assets/audio/attack_ariel.wav")
}


func _ready() -> void:
	music = AudioStreamPlayer.new()
	var theme: AudioStreamOggVorbis = preload("res://assets/audio/adventure_theme.ogg").duplicate()
	theme.loop = true
	music.stream = theme
	add_child(music)
	for index in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		voices.append(player)
	for id in ["click", "hit", "upgrade", "win", "loss"]:
		effects[id] = make_tone(id)
	effects.merge(COMBAT_CUES, true)
	calls = ATTACK_CALLS.duplicate()
	for index in 2:
		var player := AudioStreamPlayer.new()
		add_child(player)
		attack_players.append(player)
	apply_volume(music_gain, effects_gain, attack_gain)


func apply_volume(music_value: float, effects_value: float, voice_value: float = 0.5) -> void:
	music_gain = clampf(music_value, 0, 1)
	effects_gain = clampf(effects_value, 0, 1)
	attack_gain = clampf(voice_value, 0, 1)
	for player in attack_players:
		player.volume_db = linear_to_db(maxf(0.0001, attack_gain * 0.65))
		if attack_gain <= 0:
			player.stop()
	for player in voices:
		player.volume_db = linear_to_db(maxf(0.0001, effects_gain * 0.3))
		if effects_gain <= 0:
			player.stop()
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


func reserve_call(id: String, now: float) -> bool:
	# Each heroine calls at most once every 4 seconds; a global gap avoids a chorus.
	if not calls.has(id) or now < global_call_next or now < float(call_next.get(id, 0)):
		return false
	global_call_next = now + 0.45
	call_next[id] = now + 4.0
	return true


func play_attack(id: String) -> void:
	if AudioServer.get_driver_name() == "Dummy" or attack_gain <= 0:
		return
	var available: AudioStreamPlayer
	for player in attack_players:
		if not player.playing:
			available = player
			break
	if available == null or not reserve_call(id, Time.get_ticks_msec() / 1000.0):
		return
	available.stream = calls[id]
	available.volume_db = linear_to_db(maxf(0.0001, attack_gain * 0.65))
	available.play()


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


func _notification(what:int) -> void:
	# Moving the game into the native window briefly exits the tree. Keep audio
	# resources alive during that reparent; only dispose when the owner is deleted.
	if what!=NOTIFICATION_PREDELETE:return
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	for player in voices + attack_players:
		if is_instance_valid(player):
			player.stop()
			player.stream = null
	effects.clear()
	calls.clear()
