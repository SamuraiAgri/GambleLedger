// HomeViewModel.swift
import Foundation
import Combine
import CoreData

class HomeViewModel: ObservableObject {
    @Published var todayStats: DailyStats = DailyStats()
    @Published var monthlyStats: MonthlyStats = MonthlyStats()
    @Published var recentBets: [BetRecordDisplayModel] = []
    @Published var isLoading: Bool = false
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        // 本日の統計を取得
        fetchTodayStats()
        
        // 月間統計を取得
        fetchMonthlyStats()
        
        // 最近のベット履歴を取得
        fetchRecentBets()
        
        isLoading = false
    }
    
    private func fetchTodayStats() {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        coreDataManager.fetchBetRecords(
            startDate: startOfDay,
            endDate: endOfDay
        ) { [weak self] records in
            guard let self = self else { return }
            
            let totalBet = records.reduce(0) { $0 + ($1.betAmount?.decimalValue ?? 0) }
            let totalReturn = records.reduce(0) { $0 + ($1.returnAmount?.decimalValue ?? 0) }
            let profit = totalReturn - totalBet
            let roi = totalBet > 0 ? ((totalReturn / totalBet) - 1) * 100 : 0
            
            let wins = records.filter { $0.isWin }.count
            let winRate = records.isEmpty ? 0 : Double(wins) / Double(records.count) * 100
            
            DispatchQueue.main.async {
                self.todayStats = DailyStats(
                    totalBet: totalBet,
                    totalReturn: totalReturn,
                    profit: profit,
                    roi: roi,
                    betCount: records.count,
                    winCount: wins,
                    winRate: winRate
                )
            }
        }
    }
    
    private func fetchMonthlyStats() {
        // 実装省略 (今月の統計データ取得)
    }
    
    private func fetchRecentBets() {
        coreDataManager.fetchBetRecords(limit: 5) { [weak self] records in
            guard let self = self else { return }
            
            let displayModels = records.map { record in
                BetRecordDisplayModel(
                    id: record.id?.uuidString ?? UUID().uuidString,
                    date: record.date ?? Date(),
                    gambleType: record.gambleType?.name ?? "不明",
                    gambleTypeColor: Color(hex: record.gambleType?.color ?? "#000000"),
                    eventName: record.eventName ?? "",
                    bettingSystem: record.bettingSystem ?? "",
                    betAmount: record.betAmount?.doubleValue ?? 0,
                    returnAmount: record.returnAmount?.doubleValue ?? 0,
                    isWin: record.isWin
                )
            }
            
            DispatchQueue.main.async {
                self.recentBets = displayModels
            }
        }
    }
}

struct DailyStats {
    var totalBet: Decimal = 0
    var totalReturn: Decimal = 0
    var profit: Decimal = 0
    var roi: Decimal = 0
    var betCount: Int = 0
    var winCount: Int = 0
    var winRate: Double = 0
}

struct MonthlyStats {
    var totalBet: Decimal = 0
    var totalReturn: Decimal = 0
    var profit: Decimal = 0
    var roi: Decimal = 0
    var betCount: Int = 0
    var winCount: Int = 0
    var winRate: Double = 0
    var budgetRemaining: Decimal = 0
    var budgetTotal: Decimal = 0
}

struct BetRecordDisplayModel: Identifiable {
    let id: String
    let date: Date
    let gambleType: String
    let gambleTypeColor: Color
    let eventName: String
    let bettingSystem: String
    let betAmount: Double
    let returnAmount: Double
    let isWin: Bool
    
    var profit: Double { returnAmount - betAmount }
}
