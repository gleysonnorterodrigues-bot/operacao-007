extends CharacterBody3D

var hp := 2
var attack_timer := 0.0

func _ready():
	pass

func _physics_process(delta):
	var game = get_parent()
	if not game.has_node("Player"):
		return
	var player = game.get_node("Player")
	var distance = global_position.distance_to(player.global_position)
	if distance < 9.0 and distance > 1.4:
		var direction = (player.global_position - global_position).normalized()
		velocity.x = direction.x * 1.2
		velocity.z = direction.z * 1.2
		look_at(Vector3(player.global_position.x,global_position.y,player.global_position.z))
		move_and_slide()
	elif distance <= 1.4:
		attack_timer -= delta
		if attack_timer <= 0:
			game.health = max(0,game.health-5)
			game._update_hud()
			attack_timer = 1.0

func take_damage():
	hp -= 1
	if hp <= 0:
		var game = get_parent()
		game.enemy_defeated()
		queue_free()
