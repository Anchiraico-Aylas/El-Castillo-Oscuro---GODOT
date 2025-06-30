extends Node2D

@onready var light = $PointLight2D
@onready var area = $Area2D

var player_in_range = false
var player_ref = null
var is_on = false

func _ready():
	light.visible = false  # Off at the start

func _process(_delta):
	if player_in_range and player_ref and player_ref.has_lighter:
		if Input.is_action_just_pressed("interact") and not is_on:
			turn_on_light()

func turn_on_light():
	light.visible = true
	is_on = true
	print("Lamp turned on")

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true
		player_ref = body

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		player_ref = null
