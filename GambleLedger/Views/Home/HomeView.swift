// HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 本日の成績サマリーカード
                    DailySummaryCard(stats: viewModel.todayStats)
                    
                    // 月間サマリーカード
                    MonthlySummaryCard(stats: viewModel.monthlyStats)
                    
                    // 最近の記録
                    RecentBetsSection(bets: viewModel.recentBets)
                }
                .padding()
            }
            .navigationTitle("GambleLedger")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.showAddBetSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.loadData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(isPresented: $appState.showAddBetSheet) {
                QuickBetRecordView()
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
        VStack(alignment: .leading, spacing: 12) {
            Text("本日の収支")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading) {
                    Text("損益")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(stats.profit.formatted(.currency(code: "JPY")))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stats.profit >= 0 ? .accentSuccess : .accentDanger)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("ROI")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f%%", NSDecimalNumber(decimal: stats.roi).doubleValue))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(stats.roi >= 0 ? .accentSuccess : .accentDanger)
                }
                
                VStack(alignment: .trailing) {
                    Text("的中率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f%%", stats.winRate))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryColor)
                }
            }
            
            Divider()
            
            HStack {
                Text("投資額: \(stats.totalBet.formatted(.currency(code: "JPY")))")
                    .font(.footnote)
                
                Spacer()
                
                Text("払戻額: \(stats.totalReturn.formatted(.currency(code: "JPY")))")
                    .font(.footnote)
            }
            .foregroundColor(.gray)
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 月間サマリーカード
struct MonthlySummaryCard: View {
    let stats: MonthlyStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("月間サマリー")
                .font(.headline)
                .foregroundColor(.secondaryColor)
            
            HStack {
                // 損益
                VStack(alignment: .leading, spacing: 4) {
                    Text("損益")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(stats.profit.formatted(.currency(code: "JPY")))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(stats.profit >= 0 ? .accentSuccess : .accentDanger)
                }
                
                Spacer()
                
                // ROI
                VStack(alignment: .center, spacing: 4) {
                    Text("ROI")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f%%", NSDecimalNumber(decimal: stats.roi).doubleValue))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(stats.roi >= 0 ? .accentSuccess : .accentDanger)
                }
                
                Spacer()
                
                // 的中率
                VStack(alignment: .trailing, spacing: 4) {
                    Text("的中率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f%%", stats.winRate))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryColor)
                }
            }
            
            Divider()
            
            // 予算残高
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("予算残高")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(stats.budgetRemaining.formatted(.currency(code: "JPY")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                // 予算プログレスバー
                BudgetProgressBar(
                    current: stats.totalBet,
                    total: stats.budgetTotal
                )
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// 最近のベット記録セクション
struct RecentBetsSection: View {
    let bets: [BetRecordDisplayModel]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近の記録")
                    .font(.headline)
                    .foregroundColor(.secondaryColor)
                
                Spacer()
                
                NavigationLink(destination: HistoryView()) {
                    Text("すべて見る")
                        .font(.caption)
                        .foregroundColor(.primaryColor)
                }
            }
            
            if bets.isEmpty {
                EmptyBetsView()
            } else {
                ForEach(bets) { bet in
                    RecentBetRow(bet: bet)
                    
                    if bet.id != bets.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
                .frame(width: 10, height: 10)
            
            // イベント名
            VStack(alignment: .leading, spacing: 2) {
                Text(bet.eventName)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text("\(bet.gambleType) | \(bet.bettingSystem)")
                    .font(.caption)
                    .foregroundColor(.gray)
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
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// ベット記録が空の場合の表示
struct EmptyBetsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 32))
                .foregroundColor(.gray)
            
            Text("記録がありません")
                .font(.subheadline)
            
            Text("ベット記録を追加すると、ここに表示されます")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
