// GambleLedger/Views/Home/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var selectedCalendarDate: Date?
    @State private var showDailyBetList = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 月別カレンダー（収支一覧）
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button(action: {
                                viewModel.changeMonth(by: -1)
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.primaryColor)
                                    .font(.title3)
                                    .padding(8)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.currentMonth = Date()
                                viewModel.fetchDailyProfitsForMonth()
                            }) {
                                Text("今月")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryColor)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.changeMonth(by: 1)
                            }) {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.primaryColor)
                                    .font(.title3)
                                    .padding(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        CalendarView(
                            month: viewModel.currentMonth,
                            dailyProfits: viewModel.dailyProfits,
                            dailyBets: viewModel.dailyBets,
                            onDateSelected: { date in
                                // 日付選択時にその日の記録一覧を表示
                                selectedCalendarDate = date
                                showDailyBetList = true
                            }
                        )
                    }
                    .padding()
                    .background(Color.backgroundSecondary)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
                    
                    // 本日の成績サマリーカード（グラデーションスタイル）
                    DailySummaryCard(stats: viewModel.todayStats)
                    
                    // 月間サマリーカード（アクセントカードスタイル）
                    MonthlySummaryCard(stats: viewModel.monthlyStats)
                    
                    // 最近の記録（プレミアムカードスタイル）
                    RecentBetsSection(bets: viewModel.recentBets)
                }
                .padding()
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("GambleLedger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.showAddBetSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.primaryColor)
                            .font(.title3)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.primaryColor)
                    }
                }
            }
            .sheet(isPresented: $appState.showAddBetSheet) {
                BetRecordModeSelector(selectedDate: selectedCalendarDate)
                    .onDisappear {
                        // シートが閉じられたら選択日付をクリア
                        selectedCalendarDate = nil
                        // データを再読み込み
                        viewModel.loadData()
                    }
            }
            .sheet(isPresented: $showDailyBetList) {
                if let date = selectedCalendarDate {
                    DailyBetListView(date: date)
                        .onDisappear {
                            // シートが閉じられたら選択日付をクリアしてデータを再読み込み
                            selectedCalendarDate = nil
                            viewModel.loadData()
                        }
                }
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }
}

struct DailySummaryCard: View {
    let stats: DailyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("本日の収支")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(Date().formattedString(format: "yyyy/MM/dd"))
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("損益")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(stats.profit.formatted(.currency(code: "JPY")))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("ROI")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(String(format: "%.1f%%", NSDecimalNumber(decimal: stats.roi).doubleValue))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
                
                VStack(alignment: .trailing) {
                    Text("的中率")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(String(format: "%.1f%%", stats.winRate))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            HStack {
                Text("投資額: \(stats.totalBet.formatted(.currency(code: "JPY")))")
                    .font(.footnote)
                
                Spacer()
                
                Text("払戻額: \(stats.totalReturn.formatted(.currency(code: "JPY")))")
                    .font(.footnote)
            }
            .foregroundColor(.white.opacity(0.9))
        }
        .padding()
        .background(
            stats.profit >= 0 ?
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentSuccess.opacity(0.8),
                        Color.accentSuccess
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ) :
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.accentDanger.opacity(0.8),
                        Color.accentDanger
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// 月間サマリーカード
struct MonthlySummaryCard: View {
    let stats: MonthlyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondaryColor)
                
                Text("月間サマリー")
                    .font(.headline)
                    .foregroundColor(.secondaryColor)
                
                Spacer()
                
