extends Node3D

const CUSTOMER_SCRIPT = preload("res://scripts/customer.gd")
const CHARACTER_MODEL = preload("res://scripts/character_model.gd")
const CAREER_SCRIPT = preload("res://scripts/career_manager.gd")
const INVENTORY_SCRIPT = preload("res://scripts/inventory_manager.gd")

var career
var inventory
var inventory_panel_open := false
var inventory_row_rects: Array[Rect2] = []
var inventory_toggle_rect := Rect2()
var close_day_rect := Rect2()
var player: CharacterBody3D
var camera: Camera3D
var customers: Array[Node3D] = []
var competitor_nodes: Array[Node3D] = []
var competitor_targets: Array[Node3D] = []
var competitor_service_time: Array[float] = []
var money := 0
var sales := 0
var day := 1
var message := "Добро пожаловать в ELECTRON!"
var message_time := 5.0
var joystick_touch := -1
var joystick_origin := Vector2.ZERO
var joystick_vector := Vector2.ZERO
var camera_touch := -1
var camera_yaw := 0.0
var camera_vector := Vector2.ZERO
var camera_sensitivity := 0.006
var action_button_rect := Rect2()
var active_customer: Node3D
var dialogue_step := -1
var dialogue_text := ""
var dialogue_options: Array[String] = []
var dialogue_rects: Array[Rect2] = []
var dialogue_quality := 0
var dialogue_approach := 0
var ui_font: Font

func _ready() -> void:
    career = CAREER_SCRIPT.new()
    add_child(career)
    career.load_game()
    inventory = INVENTORY_SCRIPT.new()
    add_child(inventory)
    day = career.day
    money = career.revenue
    sales = career.sales_count
    _build_store()
    _build_player()
    _spawn_customers()
    _spawn_competitors()
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
    # Крыша убрана: камера сверху должна видеть персонажа и покупателей.
    _box(Vector3(0, 3.5, -8.78), Vector3(8, 0.65, 0.12), Color(0.05, 0.65, 0.85))
    _box(Vector3(0, 3.5, -8.68), Vector3(7.4, 0.4, 0.08), Color(0.03, 0.12, 0.17))
    _build_store_details()

    for i in range(4):
        var x := -7.0 + float(i) * 4.6
        _box(Vector3(x, 0.75, -5.3), Vector3(3.2, 1.3, 1.2), Color(0.15, 0.2, 0.25))
        _box(Vector3(x, 1.55, -5.3), Vector3(3.0, 0.12, 1.05), Color(0.08, 0.55, 0.72))
        for j in range(3):
            _box(Vector3(x - 0.9 + j * 0.9, 2.05, -5.3), Vector3(0.55, 0.8, 0.42), [Color(0.22,0.65,0.9), Color(0.85,0.35,0.18), Color(0.3,0.75,0.45)][j])

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


