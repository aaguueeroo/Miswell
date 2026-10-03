extends Node2D

const ROAD_DARK := Color("#d5c5a5")
const ROAD_LIGHT := Color("#e0d2b6")

func _draw() -> void:
	var map_size := VillageMapConfig.WORLD_SIZE
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#b9cea5"))
	_draw_neighborhood()
	_draw_roads()
	_draw_football_pitch()
	_draw_park()
	_draw_picnic_area()
	_draw_street_details()

func _draw_neighborhood() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(95.0, 135.0), Vector2(425.0, 115.0), Vector2(480.0, 208.0),
		Vector2(470.0, 650.0), Vector2(120.0, 730.0), Vector2(68.0, 440.0)
	]), Color("#b3c69e"))
	_draw_area_label(Vector2(110.0, 195.0), "CEDAR NEIGHBORHOOD")
	_draw_area_label(Vector2(105.0, 242.0), "A quiet street of small homes")

func _draw_roads() -> void:
	# Main Street links the school, shops and recreation area across the whole town.
	_draw_road(Rect2(480.0, 0.0, 120.0, VillageMapConfig.WORLD_SIZE.y))
	for road_y in [430.0, 940.0, 1200.0, 1580.0]:
		_draw_road(Rect2(0.0, road_y, VillageMapConfig.WORLD_SIZE.x, 92.0))
	_draw_crosswalk(Vector2(480.0, 455.0), true)
	_draw_crosswalk(Vector2(600.0, 455.0), true)
	_draw_crosswalk(Vector2(480.0, 965.0), true)
	_draw_crosswalk(Vector2(600.0, 965.0), true)
	_draw_crosswalk(Vector2(480.0, 1225.0), true)
	_draw_crosswalk(Vector2(600.0, 1225.0), true)
	_draw_crosswalk(Vector2(480.0, 1605.0), true)
	_draw_crosswalk(Vector2(600.0, 1605.0), true)
	_draw_path(Rect2(585.0, 438.0, 218.0, 17.0))
	_draw_path(Rect2(320.0, 928.0, 170.0, 17.0))
	_draw_path(Rect2(590.0, 1294.0, 145.0, 17.0))
	_draw_path(Rect2(320.0, 1570.0, 168.0, 17.0))
	_draw_area_label(Vector2(612.0, 650.0), "MAIN STREET")

func _draw_road(rect: Rect2) -> void:
	draw_rect(rect, ROAD_DARK)
	var inset := Rect2(rect.position + Vector2(11.0, 11.0), rect.size - Vector2(22.0, 22.0))
	draw_rect(inset, ROAD_LIGHT)
	if rect.size.x > rect.size.y:
		var y := rect.position.y + rect.size.y * 0.5
		for x in range(int(rect.position.x + 28.0), int(rect.end.x - 20.0), 52):
			draw_rect(Rect2(float(x), y - 2.0, 24.0, 4.0), Color("#c3b595"))
	else:
		var x := rect.position.x + rect.size.x * 0.5
		for y in range(int(rect.position.y + 25.0), int(rect.end.y - 20.0), 52):
			draw_rect(Rect2(x - 2.0, float(y), 4.0, 24.0), Color("#c3b595"))

func _draw_crosswalk(origin: Vector2, vertical_road: bool) -> void:
	for stripe in range(5):
		if vertical_road:
			draw_rect(Rect2(origin.x + stripe * 22.0 + 4.0, origin.y, 11.0, 64.0), Color("#f1e8d3"))
		else:
			draw_rect(Rect2(origin.x, origin.y + stripe * 12.0 + 4.0, 82.0, 7.0), Color("#f1e8d3"))

func _draw_path(rect: Rect2) -> void:
	draw_rect(rect, Color("#ccb996"))
	draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("#e2d3b7"), 2.0)
	draw_line(Vector2(rect.position.x, rect.end.y), rect.end, Color("#b5a17f"), 2.0)

