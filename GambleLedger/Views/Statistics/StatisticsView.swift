// GambleLedger/Views/Statistics/StatisticsView.swift
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
                            .padding(.horizontal)
                    }
                    
                    // ROIグラフ
                    if !viewModel.roiChartData.isEmpty {
                        ROIChartView(data: viewModel.roiChartData)
                            .padding(.horizontal)
                    }
                    
                    // ギャンブル種別統計
                    if !viewModel.gambleTypeStats.isEmpty {
                        GambleTypeStatsSection(stats: viewModel.gambleTypeStats)
                            .padding(.horizontal)
                    }
                    
                    // 統計数値カード
                    StatsMetricsGrid()
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
    
              // GambleLedger/Views/Statistics/StatisticsView.swift （続き）
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
                                   
                                   Text("ROI: \(stat.roi, specifier: "%.1f")%")
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
                                   value: "\(stat.winRate, specifier: "%.1f")%"
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
                   var body: some View {
                       StatsGridView(
                           stats: [
                               StatCardData(
                                   title: "平均ベット金額",
                                   value: "¥3,240",
                                   icon: "banknote",
                                   color: .primaryColor
                               ),
                               StatCardData(
                                   title: "最大勝ち金額",
                                   value: "¥32,500",
                                   icon: "arrow.up.forward",
                                   color: .accentSuccess
                               ),
                               StatCardData(
                                   title: "最大負け金額",
                                   value: "¥12,800",
                                   icon: "arrow.down.forward",
                                   color: .accentDanger
                               ),
                               StatCardData(
                                   title: "連勝記録",
                                   value: "6回",
                                   icon: "flame",
                                   color: .gambleHorse
                               )
                           ],
                           columns: 2
                       )
                   }
               }

               // プレビュー
               #Preview {
                   StatisticsView()
               }
