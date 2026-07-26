extends Node


enum MusicTrack {
	LEVEL_0,
	LEVEL_1,
}


const LEVEL_0_BGM: AudioStream = preload(
	"res://bgm/TRAINing with friends.mp3"
)

const LEVEL_1_BGM: AudioStream = preload(
	"res://levels/You TRAINed for this copy.mp3"
)

const TRIPPED_BGM: AudioStream = preload(
	"res://bgm/Tripped and Lost v2.mp3"
)

const NOTEBOOK_BGM: AudioStream = preload(
	"res://notebook/Keeping TRACK of my Notes demo.mp3"
)

const TRAIN_PULLING_IN: AudioStream = preload(
	"res://ui/Train/Train Pulling Into.mp3"
)

const LEVEL_0_FIRST_TRAIN_IN: AudioStream = preload(
	"res://level_elements/train/Pulling out without door opening.mp3"
)

const TRAIN_PULLING_OUT: AudioStream = preload(
	"res://ui/Train/Pulling out.mp3"
)

const WRONG_TICKET_SFX: AudioStream = preload(
	"res://ui/Wrong Ticket.mp3"
)


const SILENT_DB: float = -40.0
const DEFAULT_MUSIC_DB: float = -4.0
const NOTEBOOK_MUSIC_DB: float = -4.0
const NOTEBOOK_CROSSFADE_DURATION: float = 2.0


var _music_player: AudioStreamPlayer
var _notebook_player: AudioStreamPlayer
var _train_player: AudioStreamPlayer

var _music_tween: Tween
var _crossfade_tween: Tween

var _level_music_track: int = MusicTrack.LEVEL_0
var _music_target_db: float = DEFAULT_MUSIC_DB
var _notebook_is_open: bool = false

var _sequence_id: int = 0


func _ready() -> void:
	_music_player = _create_player("MainMusicPlayer")
	_notebook_player = _create_player("NotebookMusicPlayer")
	_train_player = _create_player("TrainSFXPlayer")

	_notebook_player.stream = NOTEBOOK_BGM
	_notebook_player.volume_db = SILENT_DB

	SignalBus.notebook_opened.connect(
		_on_notebook_opened
	)
	SignalBus.notebook_closed.connect(
		_on_notebook_closed
	)


func _create_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Master"
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
	_sequence_id += 1
	var this_sequence := _sequence_id

	_level_music_track = track
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
		false
	)


func _on_notebook_closed() -> void:
	if not _notebook_is_open:
		return

	_notebook_is_open = false

	_crossfade_music(
		_music_target_db,
		SILENT_DB,
		true
	)


func _crossfade_music(
	main_target_db: float,
	notebook_target_db: float,
	stop_notebook_after: bool
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
		NOTEBOOK_CROSSFADE_DURATION
	)

	_crossfade_tween.tween_property(
		_notebook_player,
		"volume_db",
		notebook_target_db,
		NOTEBOOK_CROSSFADE_DURATION
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

func play_level_0_first_train_in() -> void:
	_train_player.stop()
	_train_player.stream = LEVEL_0_FIRST_TRAIN_IN
	_train_player.play()
	
func play_wrong_ticket_sfx() -> void:
	_train_player.stop()
	_train_player.stream = WRONG_TICKET_SFX
	_train_player.play()
