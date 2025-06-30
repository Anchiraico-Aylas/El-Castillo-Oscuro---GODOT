extends CharacterBody2D
class_name PigActor

# ==== Exportables / Configuración desde el editor ====
@export var flip_on_start: bool = false
@export var disable_move: bool = false
@export var run_right: bool = false
@export var body_free: bool = false
@export var disable_collision: bool = false
@export var coin_scene: PackedScene
@export var basic_speed: int = -169
@export var health: int = 3
@export var damage_amount: int = 1

# ==== Estados ====
enum { STOP, MOVING, DEAD }
var state: int = MOVING
var is_hit: bool = false

# ==== Movimiento ====
var gravity: float = 1000

# ==== Inicialización ====
func _ready() -> void:
	velocity = Vector2(basic_speed, 0)
	if run_right:
		velocity.x *= -1
	if disable_move:
		state = STOP
	if disable_collision:
		_disable_detectors()

# ==== Ciclo físico ====
func _physics_process(delta: float) -> void:
	if state == STOP:
		return

	if state != DEAD:
		velocity.y += gravity * delta
		if is_on_wall():
			velocity.x *= -1
	else:
		velocity.x = 0

	move_and_slide()

	if state == MOVING:
		set_animation()
		set_flip()

# ==== Colisiones ====
func _on_StompDetector_body_entered(body: Node2D) -> void:
	if body.global_position.y < global_position.y and body.has_method("calculate_stomp_velocity"):
		body.calculate_stomp_velocity(300)
		call_die()

func _on_PlayerDetector_body_entered(body: Node2D) -> void:
	$AnimationPlayer.play("Attack")
	flip(body.global_position.x > global_position.x)
	state = STOP

	if body.has_method("take_damage"):
		body.take_damage()

# ==== Animaciones ====
func set_animation() -> void:
	if is_hit:
		return

	var anim_name := "Idle"
	if not is_on_floor():
		anim_name = "Jump"
	elif velocity.x != 0:
		anim_name = "Run"

	anim_play(anim_name)

func anim_play(new_animation: String) -> void:
	if $AnimationPlayer.current_animation == "Attack":
		return
	if $AnimationPlayer.current_animation != new_animation:
		$AnimationPlayer.play(new_animation)

# ==== Flip / Dirección ====
func set_flip() -> void:
	if velocity.x != 0:
		flip(velocity.x > 0)

func flip(is_flipped: bool) -> void:
	$Sprite2D.flip_h = is_flipped
	var pos_x = -1 if is_flipped else 5
	$CollisionShape2D.position.x = pos_x
	$StompDetector/CollisionShape2D.position.x = pos_x
	$PlayerDetector/CollisionShape2D.position.x = pos_x

# ==== Daño / Muerte ====
func take_hit() -> void:
	if is_hit or state == DEAD:
		return

	health -= 1
	is_hit = true
	$AnimationPlayer.play("Hit")

	if health <= 0:
		call_die()
	else:
		await $AnimationPlayer.animation_finished
		is_hit = false

func call_die() -> void:
	if state != DEAD:
		call_deferred("die")

func die() -> void:
	if coin_scene:
		var coin_instance = coin_scene.instantiate()
		coin_instance.global_position = global_position + Vector2(0, -10)
		get_parent().add_child(coin_instance)

	_disable_detectors()
	collision_layer = 0
	state = DEAD
	$AnimationPlayer.play("Dead")
	await $AnimationPlayer.animation_finished
	queue_free()

func _disable_detectors():
	$StompDetector/CollisionShape2D.disabled = true
	$StompDetector.monitoring = false
	$StompDetector.monitorable = false
	$PlayerDetector/CollisionShape2D.disabled = true
	$PlayerDetector.monitoring = false
	$PlayerDetector.monitorable = false
