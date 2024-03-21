//
//  RealityKitHelpers.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 01/03/2024.
//

import Foundation
import RealityKit
import Combine
typealias EntitySize = SIMD3<Float>
extension Entity {
    var modelMesh: MeshResource? {
        return (self.components[ModelComponent.self])?.mesh
    }
}
extension Entity {
    var visualSize: EntitySize {
        let box = self.visualBounds(relativeTo: nil)
        let width = box.max.x - box.min.x
        let height = box.max.y - box.min.y
        let depth = box.max.z - box.min.z
        return [width, height, depth]
    }
}
//https://stackoverflow.com/a/76845322
extension ModelEntity {
    func size() -> EntitySize {
        guard let mesh = self.model?.mesh else {
            return .zero
        }

        let width = mesh.bounds.max.x - mesh.bounds.min.x
        let height = mesh.bounds.max.y - mesh.bounds.min.y
        let depth = mesh.bounds.max.z - mesh.bounds.min.z
        return [width, height, depth]
    }
}
extension MeshResource {
    var size: EntitySize {
        let width = bounds.max.x - bounds.min.x
        let height = bounds.max.y - bounds.min.y
        let depth = bounds.max.z - bounds.min.z
        return [width, height, depth]
    }
}
extension BoundingBox {
    var size: EntitySize {
        let width = max.x - min.x
        let height = max.y - min.y
        let depth = max.z - min.z
        return [width, height, depth]
    }
}

extension SIMD3 where Scalar == Float {
    static let xAxis = SIMD3<Float>(1, 0, 0)
    static let yAxis = SIMD3<Float>(0, 1, 0)
    static let zAxis = SIMD3<Float>(0, 0, 1)
}

//A wrapper around iOS Entity/loadAsync(named:in:) and visionOS Entity(named:in:) async that works on both platforms
// https://gist.github.com/drewolbrich/946eae4af57938155456f5ca947e850a
extension TextureResource {
    
    // The RealityKit visionOS `TextureResource(named:in:options:) async` initializer
    // isn't available in iOS 17, so we implement our own replacement on iOS and wrap
    // both implementations in `TextureResource/loadFileAsync(named:in:options:)`.
    
#if os(visionOS)
    
    /// Loads a texture resource from a file in a bundle asynchronously.
    ///
    /// Unlike `TextureResource(named:in:options:) async` or
    /// `TextureResource.loadAsync(named:in:options:)`, this method  works on both iOS
    /// and visionOS.
    static func loadFileAsync(named name: String, in bundle: Bundle? = nil, options: TextureResource.CreateOptions = .init(semantic: nil)) async throws -> TextureResource {
        return try await TextureResource(named: name, in: bundle, options: options)
    }
    
#else // !os(visionOS)
    
    /// Loads a texture resource from a file in a bundle asynchronously.
    ///
    /// Unlike `TextureResource(named:in:options:) async` or
    /// `TextureResource.loadAsync(named:in:options:)`, this method  works on both iOS
    /// and visionOS.
    static func loadFileAsync(named name: String, in bundle: Bundle? = nil, options: TextureResource.CreateOptions = .init(semantic: nil)) async throws -> TextureResource {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = TextureResource.loadAsync(named: name, in: bundle, options: options).sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
                cancellable?.cancel()
            }, receiveValue: { entity in
                continuation.resume(returning: entity)
                cancellable?.cancel()
            })
        }
    }
    
#endif // !os(visionOS)
    
}
//extension TextureResource {
//    static func loadAsync(named name: String) async throws -> TextureResource {
//        return try await withCheckedThrowingContinuation { continuation in
//            loadAsync(named: name) { result in
//                switch result {
//                case .success(let textureResource):
//                    continuation.resume(returning: textureResource)
//                case .failure(let error):
//                    continuation.resume(throwing: error)
//                }
//            }
//        }
//    }
//}
/*
 usage
 
 func loadTexture() async {
     do {
         let texture = try await TextureResource.loadAsync(named: "yourTextureName")
         // Используйте texture здесь
     } catch {
         print("Ошибка при загрузке текстуры: \(error)")
     }
 }
 
 */
extension Entity {
    /// Функция для изменения видимости текущей entity и всех её дочерних entities.
    /// - Parameter isVisible: Булево значение, определяющее, должна ли entity быть видимой.
    func setVisibility(isVisible: Bool) {
        self.isEnabled = isVisible // Изменяем видимость самой entity
        
        // Рекурсивно изменяем видимость всех дочерних entities
        self.children.forEach { child in
            child.setVisibility(isVisible: isVisible)
        }
    }
}

extension Entity {
    
    /// Функция для изменения альфа-значения (прозрачности) моделей сущностей через OpacityComponent.
    /// - Parameter alpha: Значение альфа от 0.0 (полностью прозрачный) до 1.0 (полностью непрозрачный).
    func setModelAlpha(alpha: Float) {
        // Устанавливаем OpacityComponent с заданным значением альфа для текущей сущности
        self.components[OpacityComponent.self] = .init(opacity: alpha)
        
        // Применяем изменение альфа-значения ко всем дочерним entities
        self.children.forEach { child in
            child.setModelAlpha(alpha: alpha)
        }
    }
}