func _build_store_details() -> void:
    # Светлый торговый зал с контрастными проходами и фирменными панелями.
    _box(Vector3(0, 0.005, 0), Vector3(23.4, 0.025, 17.4), Color(0.32, 0.36, 0.4))
    for x in [-10.0, -5.0, 0.0, 5.0, 10.0]:
        _box(Vector3(x, 0.012, 0), Vector3(0.035, 0.012, 16.8), Color(0.42, 0.48, 0.53))
    _box(Vector3(0, 0.03, 6.9), Vector3(10.0, 0.025, 1.1), Color(0.08, 0.35, 0.48))

    # Витринные окна по краям входа, центральный проход остаётся открытым.
    var glass := StandardMaterial3D.new()
    glass.albedo_color = Color(0.24, 0.68, 0.82, 0.22)
    glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    glass.roughness = 0.18
    glass.metallic = 0.25
    for side in [-1.0, 1.0]:
        var frame := _box_node(Vector3(side * 9.0, 1.65, 8.82), Vector3(4.8, 3.2, 0.08), Color(0.08, 0.13, 0.17))
        var pane := MeshInstance3D.new()
        var pane_mesh := BoxMesh.new()
        pane_mesh.size = Vector3(4.55, 2.85, 0.035)
        pane.mesh = pane_mesh
        pane.position = Vector3(side * 9.0, 1.65, 8.76)
        pane.material_override = glass
        add_child(pane)
    for x in [-11.35, -6.65, 6.65, 11.35]:
        _box(Vector3(x, 1.7, 8.7), Vector3(0.12, 3.4, 0.18), Color(0.04, 0.58, 0.76))
    _box(Vector3(0, 3.45, 8.68), Vector3(7.0, 0.32, 0.28), Color(0.04, 0.58, 0.76))
    _add_store_label("ELECTRON", Vector3(0, 3.48, 8.48), 42, Color(0.12, 0.86, 1.0))

    # Фирменная панель и телевизионная стена.
    _box(Vector3(0, 3.0, -8.72), Vector3(8.2, 1.25, 0.12), Color(0.025, 0.07, 0.11))
    _add_store_label("ТЕХНИКА. КОТОРАЯ ДВИЖЕТ.", Vector3(0, 3.05, -8.62), 22, Color(0.78, 0.92, 1.0))
    for i in range(4):
        var tx := -7.2 + float(i) * 4.8
        _box(Vector3(tx, 1.75, -8.35), Vector3(2.35, 1.38, 0.16), Color(0.025, 0.03, 0.04))
        _box(Vector3(tx, 1.75, -8.25), Vector3(2.17, 1.2, 0.035), [Color(0.04, 0.24, 0.38), Color(0.08, 0.34, 0.28), Color(0.2, 0.16, 0.38), Color(0.12, 0.28, 0.42)][i])
        _box(Vector3(tx, 0.92, -8.25), Vector3(0.16, 0.32, 0.12), Color(0.12, 0.14, 0.17))

    # Центральные острова с демонстрационными смартфонами и ноутбуками.
    for island in range(3):
        var ix := -6.0 + float(island) * 6.0
        _box(Vector3(ix, 0.78, 0.0), Vector3(3.5, 1.25, 1.7), Color(0.12, 0.16, 0.21))
        _box(Vector3(ix, 1.43, 0.0), Vector3(3.35, 0.12, 1.58), Color(0.12, 0.62, 0.78))
        for p in range(4):
            var px := ix - 1.15 + float(p) * 0.76
            if island == 1:
                _box(Vector3(px, 1.57, -0.12), Vector3(0.48, 0.035, 0.34), Color(0.035, 0.04, 0.05))
                _box(Vector3(px, 1.76, 0.02), Vector3(0.48, 0.36, 0.035), Color(0.08, 0.22, 0.32))
            else:
                _box(Vector3(px, 1.62, -0.05), Vector3(0.25, 0.42, 0.035), Color(0.025, 0.035, 0.045))
                _box(Vector3(px, 1.62, -0.025), Vector3(0.21, 0.37, 0.012), [Color(0.05, 0.35, 0.52), Color(0.12, 0.48, 0.38), Color(0.35, 0.2, 0.48), Color(0.3, 0.36, 0.42)][p])

    # Стеллажи с коробками и подсвеченными полками вдоль стен.
    for side in [-1.0, 1.0]:
        var sx: float = float(side) * 9.7
        for shelf in range(3):
            var sz := -3.8 + float(shelf) * 3.2
            _box(Vector3(sx, 1.15, sz), Vector3(0.55, 2.25, 2.35), Color(0.055, 0.075, 0.095))
            for level in range(3):
                _box(Vector3(sx - side * 0.31, 0.55 + float(level) * 0.72, sz), Vector3(0.08, 0.045, 2.2), Color(0.12, 0.62, 0.78))
                for item in range(3):
                    var iz := sz - 0.72 + float(item) * 0.72
                    _box(Vector3(sx - side * 0.38, 0.78 + float(level) * 0.72, iz), Vector3(0.28, 0.38, 0.38), [Color(0.2, 0.48, 0.68), Color(0.68, 0.3, 0.18), Color(0.24, 0.58, 0.38)][item])

    # Кассовая и сервисная стойки возле входа.
    _box(Vector3(-5.8, 0.72, 5.0), Vector3(3.4, 1.25, 1.15), Color(0.045, 0.09, 0.13))
    _box(Vector3(-5.8, 1.38, 5.0), Vector3(3.5, 0.12, 1.22), Color(0.06, 0.58, 0.76))
    _box(Vector3(-5.8, 1.65, 4.62), Vector3(0.62, 0.38, 0.06), Color(0.025, 0.035, 0.045))
    _box(Vector3(5.8, 0.72, 5.0), Vector3(3.4, 1.25, 1.15), Color(0.045, 0.09, 0.13))
    _box(Vector3(5.8, 1.38, 5.0), Vector3(3.5, 0.12, 1.22), Color(0.06, 0.58, 0.76))
    _add_store_label("КАССА", Vector3(-5.8, 1.9, 4.38), 18, Color(0.5, 0.9, 1.0))
    _add_store_label("СЕРВИС", Vector3(5.8, 1.9, 4.38), 18, Color(0.5, 0.9, 1.0))

    # Потолочные балки и световые короба без сплошной крыши.
    for x in [-8.0, -4.0, 0.0, 4.0, 8.0]:
        _box(Vector3(x, 4.0, 0.0), Vector3(0.12, 0.12, 15.5), Color(0.12, 0.18, 0.22))
        _box(Vector3(x, 3.88, -1.0), Vector3(1.5, 0.08, 0.32), Color(0.7, 0.88, 1.0))

