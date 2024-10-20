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

    @EnvironmentObject var dataModel: DataModel
    @State private var latestYPos: Float = 0.0
    @State private var timerCancellable: AnyCancellable?
    @State var box = ModelEntity()
    @State var sphere = ModelEntity()
    private var attachmentModel = AttachmentModel()
    private let worldTrackingProvider = WorldTrackingProvider()
    private let handTracking = HandTrackingProvider()
    private let session = ARKitSession()

    var body: some View {
        RealityView { content, attachment in

            if let attachment = attachment.entity(for: "Set Max") {
                content.add(attachment)
            }
            if let attachment = attachment.entity(for: "Set Min") {
                content.add(attachment)
            }

            if let chart = attachment.entity(for: "chart") {
                content.add(chart)
            }
        } update: { content, attachment in
            Task {
                for await anchorUpdate in handTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    switch anchor.chirality {
                    case .left:

                        let foreArmWorldPos1 = attachButtonToHand(anchor: anchor, xOffset: 0.13, yOffset: 0, zOffset: 0.1)
                        let foreArmWorldPos2 = attachButtonToHand(anchor: anchor, xOffset: 0.13, yOffset: 0, zOffset: 0.03)
                        let foreArmWorldPos3 = attachButtonToHand(anchor: anchor, xOffset: 0.1, yOffset: 0, zOffset: -0.5)
                        // Safely unwrap transformed positions
                        guard let foreArmPos1 = foreArmWorldPos1,
                              let foreArmPos2 = foreArmWorldPos2,
                              let foreArmPos3 = foreArmWorldPos3 else {
                            print("Invalid forearm positions")
                            continue
                        }

                        //FIXME: FIX how this is handled. approperitaly handle a nil value
                        let yPos = Float(foreArmWorldPos1?.columns.3.y ?? 6)

                        self.latestYPos = yPos

                        // Update attachment positions and orient them to face the head
                        if let setMaxEntity = attachment.entity(for: "Set Max") {
                            setMaxEntity.setTransformMatrix(foreArmPos1, relativeTo: nil)
                            makeEntityFaceUp(entity: setMaxEntity)
                        }
                        if let setMinEntity = attachment.entity(for: "Set Min") {
                            setMinEntity.setTransformMatrix(foreArmPos2, relativeTo: nil)
                            makeEntityFaceUp(entity: setMinEntity)
                        }
                        if let chartEntity = attachment.entity(for: "chart") {
                            chartEntity.setTransformMatrix(foreArmPos3, relativeTo: nil)
                            makeEntityFaceHead(entity: chartEntity)
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
            Attachment(id: "chart") {
                LineChartView(minY: dataModel.minY, maxY: dataModel.maxY)
                    .frame(maxWidth: 800, maxHeight: 500)
                    .padding(.horizontal)
            }

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
                try await session.run([handTracking, worldTrackingProvider])
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

    func attachButtonToHand(anchor: HandAnchor, xOffset: Float, yOffset: Float, zOffset: Float) -> float4x4? {
        let foreArmWorldPos = convertToWorldPosition(anchor: anchor, joint: .forearmWrist)

        var adjustedTransform = foreArmWorldPos
        adjustedTransform?.columns.3.z += zOffset
        adjustedTransform?.columns.3.x += xOffset
        adjustedTransform?.columns.3.y += yOffset

        // Create a rotation matrix for 45 degrees around the Y-axis
        let angleInRadians: Float = (.pi) / 2  // 45 degrees in radians
        let rotationY = simd_float4x4(simd_quatf(angle: angleInRadians, axis: [0, 1, 0])) // Rotation around Y-axis

        let angleInRadiansX: Float = -(.pi) / 2
        let rotationX = simd_float4x4(simd_quatf(angle: angleInRadiansX, axis: [1, 0, 0])) // Rotation around X-axis

        let intermediateTransform = matrix_multiply(adjustedTransform!, rotationY) // Apply Y-axis rotation first
        let finalTransform = matrix_multiply(intermediateTransform, rotationX)    // Apply X-axis rotation second

        return finalTransform
    }

    func makeEntityFaceHead(entity: Entity) {
        let currentTimestamp = CACurrentMediaTime()
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: currentTimestamp) else {
            print("Failed to retrieve device anchor.")
            return
        }
        let cameraTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
        let cameraPosition = SIMD3<Float>(cameraTransform.translation.x,
                                          cameraTransform.translation.y,
                                          cameraTransform.translation.z)
        entity.look(at: cameraPosition, from: entity.position, relativeTo: nil)
        let rotationQuaternion = simd_quatf(angle: .pi, axis: [0, 1, 0])
        entity.transform.rotation = entity.transform.rotation * rotationQuaternion
    }


    func makeEntityFaceUp(entity: Entity) {
        // Define the "up" direction (0, 1, 0) in global space
        let upDirection = SIMD3<Float>(0, -1, -1)

        // Define the position of the entity in global space
        let entityPosition = entity.position(relativeTo: nil)

        // Make the entity look up by setting it to look at a point directly above its current position
        let lookAtPosition = entityPosition + upDirection

        // Orient the entity to face straight up
        entity.look(at: lookAtPosition, from: entityPosition, relativeTo: nil)

        // If needed, apply additional rotation to control orientation along other axes
        let rotationQuaternion = simd_quatf(angle: 2 * .pi , axis: [0, 1, 0]) // Adjust axis as needed
        entity.transform.rotation = entity.transform.rotation * rotationQuaternion
    }


}



#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(DataModel())  // Provide DataModel for preview
}
