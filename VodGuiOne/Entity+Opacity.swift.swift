//
//  Entity+Opacity.swift.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 06/03/2024.
//

import Foundation
import RealityKit
import Combine
//https://gist.githubusercontent.com/drewolbrich/1e9d3da074c8a1d5ca93721124b97596/raw/d5c0118286e285fa428a83d04060c1719e83a854/Entity+Opacity.swift
private var playbackCompletedSubscriptions: Set<AnyCancellable> = .init()

extension Entity {
    
    /// The opacity value applied to the entity and its descendants.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    var opacity: Float {
        get {
            return components[OpacityComponent.self]?.opacity ?? 1
        }
        set {
            if !components.has(OpacityComponent.self) {
                components[OpacityComponent.self] = OpacityComponent(opacity: newValue)
            } else {
                components[OpacityComponent.self]?.opacity = newValue
            }
        }
    }
    
    /// Sets the opacity value applied to the entity and its descendants with optional animation.
    ///
    /// `OpacityComponent` is assigned to the entity if it doesn't already exist.
    func setOpacity(_ opacity: Float, animated: Bool, duration: TimeInterval = 0.2, delay: TimeInterval = 0, completion: (() -> Void)? = nil) {
        guard animated else {
            self.opacity = opacity
            return
        }
        
        if !components.has(OpacityComponent.self) {
            components[OpacityComponent.self] = OpacityComponent(opacity: 1)
        }

        let animation = FromToByAnimation(name: "Entity/setOpacity", to: opacity, duration: duration, timing: .linear, isAdditive: false, bindTarget: .opacity, delay: delay)
        
        do {
            let animationResource: AnimationResource = try .generate(with: animation)
            let animationPlaybackController = playAnimation(animationResource)
            
            if completion != nil {
                scene?.publisher(for: AnimationEvents.PlaybackCompleted.self)
                    .filter { $0.playbackController == animationPlaybackController }
                    .sink(receiveValue: { event in
                        completion?()
                    }).store(in: &playbackCompletedSubscriptions)
            }
        } catch {
            assertionFailure("Could not generate animation: \(error.localizedDescription)")
        }
    }
    
//    func relocate(){}
//    func shift(){}
}
