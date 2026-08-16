class_name DepartureData 
extends Resource

@export var color_line: Enums.TrainColor
@export var direction: Enums.TrainDirection
##Resshan time given as seconds before 0:0:0
@export var departure_time_seconds: int
@export var destination: String
##For display purposes only. Under the hood the handler is picking level trains, not platforms
@export var platform: int
@export var arrival_time_seconds: int
