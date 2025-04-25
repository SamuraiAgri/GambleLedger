// GambleLedger/Common/Components/ChartComponents.swift
import SwiftUI
import Charts

// 利益推移グラフ
struct ProfitChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("利益推移")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("日付", item.date),
                        y: .value("利益", item.value)
                    )
                    .foregroundStyle(Color.primaryColor)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("日付", item.date),
                        y: .value("利益", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.primaryColor.opacity(0.5),
                                Color.primaryColor.opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                RuleMark(y: .value("ゼロライン", 0))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYScale(domain: .automatic(includesZero: true))
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ROI推移グラフ
struct ROIChartView: View {
    let data: [ChartDataPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ROI推移")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            Chart {
                ForEach(data) { item in
                    LineMark(
                        x: .value("日付", item.date),
                        y: .value("ROI", item.value)
                    )
                    .foregroundStyle(
                        item.value >= 0 ? Color.accentSuccess : Color.accentDanger
                    )
                }
                
                RuleMark(y: .value("ゼロライン", 0))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text("\(doubleValue, specifier: "%.1f")%")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ギャンブル種別別円グラフ
struct GambleTypePieChartView: View {
    struct PieChartData: Identifiable {
        let id = UUID()
        let type: String
        let color: Color
        let value: Double
        let percentage: Double
    }
    
    let data: [PieChartData]
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            // MARK: - iOS 16.4以降はChartsフレームワークのPieChartが使えますが、
            // ここでは互換性のためにカスタム円グラフを実装します
            ZStack {
                ForEach(0..<data.count, id: \.self) { index in
                    PieSliceView(
                        startAngle: startAngle(for: index),
                        endAngle: endAngle(for: index),
                        color: data[index].color
                    )
                }
                
                Circle()
                    .fill(Color.backgroundSecondary)
                    .frame(width: 100, height: 100)
                
                VStack {
                    Text("合計")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(totalValue, specifier: "%.0f")円")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                }
            }
            .frame(height: 200)
            
            // 凡例
            VStack(spacing: 8) {
                ForEach(data) { item in
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 12, height: 12)
                        
                        Text(item.type)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.value, specifier: "%.0f")円")
                            .font(.subheadline)
                        
                        Text("(\(item.percentage, specifier: "%.1f")%)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var totalValue: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private func startAngle(for index: Int) -> Double {
        if index == 0 { return 0 }
        
        let sumOfPreviousValues = data[0..<index].reduce(0) { $0 + $1.value }
        return (sumOfPreviousValues / totalValue) * 360
    }
    
    private func endAngle(for index: Int) -> Double {
        let sumOfValuesIncludingCurrent = data[0...index].reduce(0) { $0 + $1.value }
        return (sumOfValuesIncludingCurrent / totalValue) * 360
    }
}

// 円グラフのスライス
struct PieSliceView: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(degrees: startAngle - 90),
                    endAngle: Angle(degrees: endAngle - 90),
                    clockwise: false
                )
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// グラフ用のデータポイント
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ProfitChartView(data: [
                ChartDataPoint(date: Date().addingTimeInterval(-6*24*3600), value: -5000, label: "6日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-5*24*3600), value: -2000, label: "5日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-4*24*3600), value: 3000, label: "4日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-3*24*3600), value: 7000, label: "3日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-2*24*3600), value: 5000, label: "2日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-1*24*3600), value: 8000, label: "1日前"),
                ChartDataPoint(date: Date(), value: 10000, label: "今日")
            ])
            
            ROIChartView(data: [
                ChartDataPoint(date: Date().addingTimeInterval(-6*24*3600), value: -20, label: "6日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-5*24*3600), value: -10, label: "5日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-4*24*3600), value: 15, label: "4日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-3*24*3600), value: 25, label: "3日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-2*24*3600), value: 10, label: "2日前"),
                ChartDataPoint(date: Date().addingTimeInterval(-1*24*3600), value: 30, label: "1日前"),
                ChartDataPoint(date: Date(), value: 40, label: "今日")
            ])
            
            GambleTypePieChartView(
                data: [
                    .init(type: "競馬", color: .gambleHorse, value: 50000, percentage: 50),
                    .init(type: "競艇", color: .gambleBoat, value: 30000, percentage: 30),
                    .init(type: "競輪", color: .gambleBike, value: 10000, percentage: 10),
                    .init(type: "その他", color: .gambleOther, value: 10000, percentage: 10)
                ],
                title: "ギャンブル種別投資額"
            )
        }
        .padding()
    }
}
