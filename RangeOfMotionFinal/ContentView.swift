//
//  ContentView.swift
//  RangeOfMotionFinal
//
//  Created by Mehrad Faridan on 2024-10-09.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {

    var body: some View {
        VStack {

            Text("Hello, world!")

            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
