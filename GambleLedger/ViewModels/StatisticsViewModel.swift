// StatisticsViewModel.swift
import Foundation
import Combine
import SwiftUI

class StatisticsViewModel: ObservableObject {
    // 統計表示期間
    enum PeriodFilter: String, CaseIterable, Identifiable {
        case week = "週間"
        case month = "月間"
        case quarter = "四半期"
        case year = "年間"
        case all = "全期間"
        
        var id: String { self.rawValue }
    }
    
    // 表示データ
    @Published var selectedPeriod: PeriodFilter = .month
    @Published var totalStats: StatsSummary = StatsSummary()
    @Published var gambleTypeStats: [GambleTypeStat] = []
    @Published var dailyStats: [DailyStat] = []
    @Published var isLoading: Bool = false
    
    // グラフデータ
    @Published var profitChartData: [ChartDataPoint] = []
    @Published var roiChartData: [ChartDataPoint] = []
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadStatisticsData()
    }
    
    func loadStatisticsData() {
        isLoading = true
        
        let (startDate, endDate) = getDateRange(for: selectedPeriod)
        
        // 全体統計を取得
        fetchTotalStats(startDate: startDate, endDate: endDate)
        
        // ギャンブル種別ごとの統計取得
        fetchGambleTypeStats(startDate: startDate, endDate: endDate)
        
        // 日別統計取得
        fetchDailyStats(startDate: startDate, endDate: endDate)
    }
    
    private func getDateRange(for period: PeriodFilter) -> (Date, Date) {
        let endDate = Date()
        let calendar = Calendar.current
        
        let startDate: Date
        
        switch period {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
        case .quarter:
            startDate = calendar.date(byAdding: .month, value: -3, to: endDate) ?? endDate
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        case .all:
            startDate = calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
        }
        
        return (startDate, endDate)
    }
    
    private func fetchTotalStats(startDate: Date, endDate: Date) {
        coreDataManager.fetchBetRecords(startDate: startDate, endDate: endDate) { [weak self] records in
            guard let self = self else { return }
            
            let totalBet = records.reduce(Decimal(0)) { result, record in
                return result + ((record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0))
            }
            
            let totalReturn = records.reduce(Decimal(0)) { result, record in
                return result + ((record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0))
            }
            
            let profit = totalReturn - totalBet
            let roi = totalBet > 0 ? ((totalReturn / totalBet) - 1) * 100 : 0
            
            let wins = records.filter { record in
                return record.value(forKey: "isWin") as? Bool ?? false
            }.count
            
            let winRate = records.isEmpty ? 0 : Double(wins) / Double(records.count) * 100
            
            DispatchQueue.main.async {
                self.totalStats = StatsSummary(
                    totalBet: totalBet,
                    totalReturn: totalReturn,
                    profit: profit,
                    roi: roi,
                    betCount: records.count,
                    winCount: wins,
                    winRate: winRate
                )
                
                self.isLoading = false
            }
        }
    }
    
    private func fetchGambleTypeStats(startDate: Date, endDate: Date) {
        // 種別データの取得と統計処理（略）
    }
    
    private func fetchDailyStats(startDate: Date, endDate: Date) {
        // 日別データの取得とグラフ用データ加工（略）
    }
}

struct StatsSummary {
    var totalBet: Decimal = 0
    var totalReturn: Decimal = 0
    var profit: Decimal = 0
    var roi: Decimal = 0
    var betCount: Int = 0
    var winCount: Int = 0
    var winRate: Double = 0
}

struct GambleTypeStat: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    let betCount: Int
    let totalBet: Decimal
    let totalReturn: Decimal
    let profit: Decimal
    let roi: Decimal
    let winRate: Double
}

struct DailyStat: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let betCount: Int
    let profit: Decimal
    let roi: Decimal
}

struct ChartDataPoint: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let value: Double
    let label: String
}
