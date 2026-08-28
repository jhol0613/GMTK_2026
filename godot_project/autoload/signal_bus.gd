extends Node

@warning_ignore_start("unused_signal")
signal minutes_passed(minutes: int)
signal resshan_clicked(encoded_resshan: String)
signal show_resshan_entry(encoded_resshan: String)
signal new_unique_resshan_note_added_to_notebook

signal notebook_opened
signal notebook_closed
signal rest_started
signal rest_ended

signal no_ticket
#signal missed_train

signal ticket_purchased(hour: int, minute: int, second:int)

signal inventory_full

signal ticket_consumed
signal ticket_received
signal item_popup_requested(icon: Texture2D)
signal animated_item_popup_requested(sprite_sheet: Texture2D, frame_count: int, fps: float)
signal item_popup_finished

@warning_ignore_restore("unused_signal")
