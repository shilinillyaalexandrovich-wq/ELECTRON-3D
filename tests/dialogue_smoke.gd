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

    if int(game.get("dialogue_step")) != 0:
        push_error("Dialogue smoke test: the conversation did not start at its first step.")
        quit(1)
        return

    var options: Array = game.get("dialogue_options")
    if options.size() != 3:
        push_error("Dialogue smoke test: the first customer dialogue did not expose three choices.")
        quit(1)
        return

    var player := game.get("player") as CharacterBody3D
    var camera := game.get("camera") as Camera3D
    var customers: Array = game.get("customers")
    var competitors: Array = game.get("competitor_nodes")
    if not is_instance_valid(player):
        push_error("Store scene smoke test: the 3D player was not created.")
        quit(1)
        return
    if not is_instance_valid(camera) or not camera.current:
        push_error("Store scene smoke test: the active 3D camera was not created.")
        quit(1)
        return
    if customers.size() < 4 or competitors.size() < 2:
        push_error("Store scene smoke test: expected four customers and two rival sellers.")
        quit(1)
        return
    if not _has_node_named(game, "HUD"):
        push_error("Store scene smoke test: the in-game HUD was not created.")
        quit(1)
        return
    var mesh_count := _count_mesh_instances(game)
    if mesh_count < 50:
        push_error("Store scene smoke test: procedural 3D store geometry is incomplete (%d meshes)." % mesh_count)
        quit(1)
        return
    print("Store scene smoke test passed: player, active camera, HUD, %d customers, %d rival sellers and %d 3D meshes." % [customers.size(), competitors.size(), mesh_count])

    # Walk through all conversation stages using the same touch path as Android.
    for expected_step in range(1, 4):
        _tap_dialogue_option(game, viewport_size, 0, expected_step)
        if int(game.get("dialogue_step")) != expected_step:
            push_error("Dialogue smoke test: touch did not advance to conversation step %d." % expected_step)
            quit(1)
            return
        options = game.get("dialogue_options")
        if options.size() != 3:
            push_error("Dialogue smoke test: conversation step %d did not expose three choices." % expected_step)
            quit(1)
            return

    # The final third option is the existing polite no-sale path.
    _tap_dialogue_option(game, viewport_size, 2, -1)
    if is_instance_valid(game.get("active_customer")):
        push_error("Dialogue smoke test: the final no-sale choice did not close the conversation.")
        quit(1)
        return
    if not (game.get("dialogue_options") as Array).is_empty():
        push_error("Dialogue smoke test: dialogue choices remained after the conversation closed.")
        quit(1)
        return

    print("Dialogue smoke test passed: Android-style touches start the conversation, advance all stages, and close it through the no-sale option.")
    game.queue_free()
    quit(0)

func _tap_dialogue_option(game: Node, viewport_size: Vector2, option_index: int, expected_step: int) -> void:
    var touch := InputEventScreenTouch.new()
    touch.index = 1
    touch.pressed = true
    touch.position = Vector2(viewport_size.x * 0.5, viewport_size.y - 345.0 + float(option_index) * 62.0 + 26.0)
    game.call("_input", touch)

func _count_mesh_instances(node: Node) -> int:
    var count: int = 1 if node is MeshInstance3D else 0
    for child in node.get_children():
        count += _count_mesh_instances(child)
    return count

func _has_node_named(node: Node, expected_name: String) -> bool:
    if node.name == expected_name:
        return true
    for child in node.get_children():
        if _has_node_named(child, expected_name):
            return true
    return false
