extends Node2D

@onready var tile_map: TileMapLayer = $"../TileMapLayer"
@onready var score_label: RichTextLabel = $RichTextLabel
@onready var win_label: CanvasLayer = $"../CanvasLayer3"
@onready var vignette: CanvasLayer = $"../CanvasLayer"

@export var move_time := 0.15
@export var win_amount := 8

var is_moving := false
var target_position: Vector2
var score := 0
var ink_atlas := Vector2i(0,1)

func _ready() -> void:
	var cell = tile_map.local_to_map(position)
	position = tile_map.map_to_local(cell)
	target_position = position
	
	vignette.visible = false
	win_label.visible = false
	
	_update_score_label()
	_check_vignette_condition(cell)
	
func _process(delta:float) -> void:
	if is_moving:
		# lerp for smooth movement
		position = position.lerp(target_position,delta/move_time)
		
		# snap when close enough
		if position.distance_to(target_position) < 0.25:
			position = target_position
			is_moving = false
			
			var cell = tile_map.local_to_map(position)
			var atlas_coords = tile_map.get_cell_atlas_coords(cell)
			
			if atlas_coords == Vector2i(1,6) or atlas_coords == Vector2i(0,6):
				score += 1
				_update_score_label()
			
			_replace_tile(cell)
			_check_vignette_condition(cell)
			_update_score_label()
		return
	
	var input_dir: Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): input_dir = Vector2i(-1,0)
	elif Input.is_action_just_pressed("ui_down"): input_dir = Vector2i(1,0)
	elif Input.is_action_just_pressed("ui_left"): input_dir = Vector2i(0,1)
	elif Input.is_action_just_pressed("ui_right"): input_dir = Vector2i(0,-1)
	
	if input_dir != Vector2i.ZERO:
		var current_cell = tile_map.local_to_map(position)
		var next_cell = current_cell + input_dir
		target_position = tile_map.map_to_local(next_cell)
		is_moving = true

func _update_score_label() -> void:
	score_label.text = "Score: " + str(score)
	win_label.visible = score >= win_amount
	
func _replace_tile(cell: Vector2i) -> void:
	var source_id = tile_map.get_cell_source_id(cell)
	tile_map.set_cell(cell, source_id, ink_atlas)
	
func _check_vignette_condition(cell: Vector2i) -> void:
	var required := ink_atlas
	
	# offsets of neighboring cells compared to current cell
	var offsets: Array[Vector2i] = [
		Vector2i(0,0), # current tile
		Vector2i(1,0), Vector2i(-1,0), # left/right
		Vector2i(0,1), Vector2i(0,-1), # up/down
		Vector2i(1,1), Vector2i(1,-1), # diagonals
		Vector2i(-1,1), Vector2i(-1,-1)
	]
	
	for off in offsets:
		var c: Vector2i = cell + off
		var atlas: Vector2i = tile_map.get_cell_atlas_coords(c)
		
		# if any tile around isn't ink, disable vignette
		if atlas != required:
			vignette.visible = false
			return
	
	vignette.visible = true
