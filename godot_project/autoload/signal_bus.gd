extends Node

@warning_ignore_start("unused_signal")
signal minutes_passed(minutes: int)
signal train_departed
signal resshan_clicked(encoded_resshan: String)
signal resshan_note_requested(by_label: ResshanInteractable)
@warning_ignore_restore("unused_signal")