func _draw_football_pitch() -> void:
	var pitch := Rect2(250.0, 665.0, 215.0, 225.0)
	draw_rect(pitch, Color("#789a72"))
	draw_rect(pitch, Color("#e1e0c1"), false, 3.0)
	draw_line(Vector2(pitch.position.x, pitch.position.y + pitch.size.y * 0.5), Vector2(pitch.end.x, pitch.position.y + pitch.size.y * 0.5), Color("#e1e0c1"), 2.0)
	draw_arc(pitch.position + pitch.size * 0.5, 29.0, 0.0, TAU, 28, Color("#e1e0c1"), 2.0)
	draw_rect(Rect2(pitch.position.x, pitch.position.y + 62.0, 43.0, 101.0), Color("#e1e0c1"), false, 2.0)
	draw_rect(Rect2(pitch.end.x - 43.0, pitch.position.y + 62.0, 43.0, 101.0), Color("#e1e0c1"), false, 2.0)
	draw_rect(Rect2(pitch.position.x - 12.0, pitch.position.y + 93.0, 12.0, 39.0), Color("#eee8d7"), false, 2.0)
	draw_rect(Rect2(pitch.end.x, pitch.position.y + 93.0, 12.0, 39.0), Color("#eee8d7"), false, 2.0)
	_draw_area_label(Vector2(252.0, 650.0), "SCHOOL FOOTBALL FIELD")

func _draw_park() -> void:
	var park_points := PackedVector2Array([
		Vector2(642.0, 875.0), Vector2(970.0, 870.0), Vector2(1010.0, 1040.0),
		Vector2(978.0, 1205.0), Vector2(645.0, 1190.0), Vector2(615.0, 1010.0)
	])
	draw_colored_polygon(park_points, Color("#a9c493"))
	draw_polyline(PackedVector2Array([
		Vector2(670.0, 1090.0), Vector2(742.0, 1035.0), Vector2(828.0, 1055.0),
		Vector2(910.0, 970.0)
	]), Color("#d5c29e"), 20.0)
	draw_polyline(PackedVector2Array([
		Vector2(670.0, 1090.0), Vector2(742.0, 1035.0), Vector2(828.0, 1055.0),
		Vector2(910.0, 970.0)
	]), Color("#e5d8ba"), 2.0)
	for point in [
		Vector2(688.0, 920.0), Vector2(920.0, 920.0), Vector2(948.0, 1112.0),
		Vector2(690.0, 1152.0), Vector2(825.0, 1150.0)
	]:
		_draw_tree(point, 18.0)
	_draw_bench(Vector2(790.0, 1107.0))
	_draw_bench(Vector2(897.0, 1010.0))
	_draw_area_label(Vector2(675.0, 896.0), "MILLER PARK")

func _draw_picnic_area() -> void:
	var lawn := PackedVector2Array([
		Vector2(580.0, 638.0), Vector2(724.0, 602.0), Vector2(835.0, 664.0),
		Vector2(824.0, 785.0), Vector2(686.0, 797.0), Vector2(590.0, 741.0)
	])
	draw_colored_polygon(lawn, Color("#a9c393", 0.82))
	_draw_tree(Vector2(606.0, 675.0), 18.0)
	_draw_tree(Vector2(814.0, 731.0), 16.0)
	draw_rect(Rect2(673.0, 705.0, 74.0, 10.0), Color("#936d4e"))
	draw_rect(Rect2(680.0, 714.0, 7.0, 21.0), Color("#76583f"))
	draw_rect(Rect2(733.0, 714.0, 7.0, 21.0), Color("#76583f"))
	draw_rect(Rect2(668.0, 693.0, 84.0, 6.0), Color("#ac8760"))
	draw_string(ThemeDB.fallback_font, Vector2(645.0, 786.0), "FAMILY PICNIC", HORIZONTAL_ALIGNMENT_CENTER, 130.0, 10, Color("#64785e"))

