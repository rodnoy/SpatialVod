//
//  PosterComponent.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 01/03/2024.
//

import Foundation
import RealityKit
// Компонент для хранения исходного состояния постера
class PosterComponent: Component {
    var originalTransform: Transform = .identity
    var isEnlarged: Bool = false
}
