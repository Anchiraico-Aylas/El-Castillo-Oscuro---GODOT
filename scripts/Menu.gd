extends Control

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Levels/Level1.tscn")

func _on_continue_pressed() -> void:
	pass # Replace with function body.

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Hud/Options.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