func _draw_street_details() -> void:
	for point in [
		Vector2(105.0, 388.0), Vector2(930.0, 390.0), Vector2(110.0, 850.0),
		Vector2(550.0, 820.0), Vector2(550.0, 1155.0), Vector2(985.0, 1150.0),
		Vector2(112.0, 1488.0), Vector2(930.0, 1515.0), Vector2(935.0, 1775.0)
	]:
		_draw_tree(point, 21.0)
	for point in [
		Vector2(420.0, 590.0), Vector2(660.0, 790.0), Vector2(960.0, 840.0),
		Vector2(715.0, 1220.0), Vector2(390.0, 1460.0), Vector2(705.0, 1720.0)
	]:
		draw_circle(point, 5.0, Color("#e6bc70"))
		draw_circle(point + Vector2(5.0, 3.0), 2.5, Color("#b87369"))
	_draw_market_square()
	_draw_rec_court()
	_draw_area_label(Vector2(100.0, 1430.0), "REC CENTER")

func _draw_market_square() -> void:
	var plaza := Rect2(624.0, 1320.0, 230.0, 112.0)
	draw_rect(plaza, Color("#d5c5a5"))
	draw_rect(Rect2(plaza.position + Vector2(8.0, 8.0), plaza.size - Vector2(16.0, 16.0)), Color("#e3d5b8"), false, 2.0)
	_draw_bench(Vector2(674.0, 1391.0))
	for point in [Vector2(637.0, 1340.0), Vector2(830.0, 1413.0)]:
		draw_circle(point, 9.0, Color("#78966c"))
		draw_circle(point + Vector2(-3.0, -3.0), 5.0, Color("#a4b98c"))
	_draw_area_label(Vector2(626.0, 1450.0), "MARKET SQUARE")

func _draw_rec_court() -> void:
	var court := Rect2(616.0, 1640.0, 286.0, 162.0)
	draw_rect(court, Color("#a8bd9e"))
	draw_rect(court, Color("#e4e1ca"), false, 3.0)
	draw_line(Vector2(court.position.x, court.position.y + court.size.y * 0.5), Vector2(court.end.x, court.position.y + court.size.y * 0.5), Color("#e4e1ca"), 2.0)
	draw_arc(court.position + court.size * 0.5, 27.0, 0.0, TAU, 24, Color("#e4e1ca"), 2.0)
	draw_rect(Rect2(court.position.x, court.position.y + 47.0, 43.0, 68.0), Color("#e4e1ca"), false, 2.0)
	draw_rect(Rect2(court.end.x - 43.0, court.position.y + 47.0, 43.0, 68.0), Color("#e4e1ca"), false, 2.0)
	_draw_area_label(Vector2(622.0, 1630.0), "REC COURT")

func _draw_bench(point: Vector2) -> void:
	draw_rect(Rect2(point.x - 22.0, point.y, 44.0, 6.0), Color("#936d4e"))
	draw_rect(Rect2(point.x - 20.0, point.y - 9.0, 40.0, 7.0), Color("#b68b5d"))
	draw_line(point + Vector2(-14.0, 5.0), point + Vector2(-14.0, 16.0), Color("#6e5948"), 3.0)
	draw_line(point + Vector2(14.0, 5.0), point + Vector2(14.0, 16.0), Color("#6e5948"), 3.0)

func _draw_tree(point: Vector2, radius: float) -> void:
	draw_rect(Rect2(point.x - 4.0, point.y + 8.0, 8.0, 22.0), Color("#896d52"))
	draw_circle(point, radius, Color("#76936c"))
	draw_circle(point + Vector2(-radius * 0.28, -radius * 0.25), radius * 0.58, Color("#8ca982"))
	draw_circle(point + Vector2(radius * 0.35, radius * 0.16), radius * 0.48, Color("#668660"))

func _draw_area_label(position: Vector2, text: String) -> void:
	draw_string(ThemeDB.fallback_font, position, text, HORIZONTAL_ALIGNMENT_LEFT, 380.0, 12, Color("#60745c"))
