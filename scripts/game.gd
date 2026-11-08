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
var camera_yaw := 0.0
var action_button_rect := Rect2()
var action_button_center := Vector2.ZERO
var action_touch := -1
var action_dragging := false
var action_press_position := Vector2.ZERO
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

    # Мягкий общий свет убирает почти чёрные тени на персонажах и мебели.
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.36, 0.43, 0.52)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.72, 0.82, 0.96)
    environment.ambient_light_energy = 0.82
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = environment
    add_child(world)

    var light := DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-55, -25, 0)
    light.light_energy = 1.45
    light.shadow_enabled = true
    add_child(light)

    for x in [-7.0, -2.5, 2.5, 7.0]:
        var omni := OmniLight3D.new()
        omni.position = Vector3(x, 3.7, 0)
        omni.light_energy = 1.0
        omni.omni_range = 9
        add_child(omni)


func _build_store_details() -> void:
    # Светлый торговый зал с контрастными проходами и фирменными панелями.
    _box(Vector3(0, 0.005, 0), Vector3(23.4, 0.025, 17.4), Color(0.48, 0.52, 0.57))
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

    # Три открытых демонстрационных острова с узнаваемыми моделями техники.
    for island in range(3):
        var ix := -6.0 + float(island) * 6.0
        _box(Vector3(ix, 0.72, -0.1), Vector3(3.25, 1.12, 1.45), Color(0.075, 0.105, 0.14))
        _box(Vector3(ix, 1.32, -0.1), Vector3(3.18, 0.10, 1.38), Color(0.08, 0.58, 0.76))
        for p in range(3):
            var px := ix - 0.92 + float(p) * 0.92
            if island == 0:
                # Смартфон: корпус, стеклянный экран и камера.
                _box_node(Vector3(px, 1.48, -0.16), Vector3(0.34, 0.035, 0.62), Color(0.025,0.035,0.05))
                _box_node(Vector3(px, 1.501, -0.16), Vector3(0.29, 0.012, 0.53), [Color(0.05,0.36,0.58),Color(0.12,0.48,0.38),Color(0.35,0.2,0.48)][p])
                _box_node(Vector3(px, 1.51, 0.115), Vector3(0.06,0.008,0.025), Color(0.01,0.015,0.02))
            elif island == 1:
                # Ноутбук: клавиатурная база и поднятый экран.
                _box_node(Vector3(px, 1.47, -0.12), Vector3(0.72,0.045,0.48), Color(0.16,0.19,0.23))
                _box_node(Vector3(px, 1.70, -0.34), Vector3(0.70,0.42,0.045), Color(0.025,0.035,0.05))
                _box_node(Vector3(px, 1.70, -0.312), Vector3(0.63,0.35,0.012), [Color(0.06,0.3,0.5),Color(0.1,0.42,0.36),Color(0.3,0.2,0.42)][p])
            else:
                # Наушники на компактной демонстрационной подставке.
                _box_node(Vector3(px, 1.49, -0.14), Vector3(0.24,0.16,0.22), Color(0.19,0.22,0.26))
                var band := MeshInstance3D.new()
                var torus := TorusMesh.new()
                torus.inner_radius = 0.12
                torus.outer_radius = 0.17
                band.mesh = torus
                band.position = Vector3(px,1.77,-0.14)
                band.rotation_degrees.x = 90
                band.material_override = _mat([Color(0.08,0.1,0.13),Color(0.12,0.42,0.58),Color(0.32,0.22,0.4)][p])
                add_child(band)
                for side in [-1.0,1.0]:
                    var cup := MeshInstance3D.new()
                    var cup_mesh := CylinderMesh.new()
                    cup_mesh.top_radius = 0.09
                    cup_mesh.bottom_radius = 0.09
                    cup_mesh.height = 0.12
                    cup.mesh = cup_mesh
                    cup.position = Vector3(px + side*0.14,1.64,-0.14)
                    cup.material_override = _mat(Color(0.07,0.09,0.12))
                    add_child(cup)

    _add_store_label("СМАРТФОНЫ", Vector3(-6.0, 1.92, 0.82), 17, Color(0.86,0.96,1.0))
    _add_store_label("НОУТБУКИ", Vector3(0.0, 1.92, 0.82), 17, Color(0.86,0.96,1.0))
    _add_store_label("НАУШНИКИ", Vector3(6.0, 1.92, 0.82), 17, Color(0.86,0.96,1.0))

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

    # Верхнее пространство оставляем полностью открытым: камера не должна
    # упираться в потолочные балки и перекрывать обзор торгового зала.
    _box(Vector3(0, 3.72, -1.0), Vector3(7.5, 0.08, 0.24), Color(0.7, 0.88, 1.0))

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

    CHARACTER_MODEL.add_human(player, Color(0.035, 0.38, 0.72), Color(0.88, 0.66, 0.5), Color(0.16, 0.09, 0.045), "player")

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
    # Первые покупатели появляются в зоне досягаемости кнопки общения,
    # чтобы игрок мог начать консультацию сразу после входа в магазин.
    var spawn_points := [
        Vector3(-7.0,0.0,1.5), Vector3(-2.5,0.0,0.2),
        Vector3(2.5,0.0,0.2), Vector3(7.0,0.0,1.5)
    ]
    for i in range(4):
        var customer = CUSTOMER_SCRIPT.new()
        customer.customer_name = names[i]
        customer.position = spawn_points[i]
        add_child(customer)
        customers.append(customer)

