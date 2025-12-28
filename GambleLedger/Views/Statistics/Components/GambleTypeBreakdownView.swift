// GambleLedger/Views/Statistics/Components/GambleTypeBreakdownView.swift
import SwiftUI
import Charts

/// ギャンブル種別ごとの収支分析ビュー
struct GambleTypeBreakdownView: View {
    let stats: [GambleTypeStat]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("ギャンブル種別別収支")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if stats.isEmpty {
                Text("データがありません")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    ForEach(stats) { stat in
                        GambleTypeStatRow(stat: stat)
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

/// ギャンブル種別ごとの収支行
struct GambleTypeStatRow: View {
    let stat: GambleTypeStat
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // アイコンと名前
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(stat.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Text(stat.icon)
                            .font(.system(size: 20))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("\(stat.betCount)回")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 収支
                VStack(alignment: .trailing, spacing: 2) {
                    Text(stat.profit >= 0 ? "+\(stat.profit.formatted(.currency(code: "JPY")))" : stat.profit.formatted(.currency(code: "JPY")))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(stat.profit >= 0 ? .accentSuccess : .accentDanger)
                    
                    Text("ROI: \(stat.roi, specifier: "%.1f")%")
                        .font(.caption)
                        .foregroundColor(stat.roi >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            
            // 的中率バー
            HStack(spacing: 8) {
                Text("的中率")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(stat.color)
                            .frame(width: geometry.size.width * CGFloat(stat.winRate / 100), height: 6)
                    }
                }
                .frame(height: 6)
                
                Text("\(stat.winRate, specifier: "%.1f")%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundPrimary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(stat.color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    GambleTypeBreakdownView(stats: [
        GambleTypeStat(
            id: UUID(),
            name: "競馬",
            icon: "🏇",
            color: .red,
            betCount: 50,
            totalBet: 50000,
            totalReturn: 60000,
            profit: 10000,
            roi: 20.0,
            winRate: 45.0
        ),
        GambleTypeStat(
            id: UUID(),
            name: "競輪",
            icon: "🚴",
            color: .blue,
            betCount: 30,
            totalBet: 30000,
            totalReturn: 25000,
            profit: -5000,
            roi: -16.7,
            winRate: 35.0
        )
    ])
    .padding()
}
