// GambleLedger/Views/Statistics/DetailedStatisticsView.swift
import SwiftUI

struct DetailedStatisticsView: View {
    let records: [BetDisplayModel]
    @Environment(\.dismiss) private var dismiss
    
    private var statistics: DetailedStatistics {
        DetailedStatistics.calculate(from: records)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本統計
                    SectionCard(title: "基本統計") {
                        StatRow(label: "総ベット数", value: "\(statistics.totalBets)回")
                        Divider()
                        StatRow(label: "勝ち", value: "\(statistics.wins)回", valueColor: .accentSuccess)
                        Divider()
                        StatRow(label: "負け", value: "\(statistics.losses)回", valueColor: .accentDanger)
                        Divider()
                        StatRow(
                            label: "勝率",
                            value: String(format: "%.1f%%", statistics.winRate),
                            valueColor: statistics.winRate >= 50 ? .accentSuccess : .accentDanger
                        )
                    }
                    
                    // 金額統計
                    SectionCard(title: "金額統計") {
                        StatRow(label: "総賭け金", value: formatCurrency(statistics.totalBetAmount))
                        Divider()
                        StatRow(label: "総払戻金", value: formatCurrency(statistics.totalReturnAmount))
                        Divider()
                        StatRow(
                            label: "総損益",
                            value: formatCurrency(statistics.totalProfit),
                            valueColor: statistics.totalProfit >= 0 ? .accentSuccess : .accentDanger
                        )
                        Divider()
                        StatRow(label: "平均賭け金", value: formatCurrency(statistics.averageBetAmount))
                        Divider()
                        StatRow(
                            label: "平均損益",
                            value: formatCurrency(statistics.averageProfit),
                            valueColor: statistics.averageProfit >= 0 ? .accentSuccess : .accentDanger
                        )
                    }
                    
                    // ROI統計
                    SectionCard(title: "回収率") {
                        StatRow(
                            label: "平均ROI",
                            value: String(format: "%.2f%%", statistics.averageROI),
                            valueColor: statistics.averageROI >= 0 ? .accentSuccess : .accentDanger
                        )
                    }
                    
                    // 極値統計
                    SectionCard(title: "最大値") {
                        StatRow(
                            label: "最大勝利",
                            value: formatCurrency(statistics.maxWin),
                            valueColor: .accentSuccess
                        )
                        Divider()
                        StatRow(
                            label: "最大損失",
                            value: formatCurrency(statistics.maxLoss),
                            valueColor: .accentDanger
                        )
                        Divider()
                        StatRow(
                            label: "最大連勝",
                            value: "\(statistics.winStreak)回",
                            valueColor: .accentSuccess
                        )
                        Divider()
                        StatRow(
                            label: "最大連敗",
                            value: "\(statistics.lossStreak)回",
                            valueColor: .accentDanger
                        )
                    }
                    
                    // リスク統計
                    SectionCard(title: "リスク指標") {
                        StatRow(label: "標準偏差", value: formatCurrency(statistics.standardDeviation))
                        Divider()
                        StatRow(
                            label: "シャープレシオ",
                            value: String(format: "%.2f", statistics.sharpeRatio),
                            valueColor: statistics.sharpeRatio >= 1 ? .accentSuccess : 
                                       statistics.sharpeRatio >= 0 ? .orange : .accentDanger
                        )
                    }
                    
                    // 説明文
                    VStack(alignment: .leading, spacing: 8) {
                        Text("指標の説明")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• 標準偏差: 損益のばらつきを示します。値が大きいほどリスクが高いです。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("• シャープレシオ: リスク調整後のリターンを示します。1以上が望ましいです。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("詳細統計")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.maximumFractionDigits = 0
        
        let formattedAmount = formatter.string(from: NSNumber(value: amount)) ?? "0"
        return "¥\(formattedAmount)"
    }
}

// セクションカード
private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primaryColor)
            
            VStack(spacing: 0) {
                content
            }
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }
}

// 統計行
private struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

#Preview {
    DetailedStatisticsView(records: [])
}
