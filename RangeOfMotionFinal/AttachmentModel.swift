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
        HandButtons(title: "Set Max", color: .gray, image: "bird"),
        HandButtons(title: "Set Min", color: .gray, image: "bird"),
        HandButtons(title: "Remove All", color: .brown, image: "bird")
    ]

}

