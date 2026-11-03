extends Node3D

const CHARACTER_MODEL = preload("res://scripts/character_model.gd")

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
    var outfits := [Color(0.72, 0.22, 0.16), Color(0.18, 0.42, 0.28), Color(0.28, 0.25, 0.58), Color(0.78, 0.48, 0.12), Color(0.18, 0.42, 0.58)]
    var skins := [Color(0.94, 0.73, 0.58), Color(0.72, 0.48, 0.34), Color(0.52, 0.33, 0.23), Color(0.84, 0.62, 0.47)]
    var hairs := [Color(0.08, 0.055, 0.035), Color(0.28, 0.14, 0.07), Color(0.58, 0.38, 0.18), Color(0.12, 0.12, 0.14)]
    CHARACTER_MODEL.add_human(self, outfits.pick_random(), skins.pick_random(), hairs.pick_random())

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
