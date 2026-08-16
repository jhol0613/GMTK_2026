extends Node


enum MusicTrack {
	LEVEL_0,
	LEVEL_1,
}


const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
const AMBIENT_BUS: StringName = &"Ambient"
const REST_OPEN_CUTOFF_HZ: float = 20000.0
const REST_CUTOFF_HZ: float = 1100.0
const REST_FILTER_DURATION: float = 0.6

var _music_volume_linear: float = 1.0
var _sfx_volume_linear: float = 1.0

const LEVEL_0_BGM: AudioStream = preload(
	"uid://dg0waag44ulse"
)

const LEVEL_1_BGM: AudioStream = preload(
	"uid://c12ly8vl2parx"
)

const LEVEL_0_MUSIC_DB: float = -8.0
const LEVEL_1_MUSIC_DB: float = -8.0

const TRIPPED_BGM: AudioStream = preload(
	"uid://bwdovww0j8m0k"
)

const NOTEBOOK_BGM: AudioStream = preload(
	"uid://b4i1hxorrwm14"
)

const TRAIN_PULLING_IN: AudioStream = preload(
	"res://level_elements/train/Train Pulling Into.mp3"
)

const TRAIN_PULLING_IN_NO_DOORS: AudioStream = preload(
	"res://level_elements/train/Pulling out without door opening.mp3"
)

const TRAIN_PULLING_OUT: AudioStream = preload(
	"res://level_elements/train/Pulling Out.mp3"
)

const TRAIN_PULLING_OUT_NO_DOORS: AudioStream = preload(
	"res://level_elements/train/Pulling out without door opening.mp3"
)

const WRONG_TICKET_SFX: AudioStream = preload(
	"uid://dw760ndv2ehvj"
)


const SILENT_DB: float = -40.0
const DEFAULT_MUSIC_DB: float = -4.0
const NOTEBOOK_MUSIC_DB: float = -4.0
const NOTEBOOK_FADE_IN_DURATION: float = 0.35
const NOTEBOOK_FADE_OUT_DURATION: float = 2.0


var _music_player: AudioStreamPlayer
var _notebook_player: AudioStreamPlayer
var _train_player: AudioStreamPlayer
var _ui_sfx_player: AudioStreamPlayer

var _music_tween: Tween
var _crossfade_tween: Tween
var _rest_filter_tween: Tween
var _music_low_pass: AudioEffectLowPassFilter
var _ambient_low_pass: AudioEffectLowPassFilter

var _level_music_track: int = MusicTrack.LEVEL_0
var _music_target_db: float = DEFAULT_MUSIC_DB
var _notebook_is_open: bool = false

var _sequence_id: int = 0

var _pause_return_stream: AudioStream
var _pause_return_position: float = 0.0
var _pause_return_target_db: float = DEFAULT_MUSIC_DB
var _pause_return_was_playing: bool = false
var _pause_menu_music_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_bus(MUSIC_BUS)
	_ensure_audio_bus(SFX_BUS)
	_ensure_audio_bus(AMBIENT_BUS, SFX_BUS)
	_music_low_pass = _ensure_low_pass(MUSIC_BUS)
	_ambient_low_pass = _ensure_low_pass(AMBIENT_BUS)

	_music_player = _create_player(
		"MainMusicPlayer",
		MUSIC_BUS
	)
	_notebook_player = _create_player(
		"NotebookMusicPlayer",
		MUSIC_BUS
	)
	_train_player = _create_player(
		"TrainSFXPlayer",
		SFX_BUS
	)
	_ui_sfx_player = _create_player(
		"UISFXPlayer",
		SFX_BUS
	)

	_notebook_player.stream = NOTEBOOK_BGM
	_notebook_player.volume_db = SILENT_DB

	SignalBus.notebook_opened.connect(
		_on_notebook_opened
	)
	SignalBus.notebook_closed.connect(
		_on_notebook_closed
	)
	SignalBus.rest_started.connect(_on_rest_started)
	SignalBus.rest_ended.connect(_on_rest_ended)


