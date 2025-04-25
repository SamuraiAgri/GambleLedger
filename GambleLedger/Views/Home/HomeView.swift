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
                    
                    Text("\(stats.profit.formatted(.currency(code: "JPY")))")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(stats.profit >= 0 ? .accentSuccess : .accentDanger)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("ROI")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.roi, specifier: "%.1f")%")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(stats.roi >= 0 ? .accentSuccess : .accentDanger)
                }
                
                VStack(alignment: .trailing) {
                    Text("的中率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.winRate, specifier: "%.1f")%")
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

// その他のコンポーネント実装は省略
