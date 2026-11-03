extends RefCounted

static func add_human(root: Node3D, shirt_color: Color, skin_color: Color, hair_color: Color) -> void:
    var shirt := _mat(shirt_color)
    var skin := _mat(skin_color)
    var hair := _mat(hair_color)
    var pants := _mat(Color(0.12, 0.14, 0.18))
    var torso := _mesh(root, CapsuleMesh.new(), Vector3(0, 1.05, 0), shirt)
    torso.mesh.radius = 0.29
    torso.mesh.height = 0.9
    torso.scale.z = 0.82
    var head := _mesh(root, SphereMesh.new(), Vector3(0, 1.83, 0), skin)
    head.scale = Vector3(0.235, 0.29, 0.22)
    var hair_mesh := _mesh(root, SphereMesh.new(), Vector3(0, 1.99, 0.015), hair)
    hair_mesh.scale = Vector3(0.245, 0.15, 0.23)
    for side in [-1.0, 1.0]:
        var arm := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.39, 0.94, 0), shirt)
        arm.mesh.radius = 0.105
        arm.mesh.height = 0.68
        arm.rotation.z = side * -0.16
        var leg := _mesh(root, CapsuleMesh.new(), Vector3(side * 0.16, 0.43, 0), pants)
        leg.mesh.radius = 0.12
        leg.mesh.height = 0.72
        var shoe := _mesh(root, SphereMesh.new(), Vector3(side * 0.16, 0.12, -0.06), pants)
        shoe.scale = Vector3(0.15, 0.08, 0.25)
        var ear := _mesh(root, SphereMesh.new(), Vector3(side * 0.23, 1.82, 0), skin)
        ear.scale = Vector3(0.05, 0.08, 0.06)
        var eye := _mesh(root, SphereMesh.new(), Vector3(side * 0.085, 1.86, -0.2), pants)
        eye.scale = Vector3(0.025, 0.035, 0.018)

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
