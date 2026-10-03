class_name VillageMapRoot
extends Node2D

@onready var _ground: TileMapLayer = $Ground
@onready var _farmyard: TileMapLayer = $Farmyard
@onready var _town_courtyards: TileMapLayer = $TownCourtyards
@onready var _city_plazas: TileMapLayer = $CityPlazas
@onready var _sidewalks: TileMapLayer = $Sidewalks
@onready var _roads: TileMapLayer = $Roads

func get_footstep_surface(world_position: Vector2) -> StringName:
	if _has_tile_at(_roads, world_position) or _has_tile_at(_sidewalks, world_position) or _has_tile_at(_city_plazas, world_position):
		return &"concrete"
	if _has_tile_at(_farmyard, world_position):
		return &"default"
	if _has_tile_at(_town_courtyards, world_position) or _has_tile_at(_ground, world_position):
		return &"grass"
	return &"default"

func _has_tile_at(layer: TileMapLayer, world_position: Vector2) -> bool:
	var cell := layer.local_to_map(layer.to_local(world_position))
	return layer.get_cell_source_id(cell) >= 0
