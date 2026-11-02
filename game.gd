extends Node3D

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var info: Label
var objective: Label
var health_label: Label
var fire_button: Button
var mission_done := false
var enemies_left := 3
var health := 100
var ammo := 12
var look_touch := -1
var last_look := Vector2.ZERO
var move_vector := Vector2.ZERO
var yaw := 0.0
var pitch := 0.0

func _ready():
	player = get_node("Player")
	camera = player.get_node("Camera3D")
	_build_level()
	_build_hud()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not OS.has_feature("android") else Input.MOUSE_MODE_VISIBLE
	_update_hud()

func _build_level():
	_add_box(Vector3(0,-0.25,0), Vector3(24,0.5,24), Color(0.16,0.19,0.2))
	_add_box(Vector3(0,2,-12), Vector3(24,4,0.5), Color(0.24,0.29,0.31))
	_add_box(Vector3(-12,2,0), Vector3(0.5,4,24), Color(0.24,0.29,0.31))
	_add_box(Vector3(12,2,0), Vector3(0.5,4,24), Color(0.24,0.29,0.31))
	_add_box(Vector3(0,2,12), Vector3(24,4,0.5), Color(0.24,0.29,0.31))
	_add_box(Vector3(-4,1,0), Vector3(0.5,2,5), Color(0.31,0.35,0.36))
	_add_box(Vector3(4,1,-4), Vector3(0.5,2,5), Color(0.31,0.35,0.36))
	_add_box(Vector3(0,1,-8), Vector3(4,2,0.5), Color(0.37,0.25,0.12))
	for i in range(3):
		var enemy = CharacterBody3D.new()
		enemy.name = "Guarda_%d" % (i+1)
		enemy.position = [Vector3(-6,0.9,-5), Vector3(6,0.9,-8), Vector3(0,0.9,3)][i]
		var mesh = MeshInstance3D.new()
		var capsule = CapsuleMesh.new()
		capsule.radius = 0.38
		capsule.height = 1.8
		mesh.mesh = capsule
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.65,0.16,0.12)
		mesh.material_override = mat
		enemy.add_child(mesh)
		var col = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.38
		shape.height = 1.8
		col.shape = shape
		enemy.add_child(col)
		enemy.set_script(ENEMY_SCRIPT)
		add_child(enemy)

func _add_box(pos: Vector3, size: Vector3, color: Color):
	var body = StaticBody3D.new()
	body.position = pos
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	body.add_child(mesh)
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	add_child(body)

func _build_hud():
	hud = get_node("HUD")
	var panel = Panel.new()
	panel.position = Vector2(18,18)
	panel.size = Vector2(420,112)
	panel.modulate = Color(0.03,0.06,0.08,0.88)
	hud.add_child(panel)
	objective = Label.new()
	objective.position = Vector2(34,28)
	objective.add_theme_font_size_override("font_size",22)
	objective.text = "MISSÃO 01  |  Infiltração"
	hud.add_child(objective)
	info = Label.new()
	info.position = Vector2(34,62)
	info.add_theme_font_size_override("font_size",18)
	hud.add_child(info)
	health_label = Label.new()
	health_label.position = Vector2(34,88)
	health_label.add_theme_font_size_override("font_size",16)
	hud.add_child(health_label)
	var cross = Label.new()
	cross.text = "+"
	cross.add_theme_font_size_override("font_size",30)
	cross.position = Vector2(get_viewport().size.x/2-10,get_viewport().size.y/2-20)
	hud.add_child(cross)
	var shoot = Button.new()
	shoot.text = "ATIRAR"
	shoot.position = Vector2(get_viewport().size.x-150,get_viewport().size.y-110)
	shoot.size = Vector2(125,70)
	shoot.add_theme_font_size_override("font_size",20)
	shoot.pressed.connect(_shoot)
	hud.add_child(shoot)
	var jump = Button.new()
	jump.text = "PULAR"
	jump.position = Vector2(get_viewport().size.x-150,get_viewport().size.y-195)
	jump.size = Vector2(125,60)
	jump.pressed.connect(_jump)
	hud.add_child(jump)
	var up = Button.new()
	up.text = "▲"
	up.position = Vector2(35,get_viewport().size.y-190)
	up.size = Vector2(65,55)
	up.button_down.connect(func(): move_vector.y = -1)
	up.button_up.connect(func(): move_vector.y = 0)
	hud.add_child(up)
	var down = Button.new()
	down.text = "▼"
	down.position = Vector2(35,get_viewport().size.y-65)
	down.size = Vector2(65,55)
	down.button_down.connect(func(): move_vector.y = 1)
	down.button_up.connect(func(): move_vector.y = 0)
	hud.add_child(down)
	var left = Button.new()
	left.text = "◀"
	left.position = Vector2(-5,get_viewport().size.y-127)
	left.size = Vector2(65,55)
	left.button_down.connect(func(): move_vector.x = -1)
	left.button_up.connect(func(): move_vector.x = 0)
	hud.add_child(left)
	var right = Button.new()
	right.text = "▶"
	right.position = Vector2(105,get_viewport().size.y-127)
	right.size = Vector2(65,55)
	right.button_down.connect(func(): move_vector.x = 1)
	right.button_up.connect(func(): move_vector.x = 0)
	hud.add_child(right)

func _physics_process(delta):
	if mission_done:
		return
	var input_dir = Vector2.ZERO
	if OS.has_feature("android"):
		input_dir = move_vector
	else:
		input_dir = Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction = (player.global_transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
	player.velocity.x = direction.x * 5.0
	player.velocity.z = direction.z * 5.0
	if not player.is_on_floor():
		player.velocity.y -= 18.0 * delta
	else:
		player.velocity.y = 0
	player.move_and_slide()
	if Input.is_action_just_pressed("fire"):
		_shoot()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_rotate_view(event.relative)
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x > get_viewport().size.x * 0.42:
			look_touch = event.index
			last_look = event.position
		elif not event.pressed and event.index == look_touch:
			look_touch = -1
	if event is InputEventScreenDrag and event.index == look_touch:
		_rotate_view(event.relative * 0.7)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _rotate_view(amount: Vector2):
	yaw -= amount.x * 0.003
	pitch = clamp(pitch - amount.y * 0.003, -1.2, 1.2)
	player.rotation.y = yaw
	camera.rotation.x = pitch

func _shoot():
	if ammo <= 0:
		info.text = "Sem munição! Recarregue."
		return
	ammo -= 1
	var from = camera.global_position
	var to = from + -camera.global_transform.basis.z * 45.0
	var query = PhysicsRayQueryParameters3D.create(from,to)
	query.exclude = [player]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider is CharacterBody3D and hit.collider.has_method("take_damage"):
		hit.collider.take_damage()
	_update_hud()

func _jump():
	if player.is_on_floor():
		player.velocity.y = 6.5

func enemy_defeated():
	enemies_left -= 1
	_update_hud()
	if enemies_left <= 0:
		mission_done = true
		objective.text = "MISSÃO CONCLUÍDA!"
		info.text = "Área segura. Protótipo concluído."

func _update_hud():
	info.text = "Alvos restantes: %d     Munição: %d/12" % [enemies_left,ammo]
	health_label.text = "VIDA: %d%%" % health
