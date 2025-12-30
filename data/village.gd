class_name Village

var id: int
var name: String
var position: Vector2  # tile coordinates
var people: int = 10
var food: int = 50
var wood: int = 30

func _init(village_id: int, pos: Vector2, village_name: String = ""):
	id = village_id
	position = pos
	if village_name == "":
		name = "Village %d" % id
	else:
		name = village_name

func get_info_text() -> String:
	return "%s\nPeople: %d\nFood: %d\nWood: %d" % [name, people, food, wood]