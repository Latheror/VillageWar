extends Node

class_name TimeManager

signal day_advanced

var current_day: int = 1
var game_date: String = "January 1, 2026"
var paused: bool = false
var day_timer: Timer

func _ready() -> void:
	day_timer = Timer.new()
	day_timer.wait_time = 5.0
	day_timer.one_shot = false
	day_timer.connect("timeout", Callable(self, "_on_day_timer_timeout"))
	add_child(day_timer)
	day_timer.start()

func _on_day_timer_timeout() -> void:
	if not paused:
		advance_day()
		emit_signal("day_advanced")

func advance_day() -> void:
	current_day += 1
	# Simple date advancement (for demo)
	var date_parts = game_date.split(" ")
	if date_parts.size() >= 3:
		var month = date_parts[0]
		var day = int(date_parts[1].trim_suffix(","))
		var year = int(date_parts[2])
		
		day += 1
		# Very basic calendar (no leap years, etc.)
		var days_in_month = {
			"January": 31, "February": 28, "March": 31, "April": 30,
			"May": 31, "June": 30, "July": 31, "August": 31,
			"September": 30, "October": 31, "November": 30, "December": 31
		}
		
		if day > days_in_month[month]:
			day = 1
			var months = ["January", "February", "March", "April", "May", "June", 
						 "July", "August", "September", "October", "November", "December"]
			var month_index = months.find(month)
			if month_index < 11:
				month = months[month_index + 1]
			else:
				month = "January"
				year += 1
		
		game_date = "%s %d, %d" % [month, day, year]

func toggle_pause() -> void:
	paused = not paused

func get_date() -> String:
	return game_date

func get_day() -> int:
	return current_day

func is_paused() -> bool:
	return paused