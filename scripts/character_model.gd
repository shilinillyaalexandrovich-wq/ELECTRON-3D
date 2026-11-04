extends RefCounted

# Общая стилизация персонажей ELECTRON: крупная голова, выразительное лицо,
# аккуратная форма, бейдж и контрастная обувь. Модель собирается из 3D-примитивов,
# поэтому не требует внешних платных ассетов и работает в Android-сборке.

static func add_human(root: Node3D, shirt_color: Color, skin_color: Color, hair_color: Color) -> void:
    var shirt := _mat(shirt_color)
    var skin := _mat(skin_color)
    var hair := _mat(hair_color)
    var pants := _mat(Color(0.075, 0.09, 0.13))
    var shoes := _mat(Color(0.92, 0.94, 0.97))
    var dark := _mat(Color(0.035, 0.045, 0.06))
    var badge_mat := _mat(Color(0.94, 0.97, 1.0))
    var accent := _mat(Color(0.04, 0.72, 0.88))

    # Тело и шея
    var torso := _mesh(root, CapsuleMesh.new(), Vector3(0, 1.02, 0), shirt)
    torso.mesh.radius = 0.30
    torso.mesh.height = 0.92
    torso.scale.z = 0.82
    _mesh(root, SphereMesh.new(), Vector3(0, 1.52, 0), skin).scale = Vector3(0.105, 0.13, 0.10)

    # Голова с мультяшными пропорциями
    var head := _mesh(root, SphereMesh.new(), Vector3(0, 1.82, 0), skin)
    head.scale = Vector3(0.255, 0.31, 0.235)
    var hair_cap := _mesh(root, SphereMesh.new(), Vector3(0, 2.00, 0.025), hair)
    hair_cap.scale = Vector3(0.26, 0.17, 0.24)
    var fringe := _mesh(root, SphereMesh.new(), Vector3(0, 1.94, -0.17), hair)
    fringe.scale = Vector3(0.19, 0.085, 0.075)

    # Лицо ориентировано в сторону -Z
    for side in [-1.0, 1.0]:
        var ear := _mesh(root, SphereMesh.new(), Vector3(side * 0.25, 1.81, 0), skin)
        ear.scale = Vector3(0.055, 0.085, 0.065)
        var eye_white := _mesh(root, SphereMesh.new(), Vector3(side * 0.09, 1.85, -0.207), badge_mat)
        eye_white.scale = Vector3(0.043, 0.057, 0.022)
        var pupil := _mesh(root, SphereMesh.new(), Vector3(side * 0.09, 1.85, -0.228), dark)
        pupil.scale = Vector3(0.021, 0.032, 0.012)
        var brow := _mesh(root, BoxMesh.new(), Vector3(side * 0.09, 1.93, -0.207), hair)
        brow.mesh.size = Vector3(0.075, 0.018, 0.025)
        brow.rotation.z = side * -0.08

    var nose := _mesh(root, SphereMesh.new(), Vector3(0, 1.79, -0.238), skin)
    nose.scale = Vector3(0.035, 0.045, 0.035)
    var smile := _mesh(root, BoxMesh.new(), Vector3(0, 1.70, -0.218), dark)
    smile.mesh.size = Vector3(0.085, 0.012, 0.018)

    # Руки, ладони, ноги и кроссовки
    for side in [-1.0, 1.0]:
        var arm := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.39, 0.99, 0), shirt)
        arm.mesh.radius = 0.105
        arm.mesh.height = 0.68
        arm.rotation.z = side * -0.16
        var hand := _mesh(root, SphereMesh.new(), Vector3(side * 0.42, 0.62, -0.005), skin)
        hand.scale = Vector3(0.09, 0.10, 0.085)
        var leg := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.16, 0.40, 0), pants)
        leg.mesh.radius = 0.12
        leg.mesh.height = 0.72
        var shoe := _mesh(root, SphereMesh.new(), Vector3(side * 0.16, 0.105, -0.075), shoes)
        shoe.scale = Vector3(0.16, 0.085, 0.25)
        var sole := _mesh(root, SphereMesh.new(), Vector3(side * 0.16, 0.065, -0.07), dark)
        sole.scale = Vector3(0.16, 0.035, 0.25)

    # Фирменные детали формы ELECTRON
    var collar := _mesh(root, BoxMesh.new(), Vector3(0, 1.43, -0.245), badge_mat)
    collar.mesh.size = Vector3(0.19, 0.045, 0.035)
    var badge := _mesh(root, BoxMesh.new(), Vector3(0.19, 1.20, -0.255), badge_mat)
    badge.mesh.size = Vector3(0.16, 0.105, 0.025)
    var badge_mark := _mesh(root, BoxMesh.new(), Vector3(0.19, 1.205, -0.272), accent)
    badge_mark.mesh.size = Vector3(0.095, 0.025, 0.012)
    var belt := _mesh(root, BoxMesh.new(), Vector3(0, 0.68, -0.01), dark)
    belt.mesh.size = Vector3(0.48, 0.055, 0.42)

static func _mesh(root: Node3D, mesh: Mesh, pos: Vector3, material: Material) -> MeshInstance3D:
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = material
    root.add_child(node)
    return node

static func _mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.roughness = 0.78
    return m
