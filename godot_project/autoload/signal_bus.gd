extends Node

@warning_ignore_start("unused_signal")
signal minutes_passed(minutes: int)
signal resshan_clicked(encoded_resshan: String)
signal resshan_note_requested(by_label: ResshanInteractable)
signal new_unique_resshan_note_added_to_notebook

signal notebook_opened
signal notebook_closed

signal no_ticket
signal missed_train

signal ticket_purchased(hour: int, minute: int)

signal ticket_consumed
signal ticket_received

@warning_ignore_restore("unused_signal")