func _spawn_competitors() -> void:
    var outfits := [Color(0.72,0.16,0.12),Color(0.18,0.28,0.62)]
    for i in range(2):
        var seller := Node3D.new()
        seller.name = "RivalSeller_%d" % i
        seller.position = Vector3(-5.5 + float(i)*11.0,0.0,-5.8)
        add_child(seller)
        CHARACTER_MODEL.add_human(seller,outfits[i],Color(0.78,0.57,0.43),Color(0.12,0.08,0.05), "seller")
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
                if _customer_claimed_by_other_seller(customer, i):
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

func _customer_claimed_by_other_seller(customer: Node3D, seller_index: int) -> bool:
    for other_index in range(competitor_targets.size()):
        if other_index == seller_index:
            continue
        if competitor_targets[other_index] == customer:
            return true
    return false

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
    hud.draw_rect(Rect2(18, 18, size.x - 36, 190), Color(0.025, 0.04, 0.06, 0.90), true)
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 49), "ELECTRON  |  ДЕНЬ %d" % day, HORIZONTAL_ALIGNMENT_LEFT, size.x - 220, 23, Color(0.2, 0.85, 1))
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 80), career.current_rank(), HORIZONTAL_ALIGNMENT_LEFT, size.x - 220, 17, Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 111), "Выручка: %d ₽   Продажи: %d" % [money, sales], HORIZONTAL_ALIGNMENT_LEFT, size.x - 220, 16, Color.WHITE)
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 140), "Личные деньги: %d ₽" % career.cash, HORIZONTAL_ALIGNMENT_LEFT, size.x - 220, 15, Color(0.78, 0.94, 0.84))
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 168), "План: %d / %d ₽   Опыт: %d" % [money, career.daily_target, career.experience], HORIZONTAL_ALIGNMENT_LEFT, size.x - 220, 14, Color(0.98, 0.82, 0.48))
    var target_ratio: float = clampf(float(money) / maxf(1.0, float(career.daily_target)), 0.0, 1.0)
    hud.draw_rect(Rect2(32, 178, size.x - 64, 9), Color(0.16, 0.2, 0.23), true)
    hud.draw_rect(Rect2(32, 178, (size.x - 64) * target_ratio, 9), Color(0.12, 0.78, 0.48), true)
    var next_rank_index: int = mini(career.rank_index + 1, career.PROMOTION_XP.size() - 1)
    var next_rank_xp: int = int(career.PROMOTION_XP[next_rank_index])
    var rank_progress_text := "Максимальный ранг" if career.rank_index >= career.RANKS.size() - 1 else "До повышения: %d XP  •  Жалобы: %d" % [maxi(0, next_rank_xp - career.experience), career.complaints]
    hud.draw_string(ThemeDB.fallback_font, Vector2(32, 204), rank_progress_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 64, 13, Color(0.72, 0.84, 0.92))
    hud.draw_rect(Rect2(18, size.y - 92, size.x - 36, 72), Color(0.025, 0.04, 0.06, 0.82), true)
    hud.draw_string(ThemeDB.fallback_font, Vector2(30, size.y - 62), message, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, 15, Color.WHITE)
    inventory_toggle_rect = Rect2(size.x - 170, 24, 140, 46)
    hud.draw_rect(inventory_toggle_rect, Color(0.04,0.32,0.42,0.95), true)
    hud.draw_rect(inventory_toggle_rect, Color(0.2,0.82,1.0), false, 2.0)
    hud.draw_string(ThemeDB.fallback_font, inventory_toggle_rect.position + Vector2(20,31), "СКЛАД / ЗАКАЗЫ", HORIZONTAL_ALIGNMENT_LEFT, 140, 16, Color.WHITE)
    close_day_rect = Rect2(size.x - 170, 78, 140, 42)
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
            hud.draw_string(ThemeDB.fallback_font, row.position + Vector2(12,42), "Закупка: %d ₽  •  Продажа: %d ₽" % [int(item["cost"]), int(item["price"])], HORIZONTAL_ALIGNMENT_LEFT, 340, 13, Color(0.65,0.88,0.92))
            hud.draw_string(ThemeDB.fallback_font, row.position + Vector2(370,32), "ЗАКАЗАТЬ +3", HORIZONTAL_ALIGNMENT_LEFT, 150, 15, Color(0.2,0.9,1.0))
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(22,455), "Нажми на товар, чтобы заказать 3 единицы. Нажми «СКЛАД» для закрытия.", HORIZONTAL_ALIGNMENT_LEFT, 520, 14, Color(0.72,0.82,0.88))
    var center := joystick_origin if joystick_touch != -1 else _get_joystick_center(size)
    var joystick_scale := _get_joystick_scale(size)
    hud.draw_circle(center, 68.0 * joystick_scale, Color(0.05, 0.08, 0.12, 0.72))
    hud.draw_circle(center, 68.0 * joystick_scale, Color(0.35, 0.58, 0.72, 0.92), false, 3.0 * joystick_scale)
    hud.draw_circle(center + joystick_vector * 48.0 * joystick_scale, 27.0 * joystick_scale, Color(0.1, 0.65, 0.9, 0.98))
    dialogue_rects.clear()
    if is_instance_valid(active_customer):
        action_button_rect = Rect2()
        var panel := Rect2(18, size.y - 520, size.x - 36, 155)
        hud.draw_rect(panel, Color(0.025, 0.04, 0.06, 0.94), true)
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 30), "ДИАЛОГ С ПОКУПАТЕЛЕМ", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.2, 0.85, 1))
        var lines := dialogue_text.split("\
")
        for i in range(mini(lines.size(), 2)):
            hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 58 + i * 25), lines[i], HORIZONTAL_ALIGNMENT_LEFT, int(panel.size.x - 30), 18, Color.WHITE)
        var patience_ratio: float = active_customer.patience_percent()
        var contact_score := clampi(dialogue_quality, 0, 6)
        var patience_label := "Терпение: %d%%   •   Контакт: %d/6" % [int(round(patience_ratio * 100.0)), contact_score]
        hud.draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 103), patience_label, HORIZONTAL_ALIGNMENT_LEFT, 250, 13, Color(0.78,0.88,0.94))
        var patience_bar := Rect2(panel.position + Vector2(270, 92), Vector2(maxf(80.0, panel.size.x - 290.0), 9))
        hud.draw_rect(patience_bar, Color(0.12,0.16,0.2), true)
        var patience_fill := Rect2(patience_bar.position, Vector2(patience_bar.size.x * patience_ratio, patience_bar.size.y))
        hud.draw_rect(patience_fill, Color(1.0 - patience_ratio, 0.35 + patience_ratio * 0.55, 0.18), true)
        for i in range(dialogue_options.size()):
            var rect := Rect2(18, size.y - 345 + i * 62, size.x - 36, 52)
            dialogue_rects.append(rect)
            hud.draw_rect(rect, Color(0.06, 0.28, 0.38, 0.96), true)
            hud.draw_rect(rect, Color(0.18, 0.72, 0.88, 0.9), false, 2.0)
            hud.draw_string(ThemeDB.fallback_font, rect.position + Vector2(14, 33), dialogue_options[i], HORIZONTAL_ALIGNMENT_LEFT, 315, 17, Color.WHITE)
    else:
        action_button_rect = _get_action_button_rect(size)
        hud.draw_circle(action_button_rect.get_center(), 48, Color(0.05, 0.62, 0.82, 0.92))
        hud.draw_circle(action_button_rect.get_center(), 54, Color(0.35, 0.88, 1.0, 0.75), false, 3.0)
        hud.draw_string(ThemeDB.fallback_font, Vector2(action_button_rect.position.x - 4, action_button_rect.position.y + 58), "ПОГОВОРИТЬ", HORIZONTAL_ALIGNMENT_CENTER, 180, 19, Color.WHITE)

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

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return
    # Вектор управления строится по базису камеры: вверх на экране — вперёд.
    var input_vector := joystick_vector
    if input_vector.length() > 0.10:
        var camera_right := camera.global_transform.basis.x
        var camera_forward := -camera.global_transform.basis.z
        camera_right.y = 0.0
        camera_forward.y = 0.0
        camera_right = camera_right.normalized()
        camera_forward = camera_forward.normalized()
        var direction := (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()
        var target_speed := 4.2
        player.velocity.x = move_toward(player.velocity.x, direction.x * target_speed, 24.0 * delta)
        player.velocity.z = move_toward(player.velocity.z, direction.z * target_speed, 24.0 * delta)
        player.rotation.y = lerp_angle(player.rotation.y, atan2(-direction.x, -direction.z), 1.0 - exp(-14.0 * delta))
    else:
        player.velocity.x = move_toward(player.velocity.x, 0.0, 28.0 * delta)
        player.velocity.z = move_toward(player.velocity.z, 0.0, 28.0 * delta)
    player.velocity.y = 0.0
    player.move_and_slide()
    if player.global_position.x < -10.4 or player.global_position.x > 10.4:
        player.velocity.x = 0.0
    if player.global_position.z < -7.4 or player.global_position.z > 7.4:
        player.velocity.z = 0.0
    _update_camera_transform(delta)

func _update_camera_transform(delta: float = 0.016) -> void:
    if not is_instance_valid(camera) or not is_instance_valid(player):
        return
    var target_position := player.global_position + Vector3(0.0, 3.5, 6.0)
    var follow_weight := 1.0 - exp(-8.0 * delta)
    camera.global_position = camera.global_position.lerp(target_position, follow_weight)
    camera.look_at(player.global_position + Vector3(0.0, 0.95, 0.0), Vector3.UP)

func _input(event: InputEvent) -> void:
    var size := get_viewport().get_visible_rect().size
    var center := _get_joystick_center(size)
    action_button_rect = _get_action_button_rect(size)
    if event is InputEventScreenTouch:
        if event.pressed:
            if inventory_toggle_rect.has_point(event.position):
                inventory_panel_open = not inventory_panel_open
                return
            if close_day_rect.has_point(event.position) and not inventory_panel_open and not is_instance_valid(active_customer):
                _close_workday()
                return
            if inventory_panel_open:
                _handle_inventory_tap(event.position)
                return
            if is_instance_valid(active_customer) and _dialogue_option_at(event.position):
                _handle_dialogue_tap(event.position)
                return
            if not is_instance_valid(active_customer) and action_button_rect.has_point(event.position):
                _serve_customer()
                return
            if joystick_touch == -1 and _is_joystick_touch_zone(event.position, size):
                joystick_touch = event.index
                joystick_origin = event.position
                _update_stick(event.position)
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
            if event.index == action_touch:
                if not action_dragging and action_press_position.distance_to(event.position) < 18.0:
                    _serve_customer()
                action_touch = -1
                action_dragging = false
    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            _update_stick(event.position)
        elif event.index == action_touch:
            if action_press_position.distance_to(event.position) > 14.0:
                action_dragging = true
            if action_dragging:
                action_button_center = event.position
                _clamp_action_button_center(size)
                action_button_rect = _get_action_button_rect(size)
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if inventory_toggle_rect.has_point(event.position):
                inventory_panel_open = not inventory_panel_open
                return
            if close_day_rect.has_point(event.position) and not inventory_panel_open and not is_instance_valid(active_customer):
                _close_workday()
                return
            if inventory_panel_open:
                _handle_inventory_tap(event.position)
                return
            if is_instance_valid(active_customer) and _dialogue_option_at(event.position):
                _handle_dialogue_tap(event.position)
                return
            if not is_instance_valid(active_customer) and action_button_rect.has_point(event.position):
                _serve_customer()
                return
            if joystick_touch == -1 and _is_joystick_touch_zone(event.position, size):
                joystick_touch = 0
                joystick_origin = event.position
                _update_stick(event.position)
        elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
            if joystick_touch == 0:
                joystick_touch = -1
                joystick_vector = Vector2.ZERO
            if action_touch == 0:
                if not action_dragging and action_press_position.distance_to(event.position) < 18.0:
                    _serve_customer()
                action_touch = -1
                action_dragging = false
    elif event is InputEventMouseMotion:
        if joystick_touch == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            _update_stick(event.position)
        elif action_touch == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
            if action_press_position.distance_to(event.position) > 14.0:
                action_dragging = true
            if action_dragging:
                action_button_center = event.position
                _clamp_action_button_center(size)
                action_button_rect = _get_action_button_rect(size)

func _get_action_button_rect(size: Vector2) -> Rect2:
    if action_button_center == Vector2.ZERO:
        action_button_center = Vector2(size.x - 118.0, size.y * 0.68)
    _clamp_action_button_center(size)
    return Rect2(action_button_center - Vector2(92, 60), Vector2(184, 120))

func _clamp_action_button_center(size: Vector2) -> void:
    action_button_center.x = clampf(action_button_center.x, 98.0, size.x - 98.0)
    action_button_center.y = clampf(action_button_center.y, 300.0, size.y - 125.0)

func _dialogue_option_at(position: Vector2) -> bool:
    for rect in dialogue_rects:
        if rect.has_point(position):
            return true
    return false

func _get_joystick_center(size: Vector2) -> Vector2:
    return Vector2(size.x * 0.14, size.y * 0.86)

func _get_joystick_scale(size: Vector2) -> float:
    return minf(size.x / 720.0, size.y / 1280.0)

func _is_joystick_touch_zone(pos: Vector2, size: Vector2) -> bool:
    # Плавающий джойстик: можно начать движение в любой точке нижней левой зоны.
    return pos.x < size.x * 0.56 and pos.y > size.y * 0.48 and pos.y < size.y - 70.0

func _update_stick(pos: Vector2) -> void:
    var scale_factor := _get_joystick_scale(get_viewport().get_visible_rect().size)
    var travel := 58.0 * scale_factor
    var offset := pos - joystick_origin
    joystick_vector = Vector2.ZERO if offset.length() < 8.0 * scale_factor else (offset / maxf(1.0, travel)).limit_length(1.0)

func _serve_customer() -> void:
    if is_instance_valid(active_customer) or not is_instance_valid(player):
        return
    var closest: Node3D
    var best := 10.0
    for customer in customers:
        if not is_instance_valid(customer) or bool(customer.get("is_being_served")):
            continue
        var offset := player.global_position - customer.global_position
        offset.y = 0.0
        var distance := offset.length()
        if distance < best:
            best = distance
            closest = customer
    if is_instance_valid(closest):
        active_customer = closest
        active_customer.begin_service()
        var to_player := player.global_position - active_customer.global_position
        to_player.y = 0.0
        if to_player.length() > 0.01:
            active_customer.rotation.y = atan2(-to_player.x, -to_player.z)
        dialogue_step = 0
        dialogue_quality = 0
        dialogue_approach = 0
        _set_dialogue_step()
        message = "Ты начал консультацию с %s." % active_customer.customer_name
        message_time = 2.0
    else:
        message = "Рядом нет покупателя. Подойди ближе к человеку и нажми ПОГОВОРИТЬ."
        message_time = 3.0

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
        if not inventory.sell(product_name, price):
            message = "Покупатель уже не смог купить товар: остаток закончился."
            message_time = 4.0
        else:
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
    c.position = Vector3([-8.0,-3.0,3.0,8.0].pick_random(), 0, randf_range(-3.8,-1.2))
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

    # Крупная мебель получает физические коллайдеры, чтобы персонаж
    # не проходил сквозь стойки, острова и стеллажи.
    if dimensions.x > 0.5 and dimensions.y > 0.5 and dimensions.z > 0.5:
        var body := StaticBody3D.new()
        body.position = pos
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = dimensions
        collision.shape = shape
        body.add_child(collision)
        add_child(body)

func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.82
    return material

func _rotate_camera(_horizontal_delta: float) -> void:
    # Оставлено для совместимости со старыми вызовами; камера теперь фиксирована за игроком.
    pass

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
    if bool(result.get("promoted", false)):
        message += "\nНОВОЕ ЗВАНИЕ: " + str(result.get("rank", career.current_rank()))
    message_time = 7.0
    day = career.day
    money = career.revenue
    sales = career.sales_count
    career.save_game()
