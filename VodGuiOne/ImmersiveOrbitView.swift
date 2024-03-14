//
//  ImmersiveOrbitView.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 22/02/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
struct ImmersiveOrbitView: View {
    var body: some View {
        RealityView { content in
            // Создание сферы & Установка материала
            let sphere = ModelEntity(mesh: .generateSphere(radius: 0.5),
                                     materials: [SimpleMaterial(color: .red, isMetallic: true)])
            
            //
            sphere.position = [0, 1, -2]
            // Увеличение сферы в два раза
//            sphere.scale = [1, 1, 1] * 2
            
            // Генерация кубов
            let cubes = generateCubes(on: sphere, size: [0.1, 0.05, 0.025])
            //let cubes = generateCubes(on: sphere, size: [0.1, 0.05, 0.025], sphereRadius: 0.5)
            // Добавление кубов к сцене
            content.add(sphere)
            _ = cubes.map { cube in
                content.add(cube)
            }
//            content.add(cubes.map{$0})
        }
    }
    func generateCubes(on sphere: ModelEntity, size: SIMD3<Float>) -> [Entity] {
      var cubes: [ModelEntity] = []

      // Шаг по сфере
      let step = 0.1

      // Итерация по сфере
      for u in stride(from: -0.5, through: 0.5, by: step) {
        for v in stride(from: -0.5, through: 0.5, by: step) {
          // Получение позиции на сфере
            let position = sphere.position(fromSphericalCoordinates: (Float(u), Float(v), 0.5))
          // Создание куба
            let cube = ModelEntity(mesh: .generateBox(size: size),
                                   materials: [SimpleMaterial(color: .yellow, isMetallic: false)])

          // Позиционирование куба
          cube.position = position
            // Поворот куба
            let direction = normalize(position)
            cube.look(at: direction, from: position, relativeTo: sphere)

            // добавление компонент
            var input = InputTargetComponent(allowedInputTypes: .all)
            input.isEnabled = true
            cube.components.set(input)
            let collision = CollisionComponent(shapes: [.generateBox(size: [0.1,0.1,0.1])],
                                               mode: .trigger, filter: CollisionFilter(group: .default, mask: .all))
            cube.components.set(collision)
            cube.components.set(HoverEffectComponent())
            
            
          // Добавление куба к массиву
          cubes.append(cube)
        }
      }

      return cubes
    }
    func generateCubes(on sphere: ModelEntity, size: SIMD3<Float>, sphereRadius: Float) -> [Entity] {
        var cubes: [ModelEntity] = []
        let cubeCountPerRow = Int(2 * .pi * sphereRadius / (size.x * 1.1)) // Небольшой отступ между кубами
        
        for i in 0..<cubeCountPerRow {
            for j in 0..<cubeCountPerRow {
                let theta = Float(i) / Float(cubeCountPerRow) * 2 * .pi
                let phi = Float(j) / Float(cubeCountPerRow) * .pi - .pi / 2
                let x = sphereRadius * cos(phi) * cos(theta)
                let y = sphereRadius * sin(phi)
                let z = sphereRadius * cos(phi) * sin(theta)
                let position = SIMD3<Float>(x, y, z) + sphere.position
                
                let cube = ModelEntity(mesh: .generateBox(size: size),
                                       materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                cube.position = position
                let direction = normalize(position - sphere.position)
                cube.look(at: direction, from: position, relativeTo: nil)
                
                cubes.append(cube)
            }
        }
        return cubes
    }
}
extension ModelEntity {
  func position(fromSphericalCoordinates coordinates: (u: Float, v: Float, radius: Float)) -> SIMD3<Float> {
    let theta = 2 * .pi * coordinates.v
    let phi = .pi * coordinates.u - .pi / 2

      let x = coordinates.radius * sin(phi) * cos(theta)
      let y = coordinates.radius * cos(phi)
      let z = coordinates.radius * sin(phi) * sin(theta)

    return [x, y, z]
  }

}
extension Entity {
    func normal(fromSphericalCoordinates coordinates: (u: Float, v: Float, radius: Float)) -> SIMD3<Float> {
      let theta = 2 * .pi * coordinates.v
      let phi = .pi * coordinates.u - .pi / 2

        let x = coordinates.radius * sin(phi) * cos(theta)
        let y = coordinates.radius * cos(phi)
        let z = coordinates.radius * sin(phi) * sin(theta)

      return [x, y, z]
    }
}
#Preview {
    ImmersiveOrbitView()
}
