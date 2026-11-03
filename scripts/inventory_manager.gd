extends Node
class_name InventoryManager

const SAVE_PATH := "user://electron_inventory.json"

const CATALOG := {
    "смартфон": {"brand":"AURIX","name":"Смартфоны","cost":8500,"price":12990},
    "ноутбук": {"brand":"NEXORA","name":"Ноутбуки","cost":28500,"price":39990},
    "наушники": {"brand":"SOUNDIX","name":"Наушники","cost":2600,"price":4990},
    "телевизор": {"brand":"VOLTRON","name":"Телевизоры","cost":19500,"price":27990},
    "планшет": {"brand":"PIXELON","name":"Планшеты","cost":13200,"price":18990},
    "техника": {"brand":"ROBOX","name":"Бытовая техника","cost":7400,"price":11990}
}

var stock: Dictionary = {}
var store_funds: int = 250000
var total_cost: int = 0
var total_profit: int = 0

func _ready() -> void:
    for product_id in CATALOG.keys():
        stock[product_id] = 4
    load_inventory()

func product_id_for(product_name: String) -> String:
    var normalized := product_name.to_lower()
    if normalized.contains("смартфон"):
        return "смартфон"
    if normalized.contains("ноутбук"):
        return "ноутбук"
    if normalized.contains("наушник"):
        return "наушники"
    if normalized.contains("телевизор"):
        return "телевизор"
    if normalized.contains("планшет"):
        return "планшет"
    return "техника"

func quantity(product_name: String) -> int:
    return int(stock.get(product_id_for(product_name), 0))

func can_sell(product_name: String) -> bool:
    return quantity(product_name) > 0

func sell(product_name: String, sale_price: int) -> bool:
    var product_id := product_id_for(product_name)
    var amount := int(stock.get(product_id, 0))
    if amount <= 0:
        return false
    stock[product_id] = amount - 1
    var cost := int(CATALOG[product_id]["cost"])
    store_funds += sale_price
    total_profit += sale_price - cost
    save_inventory()
    return true

func order_stock(product_id: String, quantity_to_buy: int) -> Dictionary:
    if not CATALOG.has(product_id) or quantity_to_buy <= 0:
        return {"ok":false,"message":"Некорректный заказ."}
    var cost := int(CATALOG[product_id]["cost"]) * quantity_to_buy
    if store_funds < cost:
        return {"ok":false,"message":"Недостаточно средств магазина. Нужно %d ₽." % cost}
    store_funds -= cost
    stock[product_id] = int(stock.get(product_id, 0)) + quantity_to_buy
    total_cost += cost
    save_inventory()
    return {"ok":true,"message":"Заказано: %s × %d. Списано %d ₽." % [CATALOG[product_id]["name"],quantity_to_buy,cost]}

func save_inventory() -> void:
    var data := {"stock":stock,"store_funds":store_funds,"total_cost":total_cost,"total_profit":total_profit}
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func load_inventory() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var saved_stock = parsed.get("stock", {})
    for product_id in CATALOG.keys():
        stock[product_id] = int(saved_stock.get(product_id, 4))
    store_funds = int(parsed.get("store_funds", 250000))
    total_cost = int(parsed.get("total_cost", 0))
    total_profit = int(parsed.get("total_profit", 0))