                Text(Date().formattedString(format: "yyyy年MM月"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                // 損益
                StatsValueItem(
                    title: "損益",
                    value: stats.profit.formatted(.currency(code: "JPY")),
                    valueColor: stats.profit >= 0 ? .accentSuccess : .accentDanger,
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: stats.profit >= 0 ? .accentSuccess : .accentDanger
                )
                
                Spacer()
                
                // ROI
                StatsValueItem(
                    title: "ROI",
                    value: String(format: "%.1f%%", NSDecimalNumber(decimal: stats.roi).doubleValue),
                    valueColor: stats.roi >= 0 ? .accentSuccess : .accentDanger,
                    icon: "percent",
                    iconColor: stats.roi >= 0 ? .accentSuccess : .accentDanger
                )
                
                Spacer()
                
                // 的中率
                StatsValueItem(
                    title: "的中率",
                    value: String(format: "%.1f%%", stats.winRate),
                    valueColor: .primaryColor,
                    icon: "checkmark.circle",
                    iconColor: .primaryColor
                )
            }
            
            Divider()
            
            // 予算残高
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("予算残高")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(stats.budgetRemaining.formatted(.currency(code: "JPY")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(getBudgetColor(used: stats.totalBet, total: stats.budgetTotal))
                }
                
                // 予算プログレスバー
                BudgetProgressBar(
                    current: stats.totalBet,
                    total: stats.budgetTotal
                )
                
                // 使用率表示
                if stats.budgetTotal > 0 {
                    let usagePercent = Double(truncating: (stats.totalBet / stats.budgetTotal * 100) as NSNumber)
                    Text("\(Int(usagePercent))% 使用済み")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.secondaryColor, .primaryColor]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    private func getBudgetColor(used: Decimal, total: Decimal) -> Color {
        if total == 0 { return .gray }
        let ratio = Double(truncating: (used / total) as NSNumber)
        
        if ratio < 0.6 {
            return .accentSuccess
        } else if ratio < 0.8 {
            return .accentWarning
        } else {
            return .accentDanger
        }
    }
}

struct StatsValueItem: View {
    let title: String
    let value: String
    let valueColor: Color
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 4)
    }
}

// 最近のベット記録セクション
struct RecentBetsSection: View {
    let bets: [BetRecordDisplayModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.primaryColor)
                
                Text("最近の記録")
                    .font(.headline)
                    .foregroundColor(.primaryColor)
                
                Spacer()
                
                NavigationLink(destination: HistoryView()) {
                    HStack {
                        Text("すべて見る")
                            .font(.caption)
                            .foregroundColor(.secondaryColor)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondaryColor)
                    }
                }
            }
            
            if bets.isEmpty {
                EmptyBetsView()
            } else {
                ForEach(bets) { bet in
                    RecentBetRow(bet: bet)
                    
                    if bet.id != bets.last?.id {
                        Divider()
                            .background(Color.backgroundTertiary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.backgroundSecondary)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
    }
}

// 最近のベット行
struct RecentBetRow: View {
    let bet: BetRecordDisplayModel
    
    var body: some View {
        HStack {
            // 種別カラーマーク
            Circle()
                .fill(bet.gambleTypeColor)
                .frame(width: 14, height: 14)
                .shadow(color: bet.gambleTypeColor.opacity(0.5), radius: 2, x: 0, y: 1)
            
            // イベント名
            VStack(alignment: .leading, spacing: 2) {
                Text(bet.eventName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("\(bet.gambleType) | \(bet.bettingSystem)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // 損益
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "¥%@", bet.profit.formattedWithSeparator()))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(bet.profit >= 0 ? .accentSuccess : .accentDanger)
                
                Text(bet.date.timeAgoDisplay())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: {
                // 詳細表示アクション
            }) {
                Label("詳細を表示", systemImage: "doc.text.magnifyingglass")
            }
            
            Button(action: {
                // 編集アクション
            }) {
                Label("編集", systemImage: "pencil")
            }
        }
    }
}

// ベット記録が空の場合の表示
struct EmptyBetsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.7))
                .padding()
                .background(
                    Circle()
                        .fill(Color.backgroundTertiary.opacity(0.5))
                        .frame(width: 80, height: 80)
                )
            
            Text("記録がありません")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("ベット記録を追加すると、ここに表示されます")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
