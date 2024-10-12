//
//  ImmersiveView.swift
//  RangeOfMotionFinal
//
//  Created by Mehrad Faridan on 2024-10-09.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit
import Combine

struct ImmersiveView: View {
    
    @EnvironmentObject var dataModel: DataModel  // Access shared DataModel
    @State private var latestYPos: Float = 0.0
    @State private var timerCancellable: AnyCancellable?
    private var attachmentModel = AttachmentModel()


    let handTracking = HandTrackingProvider()
    let session = ARKitSession()
    @State var box = ModelEntity()
    @State var sphere = ModelEntity()

    var body: some View {
        RealityView { content, attachment in


            if let attachment = attachment.entity(for: "Set Max") {
                content.add(attachment)
            }
            if let attachment = attachment.entity(for: "Set Min") {
                content.add(attachment)
            }
        } update: { content, attachment in
            Task {
                for await anchorUpdate in handTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    switch anchor.chirality {
                    case .left:


                        let foreArmWorldPos1 = attachButtonToHand(anchor: anchor, xOffset: 0.05)
                        let foreArmWorldPos2 = attachButtonToHand(anchor: anchor, xOffset: 0.1)

                        //FIXME: FIX how this is handled. approperitaly handle a nil value
                        let yPos = Float(foreArmWorldPos1?.columns.3.y ?? 6)

                        self.latestYPos = yPos

                        if let attachment = attachment.entity(for: "Set Max") {
                            attachment.setTransformMatrix(foreArmWorldPos1!, relativeTo: nil)
                        }
                        if let attachment = attachment.entity(for: "Set Min") {
                            attachment.setTransformMatrix(foreArmWorldPos2!, relativeTo: nil)
                        }


                    case .right:
                        if let handSkeleton = anchor.handSkeleton {
                            // do something
                        }
                    @unknown default:
                        print("Unknown error")
                    }
                }
            }
        } attachments: {
            ForEach(attachmentModel.handButtonArray) { handButton in
                Attachment(id: handButton.title, {
                    Button {
                        if handButton.title == "Set Min" {
                            dataModel.minY = dataModel.dataValue
                            print("Set Min Y to \(dataModel.minY!)")
                        } else if handButton.title == "Set Max" {
                            dataModel.maxY = dataModel.dataValue
                            print("Set Max Y to \(dataModel.maxY!)")
                        }
                    } label: {
                        Text(handButton.title)
                        Image(systemName: handButton.image ?? "")
                    }
                    .tint(handButton.color)

                })
            }
        }

        .task {
            await runHandTrackingSession()
        }
        .onAppear{
            timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink{ _ in
                    dataModel.updateValue(newValue: latestYPos)
                }
        }
        .onDisappear{
            timerCancellable?.cancel()
        }
    }

    func runHandTrackingSession() async {
        do {
            if HandTrackingProvider.isSupported {
                try await session.run([handTracking])
                print("Hand tracking initializing in progress.")
            } else {
                print("Hand tracking is not supported.")
            }
        } catch {
            print("Error during initialization of hand tracking: \(error)")
        }
    }


    func convertToWorldPosition(anchor: HandAnchor, joint: HandSkeleton.JointName) -> float4x4? {
        guard let handSkeleton = anchor.handSkeleton else { return nil }
        let joint = handSkeleton.joint(joint)

        // get pos of palm relative to origin
        let originFromWrist = anchor.originFromAnchorTransform
        let wristFromPalm = joint.anchorFromJointTransform
        let originFromTip = originFromWrist * wristFromPalm

        return originFromTip

    }

    func attachButtonToHand(anchor: HandAnchor, xOffset: Float) -> float4x4? {
        let foreArmWorldPos = convertToWorldPosition(anchor: anchor, joint: .forearmWrist)

        let offset: Float = xOffset
        var adjustedTransform = foreArmWorldPos
        adjustedTransform?.columns.3.z += offset
        adjustedTransform?.columns.3.x += 0.15

        // Create a rotation matrix for 45 degrees around the Y-axis
        let angleInRadians: Float = (.pi) / 2  // 45 degrees in radians
        let rotationY = simd_float4x4(simd_quatf(angle: angleInRadians, axis: [0, 1, 0])) // Rotation around Y-axis

        let angleInRadiansX: Float = -(.pi) / 2
        let rotationX = simd_float4x4(simd_quatf(angle: angleInRadiansX, axis: [1, 0, 0])) // Rotation around X-axis

        let intermediateTransform = matrix_multiply(adjustedTransform!, rotationY) // Apply Y-axis rotation first
        let finalTransform = matrix_multiply(intermediateTransform, rotationX)    // Apply X-axis rotation second

        return finalTransform
    }

}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(DataModel())  // Provide DataModel for preview
}
