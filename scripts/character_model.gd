extends RefCounted

# ELECTRON character kit v3.
# Procedural, low-poly cartoon people with readable silhouettes, layered clothes,
# expressive faces and role-specific details. No external assets are required.

class WalkAnimator:
    extends Node
    var left_arm: Node3D
    var right_arm: Node3D
    var left_leg: Node3D
    var right_leg: Node3D
    var previous_position := Vector3.ZERO
    var phase := 0.0
    var initialized := false

    func _process(delta: float) -> void:
        var actor := get_parent() as Node3D
        if actor == null:
            return
        if not initialized:
            previous_position = actor.global_position
            initialized = true
        var movement := actor.global_position.distance_to(previous_position) / maxf(delta, 0.001)
        previous_position = actor.global_position
        var amount := clampf(movement / 2.8, 0.0, 1.0)
        if amount > 0.04:
            phase += delta * 9.0 * clampf(movement / 2.8, 0.55, 1.6)
        var swing := sin(phase) * 0.58 * amount
        if is_instance_valid(left_arm):
            left_arm.rotation.x = swing
        if is_instance_valid(right_arm):
            right_arm.rotation.x = -swing
        if is_instance_valid(left_leg):
            left_leg.rotation.x = -swing * 0.85
        if is_instance_valid(right_leg):
            right_leg.rotation.x = swing * 0.85