func _box_node(pos: Vector3, dimensions: Vector3, color: Color) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = dimensions
    node.mesh = mesh
    node.position = pos
    node.material_override = _mat(color)
    add_child(node)
    return node

func _add_store_label(value: String, pos: Vector3, font_size: int, tint: Color) -> void:
    var label := Label3D.new()
    label.text = value
    label.font_size = font_size
    label.pixel_size = 0.008
    label.modulate = tint
    label.position = pos
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 0.05, 4.5)
    add_child(player)

    CHARACTER_MODEL.add_human(player, Color(0.035, 0.38, 0.72), Color(0.88, 0.66, 0.5), Color(0.16, 0.09, 0.045))

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.38
    shape.height = 1.7
    collision.shape = shape
    collision.position.y = 0.85
    player.add_child(collision)

    camera = Camera3D.new()
    camera.top_level = true
    camera_yaw = 0.0
    camera.current = true
    add_child(camera)
    _update_camera_transform()

func _spawn_customers() -> void:
    var names := ["Алексей", "Марина", "Игорь", "Ольга", "Денис", "Екатерина"]
    for i in range(4):
        var customer = CUSTOMER_SCRIPT.new()
        customer.customer_name = names[i]
        customer.position = Vector3(-7.0 + i * 4.5, 0.0, -1.0 - (i % 2) * 2.0)
        add_child(customer)
        customers.append(customer)

func _spawn_competitors() -> void:
    var outfits := [Color(0.72,0.16,0.12),Color(0.18,0.28,0.62)]
    for i in range(2):
        var seller := Node3D.new()
        seller.name = "RivalSeller_%d" % i
        seller.position = Vector3(-5.5 + float(i)*11.0,0.0,-5.8)
        add_child(seller)
        CHARACTER_MODEL.add_human(seller,outfits[i],Color(0.78,0.57,0.43),Color(0.12,0.08,0.05))
        var tag := Label3D.new()
        tag.text = "ПРОДАВЕЦ"
        tag.font_size = 15
        tag.pixel_size = 0.01
        tag.modulate = Color(1.0,0.82,0.35)
        tag.position = Vector3(0,2.25,0)
        tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        seller.add_child(tag)
        competitor_nodes.append(seller)
        competitor_targets.append(null)
        competitor_service_time.append(0.0)

