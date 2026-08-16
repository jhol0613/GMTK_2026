extends Node

@warning_ignore_start("unused_signal")
signal minutes_passed(minutes: int)
signal resshan_clicked(encoded_resshan: String)
signal new_unique_resshan_note_added_to_notebook

signal notebook_opened
signal notebook_closed
signal rest_started
signal rest_ended

signal no_ticket
signal missed_train

signal ticket_purchased(hour: int, minute: int, second:int)

signal ticket_consumed
signal ticket_received

@warning_ignore_restore("unused_signal")
