extends Node3D

var customer_name := "Покупатель"
var patience := 100.0
var wander_target := Vector3.ZERO
var wander_timer := 0.0
var price := 18990
var customer_type := "Обычный покупатель"
var product_name := "смартфон"

func _ready() -> void:
    var profiles := [
        {"type": "Экономный", "product": "смартфон", "budget": [8990, 12990], "patience": 75.0},
        {"type": "Требовательный", "product": "ноутбук", "budget": [35990, 49990], "patience": 45.0},
        {"type": "Спешащий", "product": "наушники", "budget": [4990, 8990], "patience": 25.0},
        {"type": "Сравнивающий", "product": "телевизор", "budget": [24990, 35990], "patience": 90.0},
        {"type": "Постоянный", "product": "планшет", "budget": [18990, 24990], "patience": 100.0}
    ]
    var profile: Dictionary = profiles.pick_random()
    customer_type = profile.type
    product_name = profile.product
    price = profile.budget.pick_random()
    patience = profile.patience
    set_meta("price", price)
    set_meta("product_name", product_name)
    set_meta("customer_type", customer_type)
    var body := MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.32
    capsule.height = 1.45
    body.mesh = capsule
    body.position.y = 0.75
    var material := StandardMaterial3D.new()
    material.albedo_color = [Color(0.88,0.42,0.25), Color(0.32,0.72,0.42), Color(0.65,0.48,0.82), Color(0.9,0.68,0.22)].pick_random()
    body.material_override = material
    add_child(body)

    var head := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.23
    head.mesh = sphere
    head.position.y = 1.58
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.9, 0.7, 0.55)
    head.material_override = skin
    add_child(head)

    var collision := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.32
    shape.height = 1.5
    collision.shape = shape
    collision.position.y = 0.75
    add_child(collision)
    wander_target = position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))

func _process(delta: float) -> void:
    wander_timer -= delta
    if wander_timer <= 0:
        wander_timer = randf_range(2.0, 5.0)
        wander_target = Vector3(randf_range(-8, 8), 0, randf_range(-5, 2))
    var direction := wander_target - position
    direction.y = 0
    if direction.length() > 0.25:
        position += direction.normalized() * delta * 0.65
        rotation.y = atan2(-direction.x, -direction.z)
    position.x = clamp(position.x, -9.5, 9.5)
    position.z = clamp(position.z, -7.0, 3.0)
