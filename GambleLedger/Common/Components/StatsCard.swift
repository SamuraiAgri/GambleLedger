// GambleLedger/Common/Components/StatsCard.swift
import SwiftUI

struct StatCardData: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: StatTrend
    let trendValue: String?
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        trend: StatTrend = .neutral,
        trendValue: String? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
        self.trendValue = trendValue
    }
}

enum StatTrend {
    case up
    case down
    case neutral
    
    var icon: String {
        switch self {
        case .up:
            return "arrow.up"
        case .down:
            return "arrow.down"
        case .neutral:
            return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up:
            return .accentSuccess
        case .down:
            return .accentDanger
        case .neutral:
            return .gray
        }
    }
}

struct StatsCard: View {
    let data: StatCardData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: data.icon)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .padding(6)
                    .background(data.color)
                    .cornerRadius(8)
                
                Text(data.title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            Text(data.value)
                .font(.title3)
                .fontWeight(.bold)
            
            if let trendValue = data.trendValue {
                HStack {
                    Image(systemName: data.trend.icon)
                        .font(.caption)
                        .foregroundColor(data.trend.color)
                    
                    Text(trendValue)
                        .font(.caption)
                        .foregroundColor(data.trend.color)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

#Preview {
    VStack(spacing: 20) {
        StatsCard(
            data: StatCardData(
                title: "総利益",
                value: "¥52,500",
                icon: "chart.line.uptrend.xyaxis",
                color: .accentSuccess,
                trend: .up,
                trendValue: "前月比 +15%"
            )
        )
        
        StatsCard(
            data: StatCardData(
                title: "的中率",
                value: "42.5%",
                icon: "checkmark.circle",
                color: .primaryColor,
                trend: .down,
                trendValue: "前月比 -3.2%"
            )
        )
        
        StatsCard(
            data: StatCardData(
                title: "ROI",
                value: "108.2%",
                icon: "percent",
                color: .secondaryColor,
                trend: .neutral,
                trendValue: "前月比 ±0%"
            )
        )
    }
    .padding()
}