func _create_player(
	player_name: String,
	bus_name: StringName
) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player

func _get_level_music(track: int) -> AudioStream:
	match track:
		MusicTrack.LEVEL_0:
			return LEVEL_0_BGM

		MusicTrack.LEVEL_1:
			return LEVEL_1_BGM

	return null


func start_level_music(
	track: int,
	play_train_intro: bool,
	fade_duration: float = 2.0
) -> void:
	_pause_menu_music_active = false
	_pause_return_stream = null
	_pause_return_position = 0.0
	_pause_return_was_playing = false
	_sequence_id += 1
	var this_sequence := _sequence_id

	_level_music_track = track
	_music_target_db = _get_level_music_volume(track)
	_notebook_is_open = false

	_stop_all_music_tweens()

	_music_player.stop()
	_notebook_player.stop()
	_notebook_player.volume_db = SILENT_DB

	_train_player.stop()

	if play_train_intro:
		play_train_pulling_in()
		await wait_for_train_sfx()

		if this_sequence != _sequence_id:
			return

	_play_music_stream(
		_get_level_music(track),
		fade_duration
	)


func _play_music_stream(
	stream: AudioStream,
	fade_duration: float
) -> void:
	if stream == null:
		return

	_stop_all_music_tweens()

	_music_player.stop()
	_music_player.stream = stream

	if _notebook_is_open:
		_music_player.volume_db = SILENT_DB
	else:
		_music_player.volume_db = SILENT_DB

	_music_player.play()

	if _notebook_is_open:
		return

	if fade_duration <= 0.0:
		_music_player.volume_db = _music_target_db
		return

	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		_music_target_db,
		fade_duration
	)


func play_tripped_music() -> void:
	_sequence_id += 1
	_play_music_stream(TRIPPED_BGM, 0.0)


func restore_level_music(
	fade_duration: float = 2.0
) -> void:
	_sequence_id += 1
	_play_music_stream(
		_get_level_music(_level_music_track),
		fade_duration
	)


func play_menu_music(
	stream: AudioStream,
	fade_duration: float = 1.0,
	target_volume_db: float = -8.0
) -> void:
	if stream == null:
		return
	
	_pause_menu_music_active = false
	_pause_return_stream = null
	_pause_return_position = 0.0
	_pause_return_was_playing = false

	_sequence_id += 1
	_music_target_db = target_volume_db
	_notebook_is_open = false

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_notebook_player.stop()
	_notebook_player.volume_db = SILENT_DB

	if _music_player.playing and _music_player.stream == stream:
		_stop_all_music_tweens()
		_music_player.volume_db = target_volume_db
		return

	_play_music_stream(stream, fade_duration)


func stop_music() -> void:
	_sequence_id += 1
	_stop_all_music_tweens()

	_music_player.stop()
	_notebook_player.stop()


func fade_out_music(
	duration: float = 2.0
) -> void:
	if not _music_player.playing:
		return

	_stop_all_music_tweens()

	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		SILENT_DB,
		duration
	)

	await _music_tween.finished
	_music_player.stop()


func _stop_all_music_tweens() -> void:
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	if (
		_crossfade_tween != null
		and _crossfade_tween.is_valid()
	):
		_crossfade_tween.kill()



func play_train_pulling_in() -> void:
	if (
		_train_player.playing
		and _train_player.stream == TRAIN_PULLING_IN
	):
		return

	_train_player.stop()
	_train_player.stream = TRAIN_PULLING_IN
	_train_player.play()


func play_train_pulling_out() -> void:
	if (
		_train_player.playing
		and _train_player.stream == TRAIN_PULLING_OUT
	):
		return

	_train_player.stop()
	_train_player.stream = TRAIN_PULLING_OUT
	_train_player.play()

