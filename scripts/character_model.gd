extends RefCounted

# Character kit v2: layered silhouettes, role-specific uniforms and procedural walk cycle.
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
        var swing := sin(phase) * 0.62 * amount
        if is_instance_valid(left_arm):
            left_arm.rotation.x = swing
        if is_instance_valid(right_arm):
            right_arm.rotation.x = -swing
        if is_instance_valid(left_leg):
            left_leg.rotation.x = -swing * 0.85
        if is_instance_valid(right_leg):
            right_leg.rotation.x = swing * 0.85

static func add_human(root: Node3D, shirt_color: Color, skin_color: Color, hair_color: Color, role: String = "customer") -> void:
    var shirt := _mat(shirt_color)
    var skin := _mat(skin_color)
    var hair := _mat(hair_color)
    var pants_color := [Color(0.055,0.075,0.105), Color(0.16,0.18,0.22), Color(0.10,0.13,0.17)].pick_random()
    var pants := _mat(pants_color)
    var shoe_mat := _mat(Color(0.035,0.045,0.06))
    var white := _mat(Color(0.96,0.97,0.94))
    var dark := _mat(Color(0.025,0.032,0.045))
    var accent := _mat(Color(0.02,0.78,0.98) if role != "customer" else Color(0.92,0.68,0.24))
    var scale_factor := randf_range(0.91, 1.09)
    root.scale = Vector3.ONE * scale_factor

    # Torso: broad shoulders over a tapered waist, with a visible clothing layer.
    var torso := _mesh(root, CapsuleMesh.new(), Vector3(0,1.08,0), shirt)
    torso.mesh.radius = 0.32
    torso.mesh.height = 0.92
    torso.scale = Vector3(1.0,1.0,0.78)
    var waist := _mesh(root, BoxMesh.new(), Vector3(0,0.72,0), pants)
    waist.mesh.size = Vector3(0.43,0.25,0.30)
    var neck := _mesh(root, CylinderMesh.new(), Vector3(0,1.57,0), skin)
    neck.mesh.top_radius = 0.105
    neck.mesh.bottom_radius = 0.12
    neck.mesh.height = 0.20

    # Oversized stylized head with cheeks, ears, nose and readable expression.
    var head := _mesh(root, SphereMesh.new(), Vector3(0,1.88,0), skin)
    head.scale = Vector3(0.285,0.335,0.255)
    for side in [-1.0,1.0]:
        var ear := _mesh(root, SphereMesh.new(), Vector3(side*0.278,1.87,0), skin)
        ear.scale = Vector3(0.075,0.105,0.065)
        var eye := _mesh(root, SphereMesh.new(), Vector3(side*0.105,1.91,-0.225), white)
        eye.scale = Vector3(0.052,0.067,0.025)
        var pupil := _mesh(root, SphereMesh.new(), Vector3(side*0.105,1.91,-0.249), dark)
        pupil.scale = Vector3(0.025,0.037,0.014)
        var brow := _mesh(root, CapsuleMesh.new(), Vector3(side*0.105,2.005,-0.225), hair)
        brow.mesh.radius = 0.018
        brow.mesh.height = 0.10
        brow.rotation.z = side * -0.12
    var nose := _mesh(root, SphereMesh.new(), Vector3(0,1.82,-0.27), skin)
    nose.scale = Vector3(0.045,0.055,0.045)
    var mouth := _mesh(root, CapsuleMesh.new(), Vector3(0,1.735,-0.245), dark)
    mouth.mesh.radius = 0.012
    mouth.mesh.height = 0.075
    mouth.rotation_degrees.z = 90

    # Hair silhouette varies: cap plus side locks or a swept fringe.
    var hair_style := randi_range(0,2)
    var cap := _mesh(root, SphereMesh.new(), Vector3(0,2.075,0.015), hair)
    cap.scale = Vector3(0.29,0.16,0.265)
    if hair_style == 0:
        var fringe := _mesh(root, SphereMesh.new(), Vector3(-0.07,2.015,-0.19), hair)
        fringe.scale = Vector3(0.22,0.085,0.09)
    elif hair_style == 1:
        for side in [-1.0,1.0]:
            var lock := _mesh(root, SphereMesh.new(), Vector3(side*0.22,1.99,0.015), hair)
            lock.scale = Vector3(0.09,0.19,0.12)
    else:
        cap.scale.y = 0.10
        for i in range(3):
            var spike := _mesh(root, SphereMesh.new(), Vector3(-0.15 + float(i)*0.15,2.17,0.0), hair)
            spike.scale = Vector3(0.10,0.12,0.11)

    # Articulated shoulder and hip pivots; the walk animator swings them naturally.
    var animator := WalkAnimator.new()
    root.add_child(animator)
    animator.left_arm = _limb(root, Vector3(-0.37,1.39,0), 0.105,0.60, shirt)
    animator.right_arm = _limb(root, Vector3(0.37,1.39,0), 0.105,0.60, shirt)
    animator.left_leg = _limb(root, Vector3(-0.16,0.52,0), 0.13,0.72, pants)
    animator.right_leg = _limb(root, Vector3(0.16,0.52,0), 0.13,0.72, pants)
    for arm in [animator.left_arm,animator.right_arm]:
        var hand := _mesh(arm, SphereMesh.new(), Vector3(0,-0.36,-0.015), skin)
        hand.scale = Vector3(0.105,0.12,0.095)
    for side in [-1.0,1.0]:
        var shoe := _mesh(root, BoxMesh.new(), Vector3(side*0.16,0.105,-0.09), shoe_mat)
        shoe.mesh.size = Vector3(0.25,0.16,0.39)
        var sole := _mesh(root, BoxMesh.new(), Vector3(side*0.16,0.045,-0.09), dark)
        sole.mesh.size = Vector3(0.255,0.045,0.40)

    # Shirt details and role identity.
    var collar := _mesh(root, BoxMesh.new(), Vector3(0,1.49,-0.205), white)
    collar.mesh.size = Vector3(0.19,0.07,0.035)
    if role == "seller" or role == "player":
        var apron := _mesh(root, BoxMesh.new(), Vector3(0,1.05,-0.245), _mat(Color(0.025,0.12,0.18,0.92)))
        apron.mesh.size = Vector3(0.38,0.55,0.035)
        var badge := _mesh(root, BoxMesh.new(), Vector3(0.18,1.24,-0.275), white)
        badge.mesh.size = Vector3(0.15,0.11,0.025)
        var badge_line := _mesh(root, BoxMesh.new(), Vector3(0.18,1.25,-0.292), accent)
        badge_line.mesh.size = Vector3(0.09,0.025,0.012)
        var radio := _mesh(root, BoxMesh.new(), Vector3(-0.22,1.28,-0.255), dark)
        radio.mesh.size = Vector3(0.075,0.12,0.045)
    else:
        # Customers get individual accessories so the crowd is not a row of clones.
        if randi_range(0,3) == 0:
            for side in [-1.0,1.0]:
                var lens := _mesh(root, SphereMesh.new(), Vector3(side*0.105,1.91,-0.255), _mat(Color(0.12,0.18,0.22,0.72)))
                lens.scale = Vector3(0.07,0.055,0.018)
            var bridge := _mesh(root, BoxMesh.new(), Vector3(0,1.91,-0.263), dark)
            bridge.mesh.size = Vector3(0.08,0.018,0.018)

static func _limb(root: Node3D, pos: Vector3, radius: float, height: float, material: Material) -> Node3D:
    var pivot := Node3D.new()
    pivot.position = pos
    root.add_child(pivot)
    var part := _mesh(pivot, CapsuleMesh.new(), Vector3(0,-height*0.34,0), material)
    part.mesh.radius = radius
    part.mesh.height = height
    return pivot

static func _mesh(root: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    root.add_child(node)
    return node

static func _mat(color: Color) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.72
    return material
