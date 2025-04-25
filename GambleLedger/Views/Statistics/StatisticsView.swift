// StatisticsView.swift
import SwiftUI
import Charts

struct StatisticsView: View {
    @StateObject private var viewModel = StatisticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 期間選択セグメント
                    Picker("期間", selection: $viewModel.selectedPeriod) {
                        ForEach(StatisticsViewModel.PeriodFilter.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedPeriod) { _ in
                        viewModel.loadStatisticsData()
                    }
                    
                    // 全体統計サマリー
                    TotalStatsCard(stats: viewModel.totalStats)
                        .padding(.horizontal)
                    
                    // 利益グラフ
                    if !viewModel.profitChartData.isEmpty {
                        ProfitChartView(data: viewModel.profitChartData)
                            .frame(height: 220)
                            .padding(.horizontal)
                    }
                    
                    // ギャンブル種別統計
                    GambleTypeStatsSection(stats: viewModel.gambleTypeStats)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("統計")
            .overlay(
                viewModel.isLoading ?
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                    : nil
            )
            .refreshable {
                viewModel.loadStatisticsData()
            }
        }
    }
}

struct TotalStatsCard: View {
    let stats: StatsSummary
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("総利益")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.profit.formatted(.currency(code: "JPY")))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stats.profit >= 0 ? .accentSuccess : .accentDanger)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("全体回収率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.roi, specifier: "%.1f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(stats.roi >= 0 ? .accentSuccess : .accentDanger)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("投資額")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.totalBet.formatted(.currency(code: "JPY")))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("払戻額")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.totalReturn.formatted(.currency(code: "JPY")))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("的中率")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.winRate, specifier: "%.1f")%")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ベット回数")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(stats.betCount)回")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// その他のコンポーネント実装は省略