func play_train_pulling_out_no_doors() -> void:
	if (
		_train_player.playing
		and _train_player.stream == TRAIN_PULLING_OUT_NO_DOORS
	):
		return

	_train_player.stop()
	_train_player.stream = TRAIN_PULLING_OUT_NO_DOORS
	_train_player.play()

func stop_train_sfx() -> void:
	_train_player.stop()


func wait_for_train_sfx() -> void:
	while _train_player.playing:
		await get_tree().process_frame


func _on_notebook_opened() -> void:
	if _notebook_is_open:
		return

	_notebook_is_open = true

	if not _notebook_player.playing:
		_notebook_player.stream = NOTEBOOK_BGM
		_notebook_player.volume_db = SILENT_DB
		_notebook_player.play()

	_crossfade_music(
	SILENT_DB,
	NOTEBOOK_MUSIC_DB,
	false,
	NOTEBOOK_FADE_IN_DURATION
	)


func _on_notebook_closed() -> void:
	if not _notebook_is_open:
		return

	_notebook_is_open = false

	var level_music := _get_level_music(_level_music_track)

	if (
		_music_player.stream != level_music
		or not _music_player.playing
	):
		_music_player.stop()
		_music_player.stream = level_music
		_music_player.volume_db = SILENT_DB
		_music_player.play()

	_crossfade_music(
		_music_target_db,
		SILENT_DB,
		true,
		NOTEBOOK_FADE_OUT_DURATION
	)


func _crossfade_music(
	main_target_db: float,
	notebook_target_db: float,
	stop_notebook_after: bool,
	duration: float
) -> void:
	_stop_all_music_tweens()

	_crossfade_tween = create_tween()
	_crossfade_tween.set_parallel(true)
	_crossfade_tween.set_trans(Tween.TRANS_SINE)
	_crossfade_tween.set_ease(Tween.EASE_IN_OUT)

	_crossfade_tween.tween_property(
		_music_player,
		"volume_db",
		main_target_db,
		duration
	)

	_crossfade_tween.tween_property(
		_notebook_player,
		"volume_db",
		notebook_target_db,
		duration
	)

	if stop_notebook_after:
		_crossfade_tween.chain().tween_callback(
			_stop_notebook_after_crossfade
		)


func _stop_notebook_after_crossfade() -> void:
	if _notebook_is_open:
		return

	_notebook_player.stop()
	_notebook_player.volume_db = SILENT_DB

func play_train_pulling_in_no_doors() -> void:
	_train_player.stop()
	_train_player.stream = TRAIN_PULLING_IN_NO_DOORS
	_train_player.play()
	
func play_wrong_ticket_sfx() -> void:
	_train_player.stop()
	_train_player.stream = WRONG_TICKET_SFX
	_train_player.play()


func play_ui_sfx(
	stream: AudioStream,
	volume_db: float = 0.0
) -> void:
	if stream == null:
		return

	_ui_sfx_player.stop()
	_ui_sfx_player.stream = stream
	_ui_sfx_player.volume_db = volume_db
	_ui_sfx_player.play()

func _ensure_audio_bus(
	bus_name: StringName,
	send_to: StringName = &"Master"
) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		AudioServer.set_bus_send(
			AudioServer.get_bus_index(bus_name),
			send_to
		)
		return

	AudioServer.add_bus()

	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send_to)


func _ensure_low_pass(
	bus_name: StringName
) -> AudioEffectLowPassFilter:
	var bus_index := AudioServer.get_bus_index(bus_name)
	for effect_index in AudioServer.get_bus_effect_count(bus_index):
		var effect := AudioServer.get_bus_effect(
			bus_index,
			effect_index
		)
		if effect is AudioEffectLowPassFilter:
			return effect as AudioEffectLowPassFilter

	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = REST_OPEN_CUTOFF_HZ
	AudioServer.add_bus_effect(bus_index, low_pass)
	return low_pass


func _on_rest_started() -> void:
	_set_rest_filter(true)


func _on_rest_ended() -> void:
	_set_rest_filter(false)


