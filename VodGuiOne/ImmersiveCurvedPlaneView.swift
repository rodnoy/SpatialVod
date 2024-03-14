//
//  ImmersiveCurvedPlaneView.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 22/02/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveCurvedPlaneView: View {
    var body: some View {
        RealityView { content in
            // Пример использования
//            let plane = generateCurvedPlane()
            let plane = generateCurvedPlane(width: 2.3, height: 1, curvature: 0.8)
            let normal = plane.normal(fromSphericalCoordinates: (u: 0.5, v: 0.25, radius: 1))
//            let cubes = plane.generateCubeMap(resolution: 10, normal: normal)

            // Добавить кубы в сцену
//
            content.add(plane)
//            _ = cubes.map { cube in
//                content.add(cube)
//            }
        }
    }
    
    func generateCurvedPlane() -> Entity {
        let videoWidth = 2.0
        let videoHeight = 1.0
        let diag = hypot(videoWidth, videoHeight)
        let distance = 1.8*diag/2.54
        let mesh = try! MeshResource.generateCylinderArc(radius: distance, length: videoWidth, height: videoHeight)
        let curved = ModelEntity(mesh: mesh, materials: [SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)])
        return curved
        
    }
    // Функция для генерации изогнутой плоскости
//    func generateCurvedPlane(width: Float, height: Float, curvature: Float) -> ModelEntity {
//      let vertices: [MeshVertex] = [
//        MeshVertex(position: SIMD3<Float>(-width/2, -height/2, 0), normal: SIMD3<Float>(0, 0, 1), textureCoordinate: [0, 0]),
//        MeshVertex(position: SIMD3<Float>(width/2, -height/2, 0), normal: SIMD3<Float>(0, 0, 1), textureCoordinate: [1, 0]),
//        MeshVertex(position: SIMD3<Float>(width/2, height/2, 0), normal: SIMD3<Float>(0, 0, 1), textureCoordinate: [1, 1]),
//        MeshVertex(position: SIMD3<Float>(-width/2, height/2, 0), normal: SIMD3<Float>(0, 0, 1), textureCoordinate: [0, 1]),
//      ]
//
//      let indices: [UInt16] = [
//        0, 1, 2,
//        2, 3, 0,
//      ]
//
//      // Вычислить смещения вершин по нормали
//      for i in 0..<vertices.count {
//        let vertex = vertices[i]
//        let x = vertex.position.x
//        let y = vertex.position.y
//        let offset = curvature * y * sqrt(x * x + 1)
//        vertices[i].position.z = offset
//      }
//      let mesh = Mesh(vertices: vertices, indices: indices)
//      
//      // Применить материал
//        let material = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
//      mesh.materials = [material]
//
//      return ModelEntity(mesh: mesh)
//    }
    func generateCurvedPlane(width: Float, height: Float, curvature: Float) -> ModelEntity {
        var vertices: [SIMD3<Float>] = []
        var indices: [UInt32] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []

        // Создаем вершины и UVs
        let rows = 10 // Количество строк для детализации изгиба
        let cols = 10 // Количество колонок для детализации изгиба
        for row in 0...rows {
            for col in 0...cols {
                let x = -width / 2 + Float(col) * (width / Float(cols))
                let y = -height / 2 + Float(row) * (height / Float(rows))
                let z = curvature * y * sqrt(x * x + 1) // Применяем изгиб
                vertices.append(SIMD3<Float>(x, y, z))
                
                normals.append(SIMD3<Float>(0, 0, 1)) // Нормали направлены вверх
                uvs.append(SIMD2<Float>(Float(col) / Float(cols), Float(row) / Float(rows)))
            }
        }

        // Создаем индексы для треугольников
        for row in 0..<rows {
            for col in 0..<cols {
                let topLeft = row * (cols + 1) + col
                let topRight = topLeft + 1
                let bottomLeft = (row + 1) * (cols + 1) + col
                let bottomRight = bottomLeft + 1
                
                indices.append(contentsOf: [UInt32(topLeft), UInt32(bottomLeft), UInt32(topRight)])
                indices.append(contentsOf: [UInt32(bottomLeft), UInt32(bottomRight), UInt32(topRight)])
            }
        }

        // Создаем меш
//        let mesh = MeshResource.generateCustomMesh(
//            vertices: vertices,
//            normals: normals,
//            uvs: uvs,
//            indices: indices.map { Int32($0) }
//        )

        // Создание меша
        var meshDescriptor = MeshDescriptor()
        meshDescriptor.positions = MeshBuffer(vertices)
        meshDescriptor.normals = MeshBuffer(normals)
        meshDescriptor.textureCoordinates = MeshBuffer(uvs)
        meshDescriptor.primitives = .triangles(indices)
//        let meshDescriptor = MeshDescriptor(positions: vertices, normals: [], textureCoordinates: uvs, triangleIndices: indices)
        guard let mesh = try? MeshResource.generate(from: [meshDescriptor]) else {
            fatalError("Failed to generate mesh")
        }
        
        
        // Применяем материал
        let material = SimpleMaterial(color: .white, isMetallic: false)

        // Возвращаем сущность с мешем и материалом
        return ModelEntity(mesh: mesh, materials: [material])
    }
}
extension Entity {
  func generateCubeMap(resolution: Int, normal: SIMD3<Float>) -> [Entity] {
    // Шаг между кубами
    let cubeSpacing = 1.0 / Float(resolution)

    // Получить координаты кубов
    let cubePositions = (0..<resolution).map { i in
      let x = Float(i % resolution) * cubeSpacing
      let y = Float(i / resolution) * cubeSpacing
      return SIMD3<Float>(x, y, 0)
    }

    // Создать массив кубов
    let cubes = cubePositions.map { position in
        let cube = ModelEntity(mesh: .generateBox(size: cubeSpacing),
                               materials: [SimpleMaterial(color: .green, isMetallic: false)])
      cube.position = position
        let direction = normalize(position)
//        cube.look(at: direction, from: position, relativeTo: self)
//        cube.look(at: direction, from: position, upVector: normal, relativeTo: nil)
        
        
//        cube.look(at: direction, from: normal, upVector: [0, 1, 0], relativeTo: self)
        cube.look(at: direction, from: position, relativeTo: nil)
//      cube.orientation = .look(at: normal, up: [0, 1, 0])
      return cube
    }

    return cubes
  }
}
#Preview {
    ImmersiveCurvedPlaneView()
}
