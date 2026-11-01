extends Node
class_name CareerManager

const SAVE_PATH := "user://electron_save.json"

var day: int = 1
var cash: int = 0
var revenue: int = 0
var sales_count: int = 0
var experience: int = 0
var reputation: int = 50
var complaints: int = 0
var daily_target: int = 50000
var salary: int = 1800
var rank_index: int = 0

const RANKS := [
    "Продавец-консультант",
    "Старший продавец",
    "Администратор",
    "Директор магазина",
    "Региональный директор",
    "Генеральный директор"
]

const PROMOTION_XP := [0, 250, 800, 1800, 4000, 9000]

func register_sale(amount: int, honest: bool = true) -> Dictionary:
    var commission := int(round(amount * 0.025))
    revenue += amount
    sales_count += 1
    cash += commission
    experience += 25
    if honest:
        reputation = mini(100, reputation + 2)
    else:
        reputation = maxi(0, reputation - 8)
        complaints += 1
    var promoted := _check_promotion()
    return {
        "amount": amount,
        "commission": commission,
        "promoted": promoted,
        "rank": current_rank()
    }

func current_rank() -> String:
    return RANKS[rank_index]

func _check_promotion() -> bool:
    if rank_index < RANKS.size() - 1 and experience >= PROMOTION_XP[rank_index + 1]:
        rank_index += 1
        salary += 600
        reputation = mini(100, reputation + 5)
        return true
    return false

func close_day() -> Dictionary:
    var bonus := 0
    if revenue >= daily_target:
        bonus = int(daily_target * 0.05)
        cash += bonus
        experience += 50
    var result := {
        "revenue": revenue,
        "target": daily_target,
        "bonus": bonus,
        "sales": sales_count
    }
    day += 1
    revenue = 0
    sales_count = 0
    daily_target = 50000 + (day - 1) * 5000
    save_game()
    return result

func save_game() -> void:
    var data := {
        "day": day,
        "cash": cash,
        "revenue": revenue,
        "sales_count": sales_count,
        "experience": experience,
        "reputation": reputation,
        "complaints": complaints,
        "daily_target": daily_target,
        "salary": salary,
        "rank_index": rank_index
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func load_game() -> bool:
    if not FileAccess.file_exists(SAVE_PATH):
        return false
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return false
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return false
    day = int(parsed.get("day", 1))
    cash = int(parsed.get("cash", 0))
    revenue = int(parsed.get("revenue", 0))
    sales_count = int(parsed.get("sales_count", 0))
    experience = int(parsed.get("experience", 0))
    reputation = int(parsed.get("reputation", 50))
    complaints = int(parsed.get("complaints", 0))
    daily_target = int(parsed.get("daily_target", 50000))
    salary = int(parsed.get("salary", 1800))
    rank_index = clampi(int(parsed.get("rank_index", 0)), 0, RANKS.size() - 1)
    return true