func _update_competitors(delta: float) -> void:
    for i in range(competitor_nodes.size()):
        var seller := competitor_nodes[i]
        if not is_instance_valid(seller):
            continue
        var target: Node3D = competitor_targets[i]
        if not is_instance_valid(target) or bool(target.get("is_being_served")):
            target = null
            var nearest := 1000.0
            for customer in customers:
                if not is_instance_valid(customer) or bool(customer.get("is_being_served")):
                    continue
                var distance := seller.global_position.distance_to(customer.global_position)
                if distance < nearest:
                    nearest = distance
                    target = customer
            competitor_targets[i] = target
            competitor_service_time[i] = 0.0
        if not is_instance_valid(target):
            continue
        var direction := target.global_position - seller.global_position
        direction.y = 0.0
        var distance_to_customer := direction.length()
        if distance_to_customer > 1.15:
            seller.global_position += direction.normalized() * delta * 2.15
            seller.rotation.y = atan2(-direction.x,-direction.z)
            competitor_service_time[i] = 0.0
        else:
            competitor_service_time[i] += delta
            if competitor_service_time[i] >= 2.8:
                _rival_wins_customer(i,target)

func _rival_wins_customer(index: int, customer: Node3D) -> void:
    if not is_instance_valid(customer):
        competitor_targets[index] = null
        competitor_service_time[index] = 0.0
        return
    var amount := int(customer.get_meta("price",18990))
    var product_name := str(customer.get_meta("product_name","смартфон"))
    if not inventory.sell(product_name, amount):
        message = "На складе закончился товар: %s. Нужен новый заказ!" % product_name
        message_time = 4.0
        competitor_targets[index] = null
        competitor_service_time[index] = 0.0
        return
    var rival_commission := int(round(amount*0.025))
    # Соперник забирает клиента: его продажа влияет на общий результат магазина,
    # но личную комиссию игрок не получает.
    career.revenue += amount
    career.sales_count += 1
    career.save_game()
    money = career.revenue
    sales = career.sales_count
    message = "Конкурент перехватил клиента! Продажа магазина: %d ₽ (твоя комиссия — 0 ₽)." % amount
    message_time = 4.5
    customers.erase(customer)
    customer.queue_free()
    competitor_targets[index] = null
    competitor_service_time[index] = 0.0
    _spawn_one_customer()

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
    hud.draw_string(ThemeDB.fallback_font, Vector2(36, 52), "ELECTRON  |  ДЕНЬ %d  |  %s" % [day, career.current_rank()], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.2, 0.85, 1))
    hud.draw_string(ThemeDB.fallback_font, Vector2(36, 88), "Выручка: %d ₽   Продажи: %d   Опыт: %d" % [money, sales, career.experience], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
    hud.draw_rect(Rect2(18, size.y - 92, 330, 72), Color(0.025, 0.04, 0.06, 0.82), true)
    hud.draw_string(ThemeDB.fallback_font, Vector2(34, size.y - 63), message, HORIZONTAL_ALIGNMENT_LEFT, 290, 16, Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font, Vector2(size.x - 330, 45), "СЛЕВА — ДВИЖЕНИЕ  •  СПРАВА — ОБЗОР", HORIZONTAL_ALIGNMENT_LEFT, 320, 15, Color(0.7, 0.85, 0.9))
    inventory_toggle_rect = Rect2(size.x - 176, 64, 150, 48)
    hud.draw_rect(inventory_toggle_rect, Color(0.04,0.32,0.42,0.95), true)
    hud.draw_rect(inventory_toggle_rect, Color(0.2,0.82,1.0), false, 2.0)
    hud.draw_string(ThemeDB.fallback_font, inventory_toggle_rect.position + Vector2(20,31), "СКЛАД / ЗАКАЗЫ", HORIZONTAL_ALIGNMENT_LEFT, 140, 16, Color.WHITE)
    close_day_rect = Rect2(size.x - 176, 120, 150, 42)
    hud.draw_rect(close_day_rect, Color(0.28,0.22,0.06,0.95), true)
    hud.draw_rect(close_day_rect, Color(0.95,0.72,0.22), false, 2.0)
    hud.draw_string(ThemeDB.fallback_font, close_day_rect.position + Vector2(17,27), "ЗАКРЫТЬ ДЕНЬ", HORIZONTAL_ALIGNMENT_LEFT, 140, 15, Color.WHITE)
    inventory_row_rects.clear()
    if inventory_panel_open:
        var panel := Rect2((size.x - 560.0) / 2.0, (size.y - 470.0) / 2.0, 560, 470)
        hud.draw_rect(panel, Color(0.015,0.025,0.04,0.97), true)
        hud.draw_rect(panel, Color(0.12,0.72,0.9), false, 3.0)
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(22,35), "УПРАВЛЕНИЕ ЗАПАСАМИ", HORIZONTAL_ALIGNMENT_LEFT, 500, 24, Color(0.2,0.86,1.0))
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(22,66), "Средства магазина: %d ₽   •   Прибыль: %d ₽" % [inventory.store_funds,inventory.total_profit], HORIZONTAL_ALIGNMENT_LEFT, 520, 17, Color.WHITE)
        var ids := ["смартфон","ноутбук","наушники","телевизор","планшет","техника"]
        for i in range(ids.size()):
            var product_id: String = ids[i]
            var item: Dictionary = inventory.CATALOG[product_id]
            var row := Rect2(panel.position.x + 18, panel.position.y + 82 + i * 59, 524, 52)
            inventory_row_rects.append(row)
            hud.draw_rect(row, Color(0.05,0.1,0.15,0.98), true)
            hud.draw_string(ThemeDB.fallback_font, row.position + Vector2(12,22), "%s  %s  |  Остаток: %d" % [item["brand"],item["name"],inventory.stock.get(product_id,0)], HORIZONTAL_ALIGNMENT_LEFT, 320, 16, Color.WHITE)
            hud.draw_string(ThemeDB.fallback_font, row.position + Vector2(12,42), "Закупка: %d ₽ / шт." % int(item["cost"]), HORIZONTAL_ALIGNMENT_LEFT, 250, 13, Color(0.65,0.78,0.84))
            hud.draw_string(ThemeDB.fallback_font, row.position + Vector2(370,32), "ЗАКАЗАТЬ +3", HORIZONTAL_ALIGNMENT_LEFT, 150, 15, Color(0.2,0.9,1.0))
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(22,455), "Нажми на товар, чтобы заказать 3 единицы. Нажми «СКЛАД» для закрытия.", HORIZONTAL_ALIGNMENT_LEFT, 520, 14, Color(0.72,0.82,0.88))
    var center := Vector2(92, size.y - 130)
    hud.draw_circle(center, 62, Color(0.05, 0.08, 0.12, 0.55))
    hud.draw_circle(center + joystick_vector * 36, 25, Color(0.1, 0.65, 0.9, 0.9))
    var right_center := Vector2(size.x - 92, size.y - 130)
    hud.draw_circle(right_center, 62, Color(0.05, 0.08, 0.12, 0.55))
    hud.draw_circle(right_center + camera_vector * 36, 25, Color(0.1, 0.65, 0.9, 0.9))
    dialogue_rects.clear()
    if is_instance_valid(active_customer):
        action_button_rect = Rect2()
        var panel := Rect2(350, size.y - 405, size.x - 380, 112)
        hud.draw_rect(panel, Color(0.025, 0.04, 0.06, 0.94), true)
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 30), "ДИАЛОГ С ПОКУПАТЕЛЕМ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.85, 1))
        var lines := dialogue_text.split("\
")
        for i in range(mini(lines.size(), 2)):
            hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 58 + i * 25), lines[i], HORIZONTAL_ALIGNMENT_LEFT, int(panel.size.x - 30), 18, Color.WHITE)
        for i in range(dialogue_options.size()):
            var rect := Rect2(size.x - 370, size.y - 280 + i * 62, 340, 52)
            dialogue_rects.append(rect)
            hud.draw_rect(rect, Color(0.06, 0.28, 0.38, 0.96), true)
            hud.draw_rect(rect, Color(0.18, 0.72, 0.88, 0.9), false, 2.0)
            hud.draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 33), dialogue_options[i], HORIZONTAL_ALIGNMENT_LEFT, 315, 17, Color.WHITE)
    else:
        action_button_rect = _get_action_button_rect(size)
        hud.draw_circle(action_button_rect.get_center(), 48, Color(0.05, 0.62, 0.82, 0.92))
        hud.draw_string(ThemeDB.fallback_font, Vector2(action_button_rect.position.x - 4, action_button_rect.position.y + 58), "ОБЩАТЬСЯ", HORIZONTAL_ALIGNMENT_CENTER, 126, 17, Color.WHITE)

