extends Node

@warning_ignore_start("unused_signal")
signal minutes_passed(minutes: int)
signal resshan_clicked(encoded_resshan: String)
signal resshan_note_requested(by_label: ResshanInteractable)

signal notebook_opened
signal notebook_closed

@warning_ignore_restore("unused_signal")
