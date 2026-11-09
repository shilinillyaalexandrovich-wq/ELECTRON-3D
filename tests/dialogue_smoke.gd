extends SceneTree

func _initialize() -> void:
    call_deferred("_run_dialogue_smoke_test")

func _run_dialogue_smoke_test() -> void:
    var packed_scene := load("res://scenes/main.tscn") as PackedScene
    if packed_scene == null:
        push_error("Dialogue smoke test: could not load the main store scene.")
        quit(1)
        return

    var game := packed_scene.instantiate()
    root.add_child(game)
    await process_frame

    var viewport_size: Vector2 = game.get_viewport().get_visible_rect().size
    var talk_touch := InputEventScreenTouch.new()
    talk_touch.index = 0
    talk_touch.pressed = true
    talk_touch.position = Vector2(viewport_size.x - 118.0, viewport_size.y * 0.68)
    game.call("_input", talk_touch)

    if not is_instance_valid(game.get("active_customer")):
        push_error("Dialogue smoke test: tapping the talk button did not select a nearby customer.")
        quit(1)
        return

    var options: Array = game.get("dialogue_options")
    if options.size() != 3:
        push_error("Dialogue smoke test: the first customer dialogue did not expose three choices.")
        quit(1)
        return

    # The script-mode CI runner does not emit Control.draw notifications.
    # Seed the same first-option hit rectangle used by _draw_hud, then test
    # the real touch-event dispatch path without depending on a rendered frame.
    var first_option := Rect2(18.0, viewport_size.y - 345.0, viewport_size.x - 36.0, 52.0)
    game.set("dialogue_rects", [first_option])

    var choice_touch := InputEventScreenTouch.new()
    choice_touch.index = 1
    choice_touch.pressed = true
    choice_touch.position = first_option.get_center()
    game.call("_input", choice_touch)

    if int(game.get("dialogue_step")) != 1:
        push_error("Dialogue smoke test: tapping a dialogue choice did not advance the conversation.")
        quit(1)
        return

    print("Dialogue smoke test passed: talk button opens a customer dialogue and a touch selects the first response.")
    game.queue_free()
    quit(0)