func _process(delta: float) -> void:
    if message_time > 0:
        message_time -= delta
        if message_time <= 0:
            message = "Найди покупателя и помоги ему с выбором."
    _update_competitors(delta)
    if is_instance_valid(active_customer) and active_customer.consume_patience(delta):
        _end_dialogue_without_sale()
        message = "Покупатель не дождался консультации и ушёл. Следи за его терпением!"
        message_time = 4.5
    get_viewport().get_camera_3d()
    var hud := get_node_or_null("CanvasLayer/HUD")
    if hud:
        hud.queue_redraw()

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    var direction := Vector3(joystick_vector.x, 0, joystick_vector.y).rotated(Vector3.UP, camera_yaw)
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
    _update_camera_transform()

func _update_camera_transform() -> void:
    if not is_instance_valid(camera) or not is_instance_valid(player):
        return
    var camera_offset := Vector3(0, 5.2, 8.5).rotated(Vector3.UP, camera_yaw)
    camera.global_position = player.global_position + camera_offset
    camera.look_at(player.global_position + Vector3(0, 1.0, 0), Vector3.UP)

func _input(event: InputEvent) -> void:
    var size := get_viewport().get_visible_rect().size
    var center := Vector2(92, size.y - 130)
    var right_center := Vector2(size.x - 92, size.y - 130)
    action_button_rect = _get_action_button_rect(size)
    if event is InputEventScreenTouch:
        if event.pressed:
            if inventory_toggle_rect.has_point(event.position):
                inventory_panel_open = not inventory_panel_open
            elif close_day_rect.has_point(event.position) and not inventory_panel_open and not is_instance_valid(active_customer):
                _close_workday()
            elif inventory_panel_open:
                _handle_inventory_tap(event.position)
            elif is_instance_valid(active_customer):
                _handle_dialogue_tap(event.position)
            elif center.distance_to(event.position) < 90:
                joystick_touch = event.index
                joystick_origin = center
                _update_stick(event.position)
            elif right_center.distance_to(event.position) < 90:
                camera_touch = event.index
                _update_camera_stick(event.position, right_center)
            elif action_button_rect.has_point(event.position):
                _serve_customer()
            elif event.position.x > size.x * 0.42 and event.position.y < size.y - 185:
                camera_touch = event.index
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
            if event.index == camera_touch:
                camera_touch = -1
                camera_vector = Vector2.ZERO
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_stick(event.position)
        elif event.index == camera_touch:
            _update_camera_stick(event.position, right_center)
            _rotate_camera(event.relative.x)
    elif event is InputEventMouseButton:
        if event.pressed:
            if is_instance_valid(active_customer):
                _handle_dialogue_tap(event.position)
            elif center.distance_to(event.position) < 90:
                joystick_touch = 0
                joystick_origin = center
                _update_stick(event.position)
            elif right_center.distance_to(event.position) < 90:
                camera_touch = 0
                _update_camera_stick(event.position, right_center)
            elif action_button_rect.has_point(event.position):
                _serve_customer()
            elif event.position.x > size.x * 0.42 and event.position.y < size.y - 185:
                camera_touch = 0
    elif event is InputEventMouseMotion:
        if joystick_touch == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _update_stick(event.position)
        elif camera_touch == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _update_camera_stick(event.position, right_center)
            _rotate_camera(event.relative.x)

