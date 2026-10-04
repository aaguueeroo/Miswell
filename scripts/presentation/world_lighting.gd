class_name WorldLighting
extends Node2D

# Times are game minutes. Matching first and last stops keeps midnight seamless.
var _light_stops: Array[Dictionary] = [
	{"minute": 0.0, "ambient": Color("#52617e"), "sky": Color("#a9c9ec"), "sky_energy": 0.10, "lamps": 0.44},
	{"minute": 270.0, "ambient": Color("#52617e"), "sky": Color("#a9c9ec"), "sky_energy": 0.10, "lamps": 0.44},
	{"minute": 330.0, "ambient": Color("#9b91a0"), "sky": Color("#ffd2b0"), "sky_energy": 0.05, "lamps": 0.32},
	{"minute": 390.0, "ambient": Color("#e9bc98"), "sky": Color("#ffdb9e"), "sky_energy": 0.09, "lamps": 0.12},
	{"minute": 480.0, "ambient": Color.WHITE, "sky": Color.WHITE, "sky_energy": 0.0, "lamps": 0.0},
	{"minute": 1050.0, "ambient": Color.WHITE, "sky": Color.WHITE, "sky_energy": 0.0, "lamps": 0.0},
	{"minute": 1110.0, "ambient": Color("#f4c491"), "sky": Color("#ffdb9e"), "sky_energy": 0.09, "lamps": 0.06},
	{"minute": 1170.0, "ambient": Color("#aa8595"), "sky": Color("#f4b995"), "sky_energy": 0.05, "lamps": 0.27},
	{"minute": 1260.0, "ambient": Color("#52617e"), "sky": Color("#a9c9ec"), "sky_energy": 0.10, "lamps": 0.44},
	{"minute": 1440.0, "ambient": Color("#52617e"), "sky": Color("#a9c9ec"), "sky_energy": 0.10, "lamps": 0.44},
]

@onready var _ambient: CanvasModulate = $Ambient
@onready var _sky_light: DirectionalLight2D = $SkyLight
@onready var _warm_lights: Node2D = $WarmLights

func apply_time_of_day(game_minute: float) -> void:
	var minute: float = fposmod(game_minute, 1440.0)
	for index in range(_light_stops.size() - 1):
		var from_stop: Dictionary = _light_stops[index]
		var to_stop: Dictionary = _light_stops[index + 1]
		var start: float = float(from_stop["minute"])
		var finish: float = float(to_stop["minute"])
		if minute > finish:
			continue
		var amount: float = clampf((minute - start) / (finish - start), 0.0, 1.0)
		amount = amount * amount * (3.0 - 2.0 * amount)
		var from_ambient: Color = from_stop["ambient"]
		var to_ambient: Color = to_stop["ambient"]
		var from_sky: Color = from_stop["sky"]
		var to_sky: Color = to_stop["sky"]
		_ambient.color = from_ambient.lerp(to_ambient, amount)
		_sky_light.color = from_sky.lerp(to_sky, amount)
		_sky_light.energy = lerpf(float(from_stop["sky_energy"]), float(to_stop["sky_energy"]), amount)
		_sky_light.enabled = _sky_light.energy > 0.001
		var lamp_energy: float = lerpf(float(from_stop["lamps"]), float(to_stop["lamps"]), amount)
		for lamp in _warm_lights.get_children():
			var point_light := lamp as PointLight2D
			if point_light != null:
				point_light.energy = lamp_energy
				point_light.enabled = lamp_energy > 0.001
		return
