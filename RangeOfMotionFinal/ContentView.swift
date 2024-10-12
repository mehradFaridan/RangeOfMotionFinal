//
//  ContentView.swift
//  RangeOfMotionFinal
//
//  Created by Mehrad Faridan on 2024-10-09.
//

import SwiftUI
import RealityKit
import RealityKitContent
import Charts


struct ContentView: View {

    @EnvironmentObject var dataModel: DataModel
    
    @State private var minY: Float?
    @State private var maxY: Float?
        
    var body: some View {
        VStack(spacing: 20) {

            //Text("Start Tracking your Hand")
            
            Text("Current Value: \(dataModel.dataValue)")
            
            LineChartView(minY: dataModel.minY, maxY: dataModel.maxY)
                .frame(maxWidth: .infinity, maxHeight: 400)
                .padding(.horizontal)
            
            ToggleImmersiveSpaceButton()
                        
            HStack(spacing: 20) {
                Button(action: {
                    minY = dataModel.dataValue
                    print("Set Min Y to \(minY!)")
                }) {
                    Text("Set Min Y")
                }
                //.buttonStyle(CustomButtonStyle())

                Button(action: {
                    maxY = dataModel.dataValue
                    print("Set Max Y to \(maxY!)")
                }) {
                    Text("Set Max Y")
                }
                //.buttonStyle(CustomButtonStyle())
            }
            .frame(height: 50)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
        .environmentObject(DataModel())  // Provide DataModel for preview
}
