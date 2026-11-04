extends Node3D

const CHARACTER_MODEL = preload("res://scripts/character_model.gd")

var customer_name := "Покупатель"
var patience := 100.0
var max_patience := 100.0
var wander_target := Vector3.ZERO
var wander_timer := 0.0
var browse_timer := 0.0
var is_being_served := false
var price := 18990
var budget := 25000
var customer_type := "Обычный покупатель"
var product_name := "смартфон"
var need_text := "для повседневных задач"
var priority_text := "надёжность и удобство"
var objection_text := "Я видел похожую модель дешевле"
var patience_speed := 1.0

func _ready() -> void:
    var profiles := [
        {"type":"Экономный","product":"смартфон","price":[8990,12990],"budget":[11000,14000],"need":"для звонков, мессенджеров и фото","priority":"цена и автономность","objection":"Дороговато. Есть вариант подешевле?","patience":75.0,"speed":1.15},
        {"type":"Требовательный","product":"ноутбук","price":[35990,49990],"budget":[42000,52000],"need":"для работы, учёбы и многозадачности","priority":"производительность и надёжность","objection":"А чем эта модель лучше той, что я смотрел?","patience":55.0,"speed":0.9},
        {"type":"Спешащий","product":"наушники","price":[4990,8990],"budget":[6500,9500],"need":"для дороги и звонков","priority":"быстро подключить и долго пользоваться","objection":"У меня мало времени. Скажите коротко самое важное","patience":32.0,"speed":1.5},
        {"type":"Сравнивающий","product":"телевизор","price":[24990,35990],"budget":[30000,38000],"need":"для фильмов и спорта всей семьёй","priority":"качество изображения и диагональ","objection":"В интернете видел похожий дешевле","patience":95.0,"speed":0.8},
        {"type":"Постоянный","product":"планшет","price":[18990,24990],"budget":[22000,27000],"need":"для чтения, видео и поездок","priority":"экран, вес и батарея","objection":"Я подумаю и, возможно, вернусь","patience":110.0,"speed":0.85},
        {"type":"Любитель новинок","product":"смартфон","price":[27990,42990],"budget":[35000,45000],"need":"хочу попробовать новые функции и хорошую камеру","priority":"камера и современные возможности","objection":"Хочу понять, за что здесь такая цена","patience":80.0,"speed":1.0}
    ]
    var profile: Dictionary = profiles.pick_random()
    customer_type = str(profile["type"])
    product_name = str(profile["product"])
    price = randi_range(int(profile["price"][0]), int(profile["price"][1]))
    budget = randi_range(int(profile["budget"][0]), int(profile["budget"][1]))
    need_text = str(profile["need"])
    priority_text = str(profile["priority"])
    objection_text = str(profile["objection"])
    patience = float(profile["patience"])
    max_patience = patience
    patience_speed = float(profile["speed"])
    set_meta("price", price)
    set_meta("budget", budget)
    set_meta("product_name", product_name)
    set_meta("customer_type", customer_type)
    set_meta("need_text", need_text)
    set_meta("priority_text", priority_text)
    set_meta("objection_text", objection_text)

    var outfits := [Color(0.72,0.22,0.16),Color(0.18,0.42,0.28),Color(0.28,0.25,0.58),Color(0.78,0.48,0.12),Color(0.18,0.42,0.58)]
    var skins := [Color(0.94,0.73,0.58),Color(0.72,0.48,0.34),Color(0.52,0.33,0.23),Color(0.84,0.62,0.47)]
    var hairs := [Color(0.08,0.055,0.035),Color(0.28,0.14,0.07),Color(0.58,0.38,0.18),Color(0.12,0.12,0.14)]
    CHARACTER_MODEL.add_human(self,outfits.pick_random(),skins.pick_random(),hairs.pick_random(), "customer")

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.5
    collision.shape = shape
    collision.position.y = 0.75
    add_child(collision)
    _choose_browse_target()

func _process(delta: float) -> void:
    if is_being_served:
        return
    if browse_timer > 0.0:
        browse_timer -= delta
        return
    wander_timer -= delta
    if wander_timer <= 0.0 or global_position.distance_to(wander_target) < 0.3:
        _choose_browse_target()
    var direction := wander_target - global_position
    direction.y = 0.0
    if direction.length() > 0.25:
        global_position += direction.normalized() * delta * 0.65 * patience_speed
        rotation.y = atan2(-direction.x,-direction.z)
    else:
        browse_timer = randf_range(1.5,3.5)

func _choose_browse_target() -> void:
    wander_timer = randf_range(3.0,6.0)
    # Маршруты проходят по свободным проходам между островами,
    # а не сквозь витрины и демонстрационные столы.
    var stops := [
        Vector3(-8.0,0.0,2.8), Vector3(-3.8,0.0,2.8),
        Vector3(3.8,0.0,2.8), Vector3(8.0,0.0,2.8),
        Vector3(-8.0,0.0,-3.8), Vector3(-3.8,0.0,-3.8),
        Vector3(3.8,0.0,-3.8), Vector3(8.0,0.0,-3.8)
    ]
    wander_target = stops.pick_random()

func begin_service() -> void:
    is_being_served = true

func consume_patience(delta: float) -> bool:
    if not is_being_served:
        return false
    patience = maxf(0.0,patience-delta*patience_speed*2.2)
    return patience <= 0.0

func patience_percent() -> float:
    return clampf(patience/max_patience,0.0,1.0)
