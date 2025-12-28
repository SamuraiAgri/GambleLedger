// GambleLedger/ViewModels/HomeViewModel.swift
import Foundation
import Combine
import CoreData
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var todayStats: DailyStats = DailyStats()
    @Published var monthlyStats: MonthlyStats = MonthlyStats()
    @Published var recentBets: [BetRecordDisplayModel] = []
    @Published var isLoading: Bool = false
    @Published var dailyProfits: [Date: Decimal] = [:] // カレンダー用の日別収支
    @Published var dailyBets: [Date: Decimal] = [:] // カレンダー用の日別賭け金額
    @Published var currentMonth: Date = Date()
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func loadData() {
        isLoading = true
        
        // 本日の統計を取得
        fetchTodayStats()
        
        // 月間統計を取得
        fetchMonthlyStats()
        
        // 最近のベット履歴を取得
        fetchRecentBets()
        
        // カレンダー用の日別データを取得
        fetchDailyProfitsForMonth()
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
            
            let totalBet = records.reduce(Decimal(0)) { result, record in
                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                return result + betAmount
            }
            
            let totalReturn = records.reduce(Decimal(0)) { result, record in
                let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                return result + returnAmount
            }
            
            let profit = totalReturn - totalBet
            let roi = totalBet > 0 ? ((totalReturn / totalBet) - 1) * 100 : 0
            
            let wins = records.filter { record in
                record.value(forKey: "isWin") as? Bool ?? false
            }.count
            
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
                
                // 読み込み完了したか確認
                self.checkLoadingComplete()
            }
        }
    }
    
    private func fetchMonthlyStats() {
        let today = Date()
        let startOfMonth = today.startOfMonth()
        let endOfMonth = today.endOfMonth()
        
        // 月次予算を取得
        coreDataManager.fetchCurrentBudget(forDate: today) { [weak self] budgetObject in
            guard let self = self else { return }
            
            let budgetTotal: Decimal
            if let budgetObject = budgetObject {
                budgetTotal = (budgetObject.value(forKey: "amount") as? NSDecimalNumber)?.decimalValue ?? Constants.Budget.defaultMonthlyAmount
            } else {
                budgetTotal = Constants.Budget.defaultMonthlyAmount
            }
            
            // 月間のベット記録を取得
            self.coreDataManager.fetchBetRecords(
                startDate: startOfMonth,
                endDate: endOfMonth
            ) { [weak self] records in
                guard let self = self else { return }
                
                let totalBet = records.reduce(Decimal(0)) { result, record in
                    let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                    return result + betAmount
                }
                
                let totalReturn = records.reduce(Decimal(0)) { result, record in
                    let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                    return result + returnAmount
                }
                
                let profit = totalReturn - totalBet
                let roi = totalBet > 0 ? ((totalReturn / totalBet) - 1) * 100 : 0
                
                let wins = records.filter { record in
                    record.value(forKey: "isWin") as? Bool ?? false
                }.count
                
                let winRate = records.isEmpty ? 0 : Double(wins) / Double(records.count) * 100
                
                DispatchQueue.main.async {
                    self.monthlyStats = MonthlyStats(
                        totalBet: totalBet,
                        totalReturn: totalReturn,
                        profit: profit,
                        roi: roi,
                        betCount: records.count,
                        winCount: wins,
                        winRate: winRate,
                        budgetRemaining: budgetTotal - totalBet,
                        budgetTotal: budgetTotal
                    )
                    
                    // 読み込み完了したか確認
                    self.checkLoadingComplete()
                }
            }
        }
    }
    
    private func fetchRecentBets() {
        coreDataManager.fetchBetRecords(limit: 5) { [weak self] records in
            guard let self = self else { return }
            
            // 結果をソート（日付の降順）
            let sortedRecords = records.sorted {
                let date1 = $0.value(forKey: "date") as? Date ?? Date()
                let date2 = $1.value(forKey: "date") as? Date ?? Date()
                return date1 > date2
            }
            
            let displayModels = sortedRecords.map { record in
                let id = record.value(forKey: "id") as? UUID ?? UUID()
                let date = record.value(forKey: "date") as? Date ?? Date()
                
                // gambleTypeのリレーションから取得
                var gambleTypeName = "不明"
                var gambleTypeColorHex = "#000000"
                
                if let gambleTypeObject = record.value(forKey: "gambleType") as? NSManagedObject {
                    gambleTypeName = gambleTypeObject.value(forKey: "name") as? String ?? "不明"
                    gambleTypeColorHex = gambleTypeObject.value(forKey: "color") as? String ?? "#000000"
                }
                
                let eventName = record.value(forKey: "eventName") as? String ?? ""
                                let bettingSystem = record.value(forKey: "bettingSystem") as? String ?? ""
                                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.doubleValue ?? 0
                                let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.doubleValue ?? 0
                                let isWin = record.value(forKey: "isWin") as? Bool ?? false
                                
                                return BetRecordDisplayModel(
                                    id: id.uuidString,
                                    date: date,
                                    gambleType: gambleTypeName,
                                    gambleTypeColor: Color(hex: gambleTypeColorHex),
                                    eventName: eventName,
                                    bettingSystem: bettingSystem,
                                    betAmount: betAmount,
                                    returnAmount: returnAmount,
                                    isWin: isWin
                                )
                            }
                            
                            DispatchQueue.main.async {
                                self.recentBets = displayModels
                                
                                // 読み込み完了したか確認
                                self.checkLoadingComplete()
                            }
                        }
                    }
                    
                    // すべてのデータが読み込まれたか確認
                    private func checkLoadingComplete() {
                        // データが揃っているか確認
                        let hasToday = self.todayStats.betCount >= 0 // 0件もあり得るため >= 0
                        let hasMonthly = self.monthlyStats.betCount >= 0 // 0件もあり得るため >= 0
                        
                        // すべてのデータが揃っていれば読み込み完了
                        if hasToday && hasMonthly {
                            self.isLoading = false
                        }
                    }
                    
                    // カレンダー用の日別収支と賭け金額を取得
                    func fetchDailyProfitsForMonth() {
                        let calendar = Calendar.current
                        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
                            return
                        }
                        
                        coreDataManager.fetchBetRecords(
                            startDate: monthInterval.start,
                            endDate: monthInterval.end
                        ) { [weak self] records in
                            guard let self = self else { return }
                            
                            var profitsByDay: [Date: Decimal] = [:]
                            var betsByDay: [Date: Decimal] = [:]
                            
                            for record in records {
                                guard let date = record.value(forKey: "date") as? Date else { continue }
                                let dayStart = calendar.startOfDay(for: date)
                                
                                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? 0
                                let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? 0
                                let profit = returnAmount - betAmount
                                
                                profitsByDay[dayStart, default: 0] += profit
                                betsByDay[dayStart, default: 0] += betAmount
                            }
                            
                            DispatchQueue.main.async {
                                self.dailyProfits = profitsByDay
                                self.dailyBets = betsByDay
                            }
                        }
                    }
                    
                    // 月を変更
                    func changeMonth(by offset: Int) {
                        let calendar = Calendar.current
                        if let newMonth = calendar.date(byAdding: .month, value: offset, to: currentMonth) {
                            currentMonth = newMonth
                            fetchDailyProfitsForMonth()
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
