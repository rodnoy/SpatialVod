//
//  VodGuiOneApp.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 20/02/2024.
//

import SwiftUI

@main
struct VodGuiOneApp: App {
    @State private var progressiveImmersionStyle: ImmersionStyle = .progressive
    @State private var fullImmersionStyle: ImmersionStyle = .full
    @State private var mixedScreenImStyle: ImmersionStyle = .mixed
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        ImmersiveSpace(id: XRRouter.wall.rawValue) {
            ImmersiveView()
        }.immersionStyle(selection: $progressiveImmersionStyle, in: .progressive)
        
        ImmersiveSpace(id: XRRouter.sphere.rawValue) {
            ImmersiveOrbitView()
        }.immersionStyle(selection: $mixedScreenImStyle, in: .mixed)
        
        ImmersiveSpace(id: XRRouter.curved.rawValue) {
            ImmersiveCurvedPlaneView()
        }.immersionStyle(selection: $mixedScreenImStyle, in: .mixed)
    }
    init() {
        PosterComponent.registerComponent()
    }
}

