//
//  ContentView.swift
//  VodGuiOne
//
//  Created by KIRILL SIMAGIN on 20/02/2024.
//

import SwiftUI
import RealityKit
import RealityKitContent
import OSLog
struct ContentView: View {

    @State private var showImmersiveSpace = false
    @State private var immersiveSpaceIsShown = false
    @State private var selectedScreen: XRRouter = .wall
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace

    var body: some View {
        
        VStack {
            VStack {
                Button("Close Immersive Space") {
                    Task {
                        await dismissImmersiveSpace()
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                }
            }
            .opacity(immersiveSpaceIsShown ? 1 : 0)

            Text("Hello, world!")

            HStack {
                Button("wall") {
                    selectedScreen = .wall
                    showImmersiveSpace = true
                }
                Button("orbit") {
                    selectedScreen = .sphere
                    showImmersiveSpace = true
                }
                Button("curved") {
                    selectedScreen = .curved
                    showImmersiveSpace = true
                }
            }
            .opacity(immersiveSpaceIsShown ? 0 : 1)
        }
        .onChange(of: showImmersiveSpace) { _, newValue in
            Task {
                print("***current selected screen is \(selectedScreen)")
                if newValue {
                    switch await openImmersiveSpace(id: selectedScreen.rawValue) {
                    case .opened:
                        immersiveSpaceIsShown = true
                    case .error, .userCancelled:
                        fallthrough
                    @unknown default:
                        immersiveSpaceIsShown = false
                        showImmersiveSpace = false
                    }
                } else if immersiveSpaceIsShown {
                    await dismissImmersiveSpace()
                    immersiveSpaceIsShown = false
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