static func add_human(root: Node3D, shirt_color: Color, skin_color: Color, hair_color: Color, role: String = "customer") -> void:
    var is_staff := role == "seller" or role == "player" or role == "manager"
    var is_manager := role == "manager"
    var pants_palette: Array[Color] = [
        Color(0.035, 0.055, 0.085), Color(0.12, 0.14, 0.18),
        Color(0.20, 0.19, 0.17), Color(0.075, 0.10, 0.13)
    ]
    var pants_color: Color = pants_palette[randi_range(0, pants_palette.size() - 1)]
    var shirt := _mat(shirt_color)
    var skin := _mat(skin_color)
    var hair := _mat(hair_color)
    var pants := _mat(pants_color if not is_staff else Color(0.035, 0.065, 0.095))
    var shoe_mat := _mat(Color(0.025, 0.032, 0.045))
    var sole_mat := _mat(Color(0.12, 0.14, 0.16))
    var white := _mat(Color(0.96, 0.97, 0.94))
    var dark := _mat(Color(0.018, 0.025, 0.035))
    var accent_color := Color(0.02, 0.78, 0.98) if is_staff else Color(0.95, 0.68, 0.28)
    var accent := _mat(accent_color)
    var scale_x := randf_range(0.91, 1.08)
    var scale_y := randf_range(0.94, 1.07)
    root.scale = Vector3(scale_x, scale_y, randf_range(0.94, 1.06))

    # Lower body: separate hips, articulated legs, visible knees and chunky shoes.
    var hips := _mesh(root, BoxMesh.new(), Vector3(0, 0.79, 0), pants)
    hips.mesh.size = Vector3(0.48, 0.30, 0.31)
    var belt := _mesh(root, BoxMesh.new(), Vector3(0, 0.91, -0.012), dark)
    belt.mesh.size = Vector3(0.46, 0.055, 0.325)
    var belt_buckle := _mesh(root, BoxMesh.new(), Vector3(0, 0.91, -0.18), accent)
    belt_buckle.mesh.size = Vector3(0.075, 0.065, 0.025)

    var animator := WalkAnimator.new()
    root.add_child(animator)
    animator.left_leg = _limb(root, Vector3(-0.16, 0.66, 0), 0.135, 0.78, pants)
    animator.right_leg = _limb(root, Vector3(0.16, 0.66, 0), 0.135, 0.78, pants)
    for side in [-1.0, 1.0]:
        var knee := _mesh(root, SphereMesh.new(), Vector3(side * 0.16, 0.43, -0.005), pants)
        knee.scale = Vector3(0.14, 0.15, 0.14)
        var shoe := _mesh(root, BoxMesh.new(), Vector3(side * 0.16, 0.105, -0.085), shoe_mat)
        shoe.mesh.size = Vector3(0.26, 0.16, 0.40)
        var toe := _mesh(root, SphereMesh.new(), Vector3(side * 0.16, 0.13, -0.235), shoe_mat)
        toe.scale = Vector3(0.13, 0.09, 0.12)
        var sole := _mesh(root, BoxMesh.new(), Vector3(side * 0.16, 0.045, -0.09), sole_mat)
        sole.mesh.size = Vector3(0.27, 0.045, 0.42)

    # Torso silhouette: broad shoulders, tapered waist and a distinct neck.
    var torso := _mesh(root, CapsuleMesh.new(), Vector3(0, 1.20, 0), shirt)
    torso.mesh.radius = 0.34
    torso.mesh.height = 0.88
    torso.scale = Vector3(1.0, 0.95, 0.76)
    var shoulder_line := _mesh(root, BoxMesh.new(), Vector3(0, 1.48, 0), shirt)
    shoulder_line.mesh.size = Vector3(0.70, 0.20, 0.34)
    var neck := _mesh(root, CylinderMesh.new(), Vector3(0, 1.69, 0), skin)
    neck.mesh.top_radius = 0.105
    neck.mesh.bottom_radius = 0.13
    neck.mesh.height = 0.20

    # Arms are pivoted at the shoulders; hands and cuffs make the silhouette readable.
    animator.left_arm = _limb(root, Vector3(-0.405, 1.43, 0), 0.115, 0.66, shirt)
    animator.right_arm = _limb(root, Vector3(0.405, 1.43, 0), 0.115, 0.66, shirt)
    for arm in [animator.left_arm, animator.right_arm]:
        var cuff := _mesh(arm, CylinderMesh.new(), Vector3(0, -0.28, 0), accent if is_staff else shirt)
        cuff.mesh.top_radius = 0.115
        cuff.mesh.bottom_radius = 0.115
        cuff.mesh.height = 0.09
        var hand := _mesh(arm, SphereMesh.new(), Vector3(0, -0.39, -0.015), skin)
        hand.scale = Vector3(0.105, 0.13, 0.095)
        var thumb := _mesh(arm, SphereMesh.new(), Vector3(0.075, -0.36, -0.06), skin)
        thumb.scale = Vector3(0.045, 0.075, 0.045)

    # Head is deliberately larger than realistic proportions for the approved cartoon style.
    var head := _mesh(root, SphereMesh.new(), Vector3(0, 1.99, -0.005), skin)
    head.scale = Vector3(0.315, 0.365, 0.285)
    for side in [-1.0, 1.0]:
        var ear := _mesh(root, SphereMesh.new(), Vector3(side * 0.302, 1.99, 0), skin)
        ear.scale = Vector3(0.078, 0.115, 0.07)
        var inner_ear := _mesh(root, SphereMesh.new(), Vector3(side * 0.326, 1.99, -0.035), _mat(Color(0.68, 0.36, 0.31)))
        inner_ear.scale = Vector3(0.025, 0.065, 0.025)

        var eye_white := _mesh(root, SphereMesh.new(), Vector3(side * 0.112, 2.025, -0.252), white)
        eye_white.scale = Vector3(0.064, 0.079, 0.035)
        var iris := _mesh(root, SphereMesh.new(), Vector3(side * 0.108, 2.025, -0.282), _mat(Color(0.20, 0.39, 0.52)))
        iris.scale = Vector3(0.037, 0.049, 0.018)
        var pupil := _mesh(root, SphereMesh.new(), Vector3(side * 0.108, 2.025, -0.297), dark)
        pupil.scale = Vector3(0.020, 0.031, 0.012)
        var glint := _mesh(root, SphereMesh.new(), Vector3(side * 0.096, 2.047, -0.308), white)
        glint.scale = Vector3(0.012, 0.014, 0.008)
        var brow := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.112, 2.135, -0.247), hair)
        brow.mesh.radius = 0.022
        brow.mesh.height = 0.13
        brow.rotation.z = side * -0.13

    var nose := _mesh(root, SphereMesh.new(), Vector3(0, 1.94, -0.302), skin)
    nose.scale = Vector3(0.052, 0.065, 0.055)
    var mouth := _mesh(root, SphereMesh.new(), Vector3(0, 1.855, -0.274), _mat(Color(0.30, 0.075, 0.085)))
    mouth.scale = Vector3(0.073, 0.018, 0.018)
    var lower_lip := _mesh(root, SphereMesh.new(), Vector3(0, 1.838, -0.269), _mat(Color(0.72, 0.30, 0.31)))
    lower_lip.scale = Vector3(0.045, 0.009, 0.01)

    _add_hair(root, hair, randi_range(0, 5))
    _add_outfit_details(root, role, shirt, accent, white, dark)

    # A small percentage of shoppers wear glasses; the frames sit in front of the eyes.
    if not is_staff and randi_range(0, 4) == 0:
        var frame := _mat(Color(0.035, 0.045, 0.06))
        for side in [-1.0, 1.0]:
            var lens := _mesh(root, BoxMesh.new(), Vector3(side * 0.112, 2.025, -0.291), frame)
            lens.mesh.size = Vector3(0.145, 0.105, 0.025)
        var bridge := _mesh(root, BoxMesh.new(), Vector3(0, 2.03, -0.30), frame)
        bridge.mesh.size = Vector3(0.075, 0.018, 0.022)


