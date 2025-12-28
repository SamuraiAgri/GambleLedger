// GambleLedger/Views/Statistics/StatisticsView.swift
import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    @State private var showDetailedStats = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択セグメント
                    periodSelector
                    
                    // 全体統計サマリー
                    TotalStatsCard(stats: viewModel.totalStats)
                        .padding(.horizontal)
                    
                    // ギャンブル種別ごとの収支分析
                    if !viewModel.gambleTypeStats.isEmpty {
                        GambleTypeBreakdownView(stats: viewModel.gambleTypeStats)
                            .padding(.horizontal)
                    }
                    
                    // グラフ部分
                    graphSections
                    
                    // ギャンブル種別統計
                    if !viewModel.gambleTypeStats.isEmpty {
                        GambleTypeStatsSection(stats: viewModel.gambleTypeStats)
                            .padding(.horizontal)
                    }
                    
                    // 統計数値カード - 実際のデータを使用
                    StatsMetricsGrid(stats: viewModel.generateAdditionalStats())
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("統計")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showDetailedStats = true
                    }) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundColor(.primaryColor)
                    }
                    .accessibilityLabel("詳細統計を表示")
                }
            }
            .overlay(loadingOverlay)
            .refreshable {
                viewModel.loadStatisticsData()
            }
            .sheet(isPresented: $showDetailedStats) {
                DetailedStatisticsView(records: viewModel.allRecords)
            }
        }
        .withErrorHandling()
    }
    
    // 期間選択部分を分割
    private var periodSelector: some View {
        Picker("期間", selection: $viewModel.selectedPeriod) {
            ForEach(StatisticsViewModel.PeriodFilter.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        .onChange(of: viewModel.selectedPeriod) { _, _ in
            viewModel.loadStatisticsData()
        }
    }
    
    // グラフ部分を分割
    private var graphSections: some View {
        VStack(spacing: 20) {
            // 利益グラフ
            if !viewModel.profitChartData.isEmpty {
                profitChart
            }
            
            // ROIグラフ
            if !viewModel.roiChartData.isEmpty {
                roiChart
            }
        }
    }
    
    // 利益グラフを分割
    private var profitChart: some View {
        let data = viewModel.profitChartData.map { point in
            ChartPointData(
                date: point.date,
                value: point.value,
                label: point.label
            )
        }
        
        return ProfitChartView(data: data)
            .padding(.horizontal)
    }
    
    // ROIグラフを分割
    private var roiChart: some View {
        let data = viewModel.roiChartData.map { point in
            ChartPointData(
                date: point.date,
                value: point.value,
                label: point.label
            )
        }
        
        return ROIChartView(data: data)
            .padding(.horizontal)
    }
    
    // ローディング表示を分割
    private var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                EmptyView()
            }
        }
    }
}

// 全体統計カード
struct TotalStatsCard: View {
    let stats: StatsSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("全体統計")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            HStack {
                // 利益
                StatsCard(
                    data: StatCardData(
                        title: "総利益",
                        value: stats.profit.formatted(.currency(code: "JPY")),
                        icon: "chart.line.uptrend.xyaxis",
                        color: stats.profit >= 0 ? .accentSuccess : .accentDanger
                    )
                )
                
                Spacer()
                
                // ROI
                StatsCard(
                    data: StatCardData(
                        title: "ROI",
                        value: String(format: "%.1f%%", NSDecimalNumber(decimal: stats.roi).doubleValue),
                        icon: "percent",
                        color: stats.roi >= 0 ? .accentSuccess : .accentDanger
                    )
                )
            }
            
            HStack {
                // ベット数
                StatsCard(
                    data: StatCardData(
                        title: "ベット数",
                        value: "\(stats.betCount)回",
                        icon: "list.bullet",
                        color: .primaryColor
                    )
                )
                
                Spacer()
                
                // 的中率
                StatsCard(
                    data: StatCardData(
                        title: "的中率",
                        value: String(format: "%.1f%%", stats.winRate),
                        icon: "checkmark.circle",
                        color: .secondaryColor
                    )
                )
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ギャンブル種別統計セクション
struct GambleTypeStatsSection: View {
    let stats: [GambleTypeStat]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ギャンブル種別別統計")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            ForEach(stats) { stat in
                GambleTypeStatRow(stat: stat)
                
                if stat.id != stats.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// ギャンブル種別統計行
struct GambleTypeStatRow: View {
    let stat: GambleTypeStat
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // アイコンと種別名
                ZStack {
                    Circle()
                        .fill(stat.color)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: stat.icon)
                        .foregroundColor(.white)
                }
                
                Text(stat.name)
                    .font(.headline)
                
                Spacer()
                
                // 損益
                VStack(alignment: .trailing) {
                    Text(stat.profit.formatted(.currency(code: "JPY")))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(stat.profit >= 0 ? .accentSuccess : .accentDanger)
                    
                    Text(String(format: "ROI: %.1f%%", NSDecimalNumber(decimal: stat.roi).doubleValue))
                        .font(.caption)
                        .foregroundColor(stat.roi >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            
            // 詳細情報
            HStack(spacing: 16) {
                StatInfoItem(
                    label: "ベット数",
                    value: "\(stat.betCount)回"
                )
                
                StatInfoItem(
                    label: "的中率",
                    value: String(format: "%.1f%%", Double(truncating: stat.winRate as NSNumber))
                )
                
                StatInfoItem(
                    label: "総投資",
                    value: "\(stat.totalBet.formatted(.currency(code: "JPY")))"
                )
            }
        }
        .padding(.vertical, 4)
    }
}

// 統計情報アイテム
struct StatInfoItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.subheadline)
        }
    }
}

// 統計メトリクスグリッド
struct StatsMetricsGrid: View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    let stats: [StatCardData]
    
    // ハードコードされたデータを削除
    init(stats: [StatCardData]) {
        self.stats = stats
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("その他の統計")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(stats) { stat in
                    StatsCard(data: stat)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    StatisticsView()
}
