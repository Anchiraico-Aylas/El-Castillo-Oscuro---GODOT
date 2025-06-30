extends Area2D

@onready var animationPlayer = $AnimationPlayer
@export var award_amount : int = 1

func _ready():
	animationPlayer.play("Idle")
	animationPlayer.connect("animation_finished", _on_animation_finished)

func _on_body_entered(body: Node2D) -> void:
	call_deferred("add_coin", body)
	CollectibleManager.give_pickup_award(award_amount)

func add_coin(body):
	$CollisionShape2D.disabled = true
	animationPlayer.play("Hit")
	body.add_coins(1)

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Hit":
		queue_free()  # elimina la moneda una vez terminada la animación
