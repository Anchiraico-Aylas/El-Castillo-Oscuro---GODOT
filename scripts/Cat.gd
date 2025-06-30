extends CharacterBody2D

# ==== Constantes ====
const SPEED = 150.0
const JUMP_VELOCITY = -250.0
const WALL_JUMP_COYOTE_TIME = 0.1
const WALL_JUMP_LOCK_TIME = 0.06

# ==== Variables de animación y estado general ====
@export var salud = 3
var coins = 0
var inmune = false
var is_dead = false
var is_attacking = false
var has_lighter = true
var is_hit = false

# ==== Variables de movimiento en pared ====
var wall_contact = false
var wall_dir = 0
var wall_jump_timer = 0.0
var wall_jump_lock_timer = 0.0

# ==== Referencias de nodos ====
@onready var animationPlayer = $AnimationPlayer
@onready var sprite2D = $Sprite2D
@onready var sword_area = $SwordArea
@onready var sword_collision = $SwordArea/CollisionShape2D
@onready var heart1 = $GUI/HBoxContainer/Heart1
@onready var heart2 = $GUI/HBoxContainer/Heart2
@onready var heart3 = $GUI/HBoxContainer/Heart3

# ==== Inicialización ====
func _ready():
	add_to_group("player")

	# Reiniciar estado del jugador
	salud = 3
	coins = 0
	inmune = false
	is_dead = false
	is_attacking = false
	has_lighter = true
	is_hit = false

	# Reiniciar salud global y actualizar corazones
	HealthManager.reset_health()

# ==== Ciclos de juego ====
func _process(_delta):
	pass

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_movement(delta)
	move_and_slide()

# ==== Movimiento del personaje ====
func _movement(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if wall_contact and velocity.y > 0:
		velocity.y = min(velocity.y, 20)

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif wall_contact or wall_jump_timer > 0.0:
			velocity.y = JUMP_VELOCITY * 1.1
			velocity.x = -wall_dir * SPEED * 1.2
			wall_jump_lock_timer = WALL_JUMP_LOCK_TIME
			wall_jump_timer = 0.0

	var direction := Input.get_axis("ui_left", "ui_right")
	if wall_jump_lock_timer <= 0.0:
		velocity.x = direction * SPEED if direction != 0 else move_toward(velocity.x, 0, SPEED)
	else:
		wall_jump_lock_timer -= delta

	_detect_wall()
	_handle_sprite_flip(direction)
	animations(direction)

# ==== Detección de colisiones con pared ====
func _detect_wall():
	wall_contact = false
	wall_dir = 0
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if collision and not is_on_floor():
			var normal = collision.get_normal()
			if abs(normal.x) > 0.9:
				var dir_left = Input.is_action_pressed("ui_left")
				var dir_right = Input.is_action_pressed("ui_right")
				if (normal.x > 0 and dir_left) or (normal.x < 0 and dir_right):
					wall_contact = true
					wall_dir = normal.x
					break

	if wall_contact:
		wall_jump_timer = WALL_JUMP_COYOTE_TIME
	elif wall_jump_timer > 0.0:
		wall_jump_timer -= get_process_delta_time()

# ==== Animaciones ====
func animations(direction):
	if is_attacking or is_hit:
		return  # No reproducir animaciones si está golpeado

	if wall_contact and not is_on_floor() and velocity.y > 0:
		animationPlayer.play("Wall_Slide")
	elif is_on_floor():
		animationPlayer.play("Run" if direction != 0 else "Idle")
	else:
		animationPlayer.play("Jump" if velocity.y < 0 else "Fall")

func _handle_sprite_flip(direction):
	if wall_contact and not is_on_floor():
		sprite2D.flip_h = wall_dir < 0
	elif direction != 0:
		sprite2D.flip_h = direction < 0

# ==== Entrada del jugador ====
func _input(event: InputEvent):
	if is_dead:
		return
	if event.is_action_pressed("ui_down") and is_on_floor():
		position.y += 1
	elif event.is_action_pressed("attack"):
		attack()

# ==== Combate ====
func attack():
	if is_attacking or is_dead:
		return
	is_attacking = true
	animationPlayer.play("Attack1")
	sword_collision.disabled = false
	await animationPlayer.animation_finished
	sword_collision.disabled = true
	is_attacking = false

func _on_sword_area_body_entered(body: Node2D) -> void:
	if is_attacking and body != self and body.has_method("take_hit"):
		body.take_hit()

# ==== Sistema de daño ====
func take_damage():
	if inmune or is_dead or is_hit:
		return

	salud -= 1
	inmune = true
	is_hit = true

	animationPlayer.play("Hit")
	await animationPlayer.animation_finished

	is_hit = false  # ← ya puede reproducir otras animaciones

	if salud <= 0:
		die()
	else:
		await get_tree().create_timer(0.5).timeout
		inmune = false


func die():
	if is_dead:
		return
	is_dead = true
	animationPlayer.play("Dead")
	set_physics_process(false)
	set_process_input(false)
	$CollisionShape2D.disabled = true

	# Reiniciar contadores
	CollectibleManager.reset_award()

	await animationPlayer.animation_finished
	get_tree().reload_current_scene()

# ==== Otros ====
func calculate_stomp_velocity(force: float):
	velocity.y = -force

func add_coins(amount: int):
	coins += amount

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		print("Enemy entered", body.damage_amount)
		HealthManager.decrease_health(body.damage_amount)
		take_damage()
