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
            // Add the initial RealityKit content
            let material = SimpleMaterial(color: .red, isMetallic: false)
            self.sphere = ModelEntity(mesh: .generateSphere(radius: 0.05), materials: [material])
            self.box = ModelEntity(mesh: .generateBox(size: 0.05), materials: [material])

            //content.add(box)
            //content.add(sphere)
            if let attachment = attachment.entity(for: "Set Max") {
                attachment.position = [0.5,1,0]
                content.add(attachment)
            }
            if let attachment = attachment.entity(for: "m") {
                attachment.position = [0,1,0]
                content.add(attachment)
            }
            if let attachment = attachment.entity(for: "Set Min") {
                attachment.position = [0.8,1,0]
                content.add(attachment)
            }
        } update: { content, attachment in
            Task {
                for await anchorUpdate in handTracking.anchorUpdates {
                    let anchor = anchorUpdate.anchor
                    switch anchor.chirality {
                    case .left:
                        if let handSkeleton = anchor.handSkeleton {
                            let palm = handSkeleton.joint(.middleFingerKnuckle)
                            let originFromWrist = anchor.originFromAnchorTransform
                            let wristFromPalm = palm.anchorFromJointTransform
                            let originFromTip = originFromWrist * wristFromPalm
                            sphere.setTransformMatrix(originFromTip, relativeTo: nil)
                        
                            // Update the latest Y position
                            let yPos = Float(originFromTip.columns.3.y)
                            print("Right Hand Y Pos: ", yPos)
                            self.latestYPos = yPos


                        }
                    case .right:
                        if let handSkeleton = anchor.handSkeleton {
                            let palm = handSkeleton.joint(.middleFingerKnuckle)
                            let originFromWrist = anchor.originFromAnchorTransform
                            let wristFromPalm = palm.anchorFromJointTransform
                            let originFromTip = originFromWrist * wristFromPalm
                            box.setTransformMatrix(originFromTip, relativeTo: nil)
                            
//                            // Get the Y position and update DataModel
//                            let yPos = originFromTip.columns.3.y
//                            print("Right Hand Y Pos: ", yPos)
//                            dataModel.updateValue(newValue: yPos)
//                            
//                            DispatchQueue.main.async{
//                                
//                                dataModel.updateValue(newValue: yPos)
//                                
//                            }
                            
//                            // Update the latest Y position
//                            let yPos = Float(originFromTip.columns.3.y)
//                            print("Right Hand Y Pos: ", yPos)
//                            self.latestYPos = yPos
                            
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
                        //
                    } label: {
                        Text(handButton.title)
                        Image(systemName: handButton.image ?? "")
                    }
                    .tint(handButton.color)

                })
            }

            Attachment(id: "m") {
                Button {
                    //
                } label: {
                    Text("klejwjkl")
                        .font(.extraLargeTitle)
                }
                .tint(.green)


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
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
        .environment(AppModel())
        .environmentObject(DataModel())  // Provide DataModel for preview
}
