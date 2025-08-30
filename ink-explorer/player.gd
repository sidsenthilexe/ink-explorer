extends Node2D
@onready var tileMap: TileMapLayer=$"../TileMapLayer"
@onready var scoreLabel: RichTextLabel=$RichTextLabel
@onready var vignette: CanvasLayer=$"../CanvasLayer"
@onready var winLayer: CanvasLayer=$"../CanvasLayer3"

@export var move_time:=0.15
var is_moving:=false
var target_position: Vector2
var score:=0

var ink_atlas := Vector2i(0,1)

func _ready() -> void:
	var cell = tileMap.local_to_map(position)
	position = tileMap.map_to_local(cell)
	target_position = position
	vignette.visible = false
	winLayer.visible = false
	_update_score_label()
	_check_vignette_condition(cell)
	
func _process(delta: float) -> void:
	if is_moving:
		position = position.lerp(target_position, delta/move_time) #smooth movement to target
		if position.distance_to(target_position) < 0.25:#snap when close enough
			position = target_position
			is_moving = false
			var cell = tileMap.local_to_map(position)
			var atlas_coords = tileMap.get_cell_atlas_coords(cell)
			
			if atlas_coords == Vector2i(1,6) or atlas_coords == Vector2i(0,6):
				score += 1
				_update_score_label()
			
			_replace_tile(cell)
			_check_vignette_condition(cell)
		return
		
	var input_dir: Vector2i = Vector2i.ZERO
	if Input.is_action_just_pressed("ui_up"): input_dir = Vector2i(-1,0)
	elif Input.is_action_just_pressed("ui_down"): input_dir = Vector2i(1,0)
	elif Input.is_action_just_pressed("ui_left"): input_dir = Vector2i(0,1)
	elif Input.is_action_just_pressed("ui_right"): input_dir = Vector2i(0,-1)
	
	if input_dir != Vector2i.ZERO:
		var current_cell = tileMap.local_to_map(position)
		var next_cell = current_cell + input_dir
		target_position = tileMap.map_to_local(next_cell)
		is_moving = true
		
func _update_score_label() -> void:
	scoreLabel.text = "Score: " + str(score)
	if score >= 8: winLayer.visible = true
	
func _replace_tile(cell: Vector2i) -> void:
	var source_id = tileMap.get_cell_source_id(cell)
	tileMap.set_cell(cell, source_id, ink_atlas)
	
func _check_vignette_condition(cell: Vector2i) -> void:
	var required: Vector2i = ink_atlas
	var offsets: Array[Vector2i] = [
		Vector2i(0,0), # Current tile
		Vector2i(1,0),Vector2i(-1,0), # tiles to left and right
		Vector2i(0,1),Vector2i(0,-1), #Up and down
		Vector2i(1,1), Vector2i(1,-1),
		Vector2i(-1,1), Vector2i(-1,-1) #diagonal
	]
	
	for off in offsets:
		var c: Vector2i = cell+off
		var atlas: Vector2i = tileMap.get_cell_atlas_coords(c)
		#if any tile is not ink no vignette
		if atlas != required:
			vignette.visible = false
			return
	vignette.visible = true
