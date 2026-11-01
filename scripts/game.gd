extends Node3D

const CUSTOMER_SCRIPT = preload("res://scripts/customer.gd")

var player: CharacterBody3D
var camera: Camera3D
var customers: Array[Node3D] = []
var money := 0
var sales := 0
var day := 1
var message := "Добро пожаловать в ELECTRON!"
var message_time := 5.0
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var action_button_rect := Rect2()
var ui_font: Font

func _ready() -> void:
    _build_store()
    _build_player()
    _spawn_customers()
    _build_ui()

func _build_store() -> void:
    var floor_mesh := MeshInstance3D.new()
    var floor := BoxMesh.new()
    floor.size = Vector3(24, 0.2, 18)
    floor_mesh.mesh = floor
    floor_mesh.position = Vector3(0, -0.15, 0)
    floor_mesh.material_override = _mat(Color(0.22, 0.25, 0.29))
    add_child(floor_mesh)

    _box(Vector3(0, 2.2, -9), Vector3(24, 4.5, 0.3), Color(0.12, 0.16, 0.21))
    _box(Vector3(-11.8, 2.2, 0), Vector3(0.3, 4.5, 18), Color(0.12, 0.16, 0.21))
    _box(Vector3(11.8, 2.2, 0), Vector3(0.3, 4.5, 18), Color(0.12, 0.16, 0.21))
    _box(Vector3(0, 4.5, 0), Vector3(24, 0.2, 18), Color(0.08, 0.1, 0.13))
    _box(Vector3(0, 3.5, -8.78), Vector3(8, 0.65, 0.12), Color(0.05, 0.65, 0.85))
    _box(Vector3(0, 3.5, -8.68), Vector3(7.4, 0.4, 0.08), Color(0.03, 0.12, 0.17))

    for i in range(4):
        var x := -7.0 + float(i) * 4.6
        _box(Vector3(x, 0.75, -5.3), Vector3(3.2, 1.3, 1.2), Color(0.15, 0.2, 0.25))
        _box(Vector3(x, 1.55, -5.3), Vector3(3.0, 0.12, 1.05), Color(0.08, 0.55, 0.72))
        for j in range(3):
            _box(Vector3(x - 0.9 + j * 0.9, 2.05, -5.3), Vector3(0.55, 0.8, 0.42), [Color(0.22,0.65,0.9), Color(0.85,0.35,0.18), Color(0.3,0.75,0.45)][j])

    for i in range(3):
        var z := -1.5 + float(i) * 3.1
        _box(Vector3(-5.2, 0.65, z), Vector3(3.4, 1.1, 1.4), Color(0.18, 0.22, 0.28))
        _box(Vector3(5.2, 0.65, z), Vector3(3.4, 1.1, 1.4), Color(0.18, 0.22, 0.28))

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.25
    add_child(light)

    for x in [-7.0, -2.5, 2.5, 7.0]:
        var omni := OmniLight3D.new()
        omni.position = Vector3(x, 3.7, 0)
        omni.light_energy = 0.8
        omni.omni_range = 8
        add_child(omni)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.05, 4.5)
    add_child(player)

    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.38
    capsule.height = 1.65
    body.mesh = capsule
    body.position.y = 0.85
    body.material_override = _mat(Color(0.05, 0.55, 0.9))
    player.add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.28
    sphere.height = 0.56
    head.mesh = sphere
    head.position.y = 1.82
    head.material_override = _mat(Color(0.92, 0.72, 0.56))
    player.add_child(head)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.7
    collision.shape = shape
    collision.position.y = 0.85
    player.add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 5.2, 8.5)
    camera.rotation_degrees = Vector3(-27, 0, 0)
    camera.current = true
    player.add_child(camera)

func _spawn_customers() -> void:
    var names := ["Алексей", "Марина", "Игорь", "Ольга", "Денис", "Екатерина"]
    for i in range(4):
        var customer = CUSTOMER_SCRIPT.new()
        customer.customer_name = names[i]
        customer.position = Vector3(-7.0 + i * 4.5, 0.0, -1.0 - (i % 2) * 2.0)
        add_child(customer)
        customers.append(customer)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var hud := Control.new()
    hud.name = "HUD"
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(hud)
    hud.draw.connect(_draw_hud.bind(hud))

