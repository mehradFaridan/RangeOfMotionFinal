//
//  ChartView.swift
//  RangeOfMotionFinal
//
//  Created by Mehrad Faridan on 2024-10-09.
//

import Combine
import SwiftUI
import Charts


struct RingBuffer<T> {
    private var buffer: [T]
    private let size: Int
    private var index: Int = 0

    init(size: Int) {
        self.size = size
        buffer = []
        buffer.reserveCapacity(size)  // Reserve capacity for efficiency
    }

    mutating func write(_ element: T) {
        if buffer.count < size {
            buffer.append(element)
        } else {
            buffer[index % size] = element
        }
        index += 1
    }

    func toArray() -> [T] {
        let count = min(index, size)
        var result = [T]()
        for i in 0..<count {
            let idx = (index - count + i) % size
            result.append(buffer[idx])
        }
        return result
    }
}


class DataModel: ObservableObject {
    @Published private var ringBuffer = RingBuffer<Float>(size: 100)  // Adjust size as needed

    var dataPoints: [Float] {
        return ringBuffer.toArray()
    }

    var dataValue: Float {
        return dataPoints.last ?? 0.0
    }

    func updateValue(newValue: Float) {
        DispatchQueue.main.async {
            self.ringBuffer.write(newValue)
        }
    }
}


struct LineChartView: View {
    @EnvironmentObject var dataModel: DataModel

    var body: some View {
        Chart {
            ForEach(Array(dataModel.dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", Double(index) * 0.1),
                    y: .value("Y Position", value)
                )
                .interpolationMethod(.linear)
                
                PointMark(
                    x: .value("Time", Double(index) * 0.1),
                    y: .value("Y Position", value)
                )
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: 1.0)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    let timeValue = value.as(Double.self) ?? 0.0
                    Text(String(format: "%.0f", timeValue))
                }
            }
        }
        .chartYAxis {
            AxisMarks()
        }
        .padding()
        .frame(width: 400, height: 400)
        .animation(nil, value: dataModel.dataPoints)
    }
}