func _get_action_button_rect(size: Vector2) -> Rect2:
    return Rect2(size.x - 166, size.y - 340, 132, 96)

func _update_stick(pos: Vector2) -> void:
    joystick_vector = ((pos - joystick_origin) / 55.0).limit_length(1.0)

func _update_camera_stick(pos: Vector2, origin: Vector2) -> void:
    camera_vector = ((pos - origin) / 55.0).limit_length(1.0)

func _serve_customer() -> void:
    if is_instance_valid(active_customer):
        return
    var closest: Node3D
    var best := 3.0
    for customer in customers:
        if not is_instance_valid(customer):
            continue
        var distance := player.global_position.distance_to(customer.global_position)
        if distance < best:
            best = distance
            closest = customer
    if closest:
        active_customer = closest
        active_customer.begin_service()
        dialogue_step = 0
        dialogue_quality = 0
        dialogue_approach = 0
        _set_dialogue_step()
    else:
        message = "Подойди ближе к покупателю!"
        message_time = 2.5

func _set_dialogue_step() -> void:
    if not is_instance_valid(active_customer):
        return
    var customer_name: String = active_customer.customer_name
    var product_name: String = active_customer.get_meta("product_name","смартфон")
    var customer_type: String = active_customer.get_meta("customer_type","Обычный покупатель")
    var need: String = active_customer.get_meta("need_text","для повседневных задач")
    var priority: String = active_customer.get_meta("priority_text","надёжность и удобство")
    var budget: int = int(active_customer.get_meta("budget",25000))
    var objection: String = active_customer.get_meta("objection_text","Есть вариант подешевле?")
    match dialogue_step:
        0:
            dialogue_text = "%s: «Здравствуйте! Ищу %s. Поможете выбрать?»\
Покупатель: %s" % [customer_name,product_name,customer_type]
            dialogue_options = ["Конечно! Расскажите, для чего нужен", "Какой бюджет планируете?", "Покажу самую дорогую модель"]
        1:
            if dialogue_approach == 0:
                dialogue_text = "%s: «Мне нужно %s. Главное — %s»" % [customer_name,need,priority]
            elif dialogue_approach == 1:
                dialogue_text = "%s: «Рассчитываю примерно на %d ₽. Не хочу переплачивать»" % [customer_name,budget]
            else:
                dialogue_text = "%s: «Люблю новинки, но объясните, за что плачу»" % customer_name
            dialogue_options = ["Понять, что для вас важнее всего", "Подобрать модель в ваш бюджет", "Предложить флагман с запасом"]
        2:
            dialogue_text = "%s: «%s»" % [customer_name,objection]
            dialogue_options = ["Объяснить преимущества именно под вашу задачу", "Показать более доступную альтернативу", "Предложить скидку и аксессуар"]
        3:
            dialogue_text = "%s: «Цена %d ₽. Как поступим?»" % [customer_name,int(active_customer.get_meta("price",18990))]
            dialogue_options = ["Оформить честную продажу", "Приукрасить характеристики ради продажи", "Не давить и отпустить клиента"]
        _:
            dialogue_text = ""
            dialogue_options.clear()