func _draw_hud(hud: Control) -> void:
    var size := hud.get_viewport_rect().size
    hud.draw_rect(Rect2(18, 18, 360, 92), Color(0.025, 0.04, 0.06, 0.88), true)
    hud.draw_string(ThemeDB.fallback_font, Vector2(36, 52), "ELECTRON  |  ДЕНЬ %d" % day, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.2, 0.85, 1))
    hud.draw_string(ThemeDB.fallback_font, Vector2(36, 88), "Выручка: %d ₽     Продажи: %d" % [money, sales], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    hud.draw_rect(Rect2(18, size.y - 92, 330, 72), Color(0.025, 0.04, 0.06, 0.82), true)
    hud.draw_string(ThemeDB.fallback_font, Vector2(34, size.y - 63), message, HORIZONTAL_ALIGNMENT_LEFT, 290, 16, Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font, Vector2(size.x - 260, 45), "ПОДОЙДИ К ПОКУПАТЕЛЮ", HORIZONTAL_ALIGNMENT_LEFT, 250, 15, Color(0.7, 0.85, 0.9))
    var center := Vector2(92, size.y - 190)
    hud.draw_circle(center, 62, Color(0.05, 0.08, 0.12, 0.45))
    hud.draw_circle(center + joystick_vector * 36, 25, Color(0.1, 0.65, 0.9, 0.8))
    action_button_rect = Rect2(size.x - 150, size.y - 160, 118, 100)
    hud.draw_circle(action_button_rect.get_center(), 48, Color(0.05, 0.62, 0.82, 0.88))
    hud.draw_string(ThemeDB.fallback_font, Vector2(size.x - 191, size.y - 100), "ПРОДАТЬ", HORIZONTAL_ALIGNMENT_CENTER, 120, 17, Color.WHITE)

func _process(delta: float) -> void:
    if message_time > 0:
        message_time -= delta
        if message_time <= 0:
            message = "Найди покупателя и помоги ему с выбором."
    get_viewport().get_camera_3d()
    var hud := get_node_or_null("CanvasLayer/HUD")
    if hud:
        hud.queue_redraw()

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var direction := Vector3(joystick_vector.x, 0, joystick_vector.y)
    if direction.length() > 0.08:
        direction = direction.normalized()
        player.velocity.x = direction.x * 4.2
        player.velocity.z = direction.z * 4.2
        player.rotation.y = atan2(-direction.x, -direction.z)
    else:
        player.velocity.x = move_toward(player.velocity.x, 0.0, 20.0 * get_physics_process_delta_time())
        player.velocity.z = move_toward(player.velocity.z, 0.0, 20.0 * get_physics_process_delta_time())
    player.velocity.y = 0
    player.move_and_slide()
    player.position.x = clamp(player.position.x, -10.5, 10.5)
    player.position.z = clamp(player.position.z, -7.5, 7.5)

func _input(event: InputEvent) -> void:
    var size := get_viewport().get_visible_rect().size
    var center := Vector2(92, size.y - 190)
    if event is InputEventScreenTouch:
        if event.pressed:
            if center.distance_to(event.position) < 90:
                joystick_touch = event.index
                joystick_origin = center
                _update_stick(event.position)
            elif action_button_rect.has_point(event.position):
                _serve_customer()
        elif event.index == joystick_touch:
            joystick_touch = -1
            joystick_vector = Vector2.ZERO
    elif event is InputEventScreenDrag and event.index == joystick_touch:
        _update_stick(event.position)
    elif event is InputEventMouseButton and event.pressed:
        if action_button_rect.has_point(event.position):
            _serve_customer()
        elif center.distance_to(event.position) < 90:
            joystick_touch = 0
            _update_stick(event.position)
    elif event is InputEventMouseMotion and joystick_touch == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
        _update_stick(event.position)

func _update_stick(pos: Vector2) -> void:
    joystick_vector = ((pos - joystick_origin) / 55.0).limit_length(1.0)

func _serve_customer() -> void:
    var closest: Node3D
    var best := 3.0
    for c in customers:
        if not is_instance_valid(c):
            continue
        var d := player.global_position.distance_to(c.global_position)
        if d < best:
            best = d
            closest = c
    if closest:
        var price := closest.get_meta("price", 18990)
        money += int(price)
        sales += 1
        message = "Продажа! +%d ₽. Клиент доволен." % int(price)
        message_time = 4.0
        closest.queue_free()
        customers.erase(closest)
        if customers.size() < 4:
            _spawn_one_customer()
    else:
        message = "Подойди ближе к покупателю!"
        message_time = 2.5

func _spawn_one_customer() -> void:
    var c = CUSTOMER_SCRIPT.new()
    c.customer_name = ["Павел", "Светлана", "Роман", "Анна"].pick_random()
    c.position = Vector3(randf_range(-7, 7), 0, randf_range(-2, 1))
    add_child(c)
    customers.append(c)

func _box(pos: Vector3, dimensions: Vector3, color: Color) -> void:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.82
    return material
