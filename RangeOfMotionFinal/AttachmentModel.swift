// AttachmentModel.swift

import Foundation
import SwiftUI
import RealityKit
import ARKit

struct HandButtons: Identifiable {
    var id = UUID()
    let title: String
    let color: Color
    let image: String?
}

@Observable
class AttachmentModel {

    var handButtonArray = [
        HandButtons(title: "Set Max", color: .blue, image: nil),
        HandButtons(title: "Set Min", color: .blue, image: nil),
        HandButtons(title: "Remove All", color: .brown, image: nil)
    ]

}