func _set_rest_filter(enabled: bool) -> void:
	if _music_low_pass == null or _ambient_low_pass == null:
		return
	if _rest_filter_tween != null and _rest_filter_tween.is_valid():
		_rest_filter_tween.kill()

	var target := REST_CUTOFF_HZ if enabled else REST_OPEN_CUTOFF_HZ
	_rest_filter_tween = create_tween()
	_rest_filter_tween.set_parallel(true)
	_rest_filter_tween.set_trans(Tween.TRANS_SINE)
	_rest_filter_tween.set_ease(Tween.EASE_IN_OUT)
	_rest_filter_tween.tween_method(
		_set_music_rest_cutoff,
		_music_low_pass.cutoff_hz,
		target,
		REST_FILTER_DURATION
	)
	_rest_filter_tween.tween_method(
		_set_ambient_rest_cutoff,
		_ambient_low_pass.cutoff_hz,
		target,
		REST_FILTER_DURATION
	)


func _set_music_rest_cutoff(value: float) -> void:
	_music_low_pass.cutoff_hz = value


func _set_ambient_rest_cutoff(value: float) -> void:
	_ambient_low_pass.cutoff_hz = value

func set_music_volume(value: float) -> void:
	_music_volume_linear = clampf(value, 0.0, 1.0)
	_set_bus_volume(MUSIC_BUS, _music_volume_linear)


func set_sfx_volume(value: float) -> void:
	_sfx_volume_linear = clampf(value, 0.0, 1.0)
	_set_bus_volume(SFX_BUS, _sfx_volume_linear)


func get_music_volume() -> float:
	return _music_volume_linear


func get_sfx_volume() -> float:
	return _sfx_volume_linear


func set_music_muted(muted: bool) -> void:
	var index := AudioServer.get_bus_index(MUSIC_BUS)
	if index >= 0:
		AudioServer.set_bus_mute(index, muted)


func set_sfx_muted(muted: bool) -> void:
	var index := AudioServer.get_bus_index(SFX_BUS)
	if index >= 0:
		AudioServer.set_bus_mute(index, muted)


func _set_bus_volume(
	bus_name: StringName,
	value: float
) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return

	AudioServer.set_bus_mute(index, value <= 0.0)

	if value > 0.0:
		AudioServer.set_bus_volume_db(
			index,
			linear_to_db(value)
		)

func _get_level_music_volume(track: int) -> float:
	match track:
		MusicTrack.LEVEL_0:
			return LEVEL_0_MUSIC_DB

		MusicTrack.LEVEL_1:
			return LEVEL_1_MUSIC_DB

	return DEFAULT_MUSIC_DB

func play_pause_menu_music(
	stream: AudioStream,
	fade_duration: float = 0.5,
	target_volume_db: float = -8.0
) -> void:
	if stream == null or _pause_menu_music_active:
		return

	_pause_return_stream = _music_player.stream
	_pause_return_position = _music_player.get_playback_position()
	_pause_return_target_db = _music_target_db
	_pause_return_was_playing = _music_player.playing
	_pause_menu_music_active = true

	_sequence_id += 1
	_music_target_db = target_volume_db

	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_play_music_stream(stream, fade_duration)

func resume_music_after_pause(
	fade_duration: float = 0.5
) -> void:
	if not _pause_menu_music_active:
		return

	_pause_menu_music_active = false
	_sequence_id += 1
	_stop_all_music_tweens()

	_music_player.stop()
	_music_player.stream = _pause_return_stream
	_music_target_db = _pause_return_target_db

	if not _pause_return_was_playing or _pause_return_stream == null:
		return

	_music_player.volume_db = SILENT_DB
	_music_player.play(_pause_return_position)

	if fade_duration <= 0.0:
		_music_player.volume_db = _music_target_db
		return

	_music_tween = create_tween()
	_music_tween.tween_property(
		_music_player,
		"volume_db",
		_music_target_db,
		fade_duration
	)
