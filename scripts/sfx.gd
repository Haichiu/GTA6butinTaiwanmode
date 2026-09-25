class_name Sfx
extends Node
## Sound effects (owned by the Game autoload: use Game.sfx.play("siren")). Everything is synthesized at startup into AudioStreamWAV,
## so there are no audio files to license and it works the same on desktop and web.

const RATE := 22050

var streams := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	streams["siren"] = _make(1.6, _siren)
	streams["stamp"] = _make(0.25, _stamp)
	streams["bell"] = _make(0.6, _bell)
	streams["horn"] = _make(0.7, _horn)
	streams["whistle"] = _make(0.7, _whistle)
	streams["crash"] = _make(0.6, _crash)
	streams["win"] = _make(0.8, _win)
	streams["shutter"] = _make(0.25, _shutter)
	var engine: AudioStreamWAV = _make(0.5, _engine)
	engine.loop_mode = AudioStreamWAV.LOOP_FORWARD
	engine.loop_end = int(0.5 * RATE)
	streams["engine"] = engine
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, volume_db := 0.0, delay := 0.0) -> void:
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(func() -> void: play(sound, volume_db))
		return
	for p in _players:
		if not p.playing:
			p.stream = streams[sound]
			p.volume_db = volume_db
			p.play()
			return


# --- Synthesis ---------------------------------------------------------------

func _make(seconds: float, fn: Callable) -> AudioStreamWAV:
	var n := int(seconds * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var v := clampf(fn.call(t, seconds), -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func _fade(t: float, length: float, tail := 0.08) -> float:
	return clampf((length - t) / tail, 0.0, 1.0) * clampf(t / 0.01, 0.0, 1.0)


# Police wail: pitch sweeps up and down twice.
func _siren(t: float, length: float) -> float:
	# Phase is the integral of f(t) = 700 + 450 * (0.5 - 0.5 cos(2πt / 0.8)).
	var phase := TAU * (700.0 * t + 450.0 * (0.5 * t - 0.5 * sin(TAU * t / 0.8) * 0.8 / TAU))
	var square := signf(sin(phase)) * 0.4 + sin(phase) * 0.6
	return 0.35 * square * _fade(t, length, 0.2)


# Rubber stamp: short low thump plus a click of noise.
func _stamp(t: float, _length: float) -> float:
	var thump := sin(TAU * 90.0 * t) * exp(-t * 30.0)
	var click := (randf() * 2.0 - 1.0) * exp(-t * 120.0) * 0.5
	return 0.9 * (thump + click)


# Bicycle bell: two dings with inharmonic partials.
func _bell(t: float, _length: float) -> float:
	var v := 0.0
	for start in [0.0, 0.2]:
		var u: float = t - start
		if u >= 0.0:
			v += (sin(TAU * 2600.0 * u) + 0.5 * sin(TAU * 3950.0 * u)) * exp(-u * 9.0)
	return 0.3 * v


# Car horn: two detuned square-ish tones.
func _horn(t: float, length: float) -> float:
	var a := signf(sin(TAU * 415.0 * t))
	var b := signf(sin(TAU * 520.0 * t))
	return 0.18 * (a + b) * _fade(t, length)


# Police whistle: high tone with a fast trill.
func _whistle(t: float, length: float) -> float:
	var f := 2900.0 + 120.0 * sin(TAU * 28.0 * t)
	return 0.25 * sin(TAU * f * t) * _fade(t, length, 0.15)


# Crash: decaying noise with a low body.
func _crash(t: float, _length: float) -> float:
	var noise := (randf() * 2.0 - 1.0) * exp(-t * 6.0)
	var body := sin(TAU * 60.0 * t) * exp(-t * 10.0)
	return 0.7 * noise + 0.5 * body


# Camera shutter: two sharp clicks.
func _shutter(t: float, _length: float) -> float:
	var v := 0.0
	for start in [0.0, 0.07]:
		var u: float = t - start
		if u >= 0.0:
			v += (randf() * 2.0 - 1.0) * exp(-u * 160.0)
	return 0.8 * v


# Win: rising arpeggio C5 E5 G5 C6.
func _win(t: float, _length: float) -> float:
	var notes := [523.25, 659.25, 783.99, 1046.5]
	var v := 0.0
	for i in notes.size():
		var u: float = t - i * 0.12
		if u >= 0.0:
			v += sin(TAU * notes[i] * u) * exp(-u * 5.0)
	return 0.25 * v


# 50cc scooter idle: buzzy sawtooth at ~50 Hz with a little noise. Looped; pitch follows speed.
func _engine(t: float, _length: float) -> float:
	var saw := fmod(t * 50.0, 1.0) * 2.0 - 1.0
	var pulse := sin(TAU * 24.0 * t) * 0.3  # whole cycles in 0.5 s, so the loop is seamless
	return 0.22 * (saw * 0.7 + pulse + (randf() * 2.0 - 1.0) * 0.08)