func _handle_dialogue_tap(position: Vector2) -> void:
    for i in range(dialogue_rects.size()):
        if dialogue_rects[i].has_point(position):
            _choose_dialogue_option(i)
            return

func _choose_dialogue_option(index: int) -> void:
    if not is_instance_valid(active_customer) or index < 0 or index >= dialogue_options.size():
        return
    if dialogue_step == 0:
        dialogue_approach = index
        dialogue_quality += 2 if index == 0 else (1 if index == 1 else 0)
        dialogue_step = 1
    elif dialogue_step == 1:
        if index == 0:
            dialogue_quality += 2
        elif index == 1:
            dialogue_quality += 2
        else:
            dialogue_quality += 1 if active_customer.customer_type == "Любитель новинок" else -1
        dialogue_step = 2
    elif dialogue_step == 2:
        var budget := int(active_customer.get_meta("budget",25000))
        var price := int(active_customer.get_meta("price",18990))
        if index == 0:
            dialogue_quality += 2
        elif index == 1:
            dialogue_quality += 2 if price > budget else 1
        else:
            dialogue_quality += 1
        dialogue_step = 3
    elif dialogue_step == 3:
        if index == 2:
            _end_dialogue_without_sale()
            return
        _resolve_customer_sale(index == 0)
        return
    _set_dialogue_step()