static func _add_hair(root: Node3D, hair: Material, style: int) -> void:
    var cap := _mesh(root, SphereMesh.new(), Vector3(0, 2.245, 0.015), hair)
    cap.scale = Vector3(0.32, 0.17, 0.29)
    if style == 0:
        var fringe := _mesh(root, SphereMesh.new(), Vector3(-0.09, 2.18, -0.205), hair)
        fringe.scale = Vector3(0.25, 0.10, 0.105)
        var side_lock := _mesh(root, SphereMesh.new(), Vector3(0.25, 2.06, -0.02), hair)
        side_lock.scale = Vector3(0.09, 0.19, 0.13)
    elif style == 1:
        cap.scale.y = 0.12
        for i in range(5):
            var spike := _mesh(root, SphereMesh.new(), Vector3(-0.22 + float(i) * 0.11, 2.34, -0.015), hair)
            spike.scale = Vector3(0.105, 0.13, 0.12)
    elif style == 2:
        for side in [-1.0, 1.0]:
            var curl := _mesh(root, SphereMesh.new(), Vector3(side * 0.22, 2.24, -0.10), hair)
            curl.scale = Vector3(0.13, 0.14, 0.13)
            var lock := _mesh(root, SphereMesh.new(), Vector3(side * 0.25, 2.02, 0.025), hair)
            lock.scale = Vector3(0.10, 0.22, 0.13)
    elif style == 3:
        cap.scale = Vector3(0.31, 0.12, 0.30)
        var fringe := _mesh(root, SphereMesh.new(), Vector3(0.05, 2.18, -0.20), hair)
        fringe.scale = Vector3(0.24, 0.10, 0.11)
        var bun := _mesh(root, SphereMesh.new(), Vector3(0, 2.18, 0.27), hair)
        bun.scale = Vector3(0.14, 0.15, 0.14)
    elif style == 4:
        cap.scale.y = 0.19
        for side in [-1.0, 1.0]:
            var long_lock := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.25, 1.99, 0.04), hair)
            long_lock.mesh.radius = 0.085
            long_lock.mesh.height = 0.48
    else:
        cap.scale = Vector3(0.30, 0.105, 0.27)
        for i in range(7):
            var curl_top := _mesh(root, SphereMesh.new(), Vector3(-0.24 + float(i) * 0.08, 2.32 + sin(float(i)) * 0.025, -0.02), hair)
            curl_top.scale = Vector3(0.095, 0.105, 0.10)


static func _add_outfit_details(root: Node3D, role: String, shirt: Material, accent: Material, white: Material, dark: Material) -> void:
    var is_staff := role == "seller" or role == "player" or role == "manager"
    if role == "manager":
        # Formal jacket, lapels and tie distinguish management from shop-floor staff.
        var jacket := _mesh(root, BoxMesh.new(), Vector3(0, 1.22, -0.135), _mat(Color(0.035, 0.075, 0.12)))
        jacket.mesh.size = Vector3(0.55, 0.63, 0.055)
        var shirt_front := _mesh(root, BoxMesh.new(), Vector3(0, 1.30, -0.17), white)
        shirt_front.mesh.size = Vector3(0.19, 0.48, 0.035)
        var tie := _mesh(root, BoxMesh.new(), Vector3(0, 1.23, -0.195), accent)
        tie.mesh.size = Vector3(0.07, 0.31, 0.025)
        return

    if is_staff:
        # ELECTRON uniform: deep navy body, bright cyan shoulders and a clear chest badge.
        var vest := _mesh(root, BoxMesh.new(), Vector3(0, 1.19, -0.165), _mat(Color(0.025, 0.105, 0.15)))
        vest.mesh.size = Vector3(0.49, 0.62, 0.045)
        var chest_panel := _mesh(root, BoxMesh.new(), Vector3(0, 1.47, -0.195), accent)
        chest_panel.mesh.size = Vector3(0.49, 0.12, 0.035)
        var badge := _mesh(root, BoxMesh.new(), Vector3(0.17, 1.30, -0.203), white)
        badge.mesh.size = Vector3(0.13, 0.105, 0.025)
        var badge_mark := _mesh(root, BoxMesh.new(), Vector3(0.17, 1.30, -0.221), accent)
        badge_mark.mesh.size = Vector3(0.075, 0.025, 0.012)
        var pocket := _mesh(root, BoxMesh.new(), Vector3(-0.15, 1.12, -0.195), dark)
        pocket.mesh.size = Vector3(0.12, 0.13, 0.025)
        var radio := _mesh(root, BoxMesh.new(), Vector3(-0.30, 1.39, -0.04), dark)
        radio.mesh.size = Vector3(0.075, 0.15, 0.09)
        var radio_light := _mesh(root, SphereMesh.new(), Vector3(-0.30, 1.44, -0.09), accent)
        radio_light.scale = Vector3(0.022, 0.022, 0.012)
    else:
        # Customers have an outerwear layer, collar and occasional shoulder strap.
        var jacket_color := _mat(Color(0.12, 0.15, 0.19, 1.0))
        if randi_range(0, 2) == 0:
            var jacket := _mesh(root, BoxMesh.new(), Vector3(0, 1.18, -0.14), jacket_color)
            jacket.mesh.size = Vector3(0.54, 0.48, 0.045)
            var zip := _mesh(root, BoxMesh.new(), Vector3(0, 1.19, -0.168), _mat(Color(0.48, 0.53, 0.58)))
            zip.mesh.size = Vector3(0.018, 0.40, 0.012)
        else:
            var collar := _mesh(root, BoxMesh.new(), Vector3(0, 1.55, -0.18), white)
            collar.mesh.size = Vector3(0.22, 0.055, 0.04)
        if randi_range(0, 5) == 0:
            var strap := _mesh(root, BoxMesh.new(), Vector3(0.25, 1.18, -0.17), dark)
            strap.mesh.size = Vector3(0.075, 0.64, 0.035)
