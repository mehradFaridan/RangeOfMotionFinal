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
    
    //@State var counter1 = 0
    
    var body: some View {
        VStack {

            //Text("Start Tracking your Hand")
            
            Text("Current Value: \(dataModel.dataValue)")
            
            LineChartView().frame(width: 1000, height: 400)
            
            ToggleImmersiveSpaceButton()
            
//            Button("Update Value"){
//                
//            dataModel.updateValue(newValue: 0)
//            
//            counter1 += 1
//                
//            }
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
        .environmentObject(DataModel())  // Provide DataModel for preview
}
