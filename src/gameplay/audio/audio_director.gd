class_name AudioDirector
extends Node
## Plays sound effects (SFX bus) in response to EventBus events and loops the music (Music bus).
## Gameplay never calls audio directly.
## Collecting quickly raises the pitch step by step (resets after a short pause).

const POOL_SIZE: int = 10
const VOLUME_DB: float = -8.0
const STREAK_RESET_SEC: float = 0.6
const PITCH_STEP: float = 0.05
const MAX_PITCH: float = 1.8
const PITCH_JITTER: float = 0.06
const LEVEL_UP_PITCH: float = 1.25
const MUSIC_VOLUME_DB: float = -14.0
const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"

const SFX_COLLECT: AudioStream = preload("res://assets/audio/sfx/pop.wav")
const SFX_DELIVER: AudioStream = preload("res://assets/audio/sfx/drop.wav")
const SFX_SELL: AudioStream = preload("res://assets/audio/sfx/cash.wav")
const SFX_MONEY: AudioStream = preload("res://assets/audio/sfx/coin.wav")
const SFX_UNLOCK: AudioStream = preload("res://assets/audio/sfx/unlock.wav")
const MUSIC_LOOP: AudioStream = preload("res://assets/audio/music/farm_loop.wav")

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _streak: int = 0
var _last_collect_sec: float = -INF
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _music: AudioStreamPlayer


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.volume_db = VOLUME_DB
		player.bus = SFX_BUS
		add_child(player)
		_players.append(player)
	_start_music()
	EventBus.item_collected.connect(_on_item_collected)
	EventBus.item_delivered.connect(
		func(_item_id: StringName) -> void: _play(SFX_DELIVER, _jitter())
	)
	EventBus.item_sold.connect(
		func(_item_id: StringName, _count: int, _value: float) -> void: _play(SFX_SELL, _jitter())
	)
	EventBus.money_collected.connect(func(_amount: float) -> void: _play(SFX_MONEY, _jitter()))
	EventBus.unlock_completed.connect(func(_unlock_id: StringName) -> void: _play(SFX_UNLOCK, 1.0))
	EventBus.level_up.connect(func(_level: int) -> void: _play(SFX_UNLOCK, LEVEL_UP_PITCH))
	EventBus.upgrade_purchased.connect(
		func(_upgrade_id: StringName, _level: int) -> void: _play(SFX_SELL, _jitter())
	)
	EventBus.passive_purchased.connect(
		func(_node_id: StringName) -> void: _play(SFX_UNLOCK, LEVEL_UP_PITCH)
	)


## Stops and releases every sound on exit; a playback still referenced at quit is
## reported by the engine as leaked.
func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null


func music_player() -> AudioStreamPlayer:
	return _music


func _start_music() -> void:
	var stream := MUSIC_LOOP.duplicate() as AudioStream
	var wav := stream as AudioStreamWAV
	if wav != null:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	_music = AudioStreamPlayer.new()
	_music.stream = stream
	_music.bus = MUSIC_BUS
	_music.volume_db = MUSIC_VOLUME_DB
	# Fallback in case the imported stream ignores loop points.
	_music.finished.connect(_music.play)
	add_child(_music)
	_music.play()


func _on_item_collected(_item_id: StringName) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_collect_sec > STREAK_RESET_SEC:
		_streak = 0
	_last_collect_sec = now
	_streak += 1
	_play(SFX_COLLECT, minf(1.0 + _streak * PITCH_STEP, MAX_PITCH))


func _play(stream: AudioStream, pitch: float) -> void:
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


func _jitter() -> float:
	return 1.0 + _rng.randf_range(-PITCH_JITTER, PITCH_JITTER)