func _end_dialogue_without_sale() -> void:
    message = "Ты вежливо попрощался. Покупатель может вернуться позже."
    message_time = 4.0
    var customer := active_customer
    active_customer = null
    dialogue_step = -1
    dialogue_options.clear()
    if is_instance_valid(customer):
        customers.erase(customer)
        customer.queue_free()
    _spawn_one_customer()

func _resolve_customer_sale(honest: bool) -> void:
    if not is_instance_valid(active_customer):
        active_customer = null
        return
    var product_name := str(active_customer.get_meta("product_name","смартфон"))
    if not inventory.can_sell(product_name):
        message = "Товар закончился на складе! Открой «СКЛАД / ЗАКАЗЫ» и пополни запас."
        message_time = 5.0
        _end_dialogue_without_sale()
        return
    var base_price := int(active_customer.get_meta("price",18990))
    var budget := int(active_customer.get_meta("budget",25000))
    var price := base_price if honest else int(round(base_price*1.12))
    var reputation_bonus := float(career.reputation)/250.0
    var budget_factor := 0.16 if price <= budget else -0.22
    var patience_factor := float(active_customer.patience_percent())*0.12
    var success_chance := clampf(0.34+float(dialogue_quality)*0.105+reputation_bonus+budget_factor+patience_factor,0.12,0.94)
    if not honest:
        success_chance -= 0.12
    var customer_name: String = active_customer.customer_name
    if randf() > success_chance:
        message = "%s: «Спасибо, я ещё подумаю». Сделка не состоялась." % customer_name
        message_time = 5.0
    else:
        inventory.sell(product_name, price)
        var result: Dictionary = career.register_sale(price,honest)
        money = career.revenue
        sales = career.sales_count
        day = career.day
        if honest:
            message = "Продажа: %d ₽. Комиссия +%d ₽. %s" % [price,result.commission,"Повышение! "+result.rank if result.promoted else "Репутация растёт."]
        else:
            message = "Продажа с обманом: %d ₽. Комиссия +%d ₽, репутация снизилась." % [price,result.commission]
        message_time = 5.0
        career.save_game()
    var finished_customer := active_customer
    active_customer = null
    dialogue_step = -1
    dialogue_options.clear()
    customers.erase(finished_customer)
    finished_customer.queue_free()
    _spawn_one_customer()

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

func _rotate_camera(horizontal_delta: float) -> void:
    camera_yaw -= horizontal_delta * camera_sensitivity
    camera_yaw = wrapf(camera_yaw, -TAU, TAU)

func _handle_inventory_tap(position: Vector2) -> void:
    for i in range(inventory_row_rects.size()):
        if inventory_row_rects[i].has_point(position):
            var ids := ["смартфон","ноутбук","наушники","телевизор","планшет","техника"]
            var result: Dictionary = inventory.order_stock(ids[i],3)
            message = str(result.message)
            message_time = 4.0
            return

func _close_workday() -> void:
    var result: Dictionary = career.close_day()
    message = "День закрыт! Выручка: %d ₽ / план: %d ₽. Бонус: %d ₽. Зарплата: %d ₽." % [result.revenue,result.target,result.bonus,result.salary_paid]
    message_time = 7.0
    day = career.day
    money = career.revenue
    sales = career.sales_count
    career.save_game()
