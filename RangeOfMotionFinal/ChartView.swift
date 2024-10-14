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

enum RepState {
    case Downward
    case Upward
    case Idle
}

class DataModel: ObservableObject {
    @Published private var ringBuffer = RingBuffer<Float>(size: 100)  // Adjust size as needed

    @Published var minY: Float? = nil
    @Published var maxY: Float? = nil
    @Published var repCount = 0
    @Published var repState: RepState = .Idle
    @Published var lastYPos: Float = 0.0

    var dataPoints: [Float] {
        return ringBuffer.toArray()
    }

    var dataValue: Float {
        return dataPoints.last ?? 0.0
    }

    func updateValue(newValue: Float) {
        DispatchQueue.main.async {
            self.ringBuffer.write(newValue)
            self.determineRepState() // Check rep state after each new Y value
            print(self.repCount)
        }
    }

    func determineRepState() {

        let movementThreshold: Float = 0.05

        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let point1 = self.dataValue
            let movementDifference = abs(point1 - self.lastYPos)

            guard movementDifference > movementThreshold else {
                return
            }
            guard let minY = self.minY, let maxY = self.maxY else {
                return print("MinY or MaxY nil")
            }

            if point1 > self.lastYPos {
                if point1 >= (maxY - 0.02) && self.repState == .Downward {
                    // Full upward motion completed
                    self.repCount += 1
                    print("Full rep completed!")
                    self.repState = .Idle
                } else {
                    self.repState = .Upward
                    print("Moving Upward")
                }
            } else if point1 < self.lastYPos {
                if point1 <= (minY + 0.02) {
                    // Downward motion started
                    self.repState = .Downward
                    print("Moving Downward")
                }
            }
            // Update lastYPosition only when movement is substantial
            self.lastYPos = point1

            // TODO: Implement Edge cases. What if user stops mid rep??
            if self.repState != .Idle && movementDifference <= movementThreshold {
                print("Movement stopped mid-rep")
                self.repState = .Idle
            }
        }
    }
}

struct LineChartView: View {
    @EnvironmentObject var dataModel: DataModel
    var minY: Float?
    var maxY: Float?

    var body: some View {
        Chart {
            ForEach(Array(dataModel.dataPoints.enumerated()), id: \.offset) { index, value in
                let clampedValue = clampValue(value)
                LineMark(
                    x: .value("Time", Double(index) * 0.1),
                    y: .value("Y Position", clampedValue)
                )
                .interpolationMethod(.linear)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: .stride(by: 1.0)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    let timeValue = value.as(Double.self) ?? 0.0
                    Text(String(format: "%.0f s", timeValue))
                }
            }
        }
        .chartYAxis {
            AxisMarks()
        }
        .conditionalChartYScale(domain: yAxisDomain())
        .padding()
        .frame(maxWidth: .infinity)
        .animation(nil, value: dataModel.dataPoints)
    }

    private func yAxisDomain() -> ClosedRange<Double>? {
        // If both minY and maxY are nil, return nil to use default scaling
        guard minY != nil || maxY != nil else { return nil }

        let dataMin = dataModel.dataPoints.min() ?? 0
        let dataMax = dataModel.dataPoints.max() ?? 1

        let minValue = Double(minY ?? dataMin)
        let maxValue = Double(maxY ?? dataMax)

        // Ensure minValue and maxValue are not equal
        if minValue == maxValue {
            let adjustment = 0.1
            return (minValue - adjustment)...(maxValue + adjustment)
        } else {
            return minValue...maxValue
        }
    }

    private func clampValue(_ value: Float) -> Float {
        var clampedValue = value
        if let minY = minY, clampedValue < minY {
            clampedValue = minY
        }
        if let maxY = maxY, clampedValue > maxY {
            clampedValue = maxY
        }
        return clampedValue
    }

}

extension View {
    @ViewBuilder
    func conditionalChartYScale(domain: ClosedRange<Double>?) -> some View {
        if let domain = domain {
            self.chartYScale(domain: domain)
        } else {
            self
        }
    }
}


