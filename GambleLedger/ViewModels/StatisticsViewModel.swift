// GambleLedger/ViewModels/StatisticsViewModel.swift
import Foundation
import Combine
import SwiftUI
import CoreData

@MainActor
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
    @Published var profitChartData: [ChartPointData] = []
    @Published var roiChartData: [ChartPointData] = []
    
    // 追加の統計データ
    @Published var averageBetAmount: Decimal = 0
    @Published var maxWinAmount: Decimal = 0
    @Published var maxLossAmount: Decimal = 0
    @Published var maxWinStreak: Int = 0
    
    // 全レコード（詳細統計用）
    @Published var allRecords: [BetDisplayModel] = []
    
    // ギャンブル種別キャッシュ
    private var gambleTypesCache: [GambleTypeModel] = []
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadGambleTypes()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // ギャンブル種別をロード
    private func loadGambleTypes() {
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            let types = results.compactMap { GambleTypeModel.fromManagedObject($0) }
            
            DispatchQueue.main.async {
                self.gambleTypesCache = types
                // ギャンブル種別をロード後に統計データをロード
                self.loadStatisticsData()
            }
        }
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
                // 追加の統計データを計算
                self.calculateAdditionalStats(from: records)
                
                // allRecordsを更新（BetDisplayModelに変換）
                self.updateAllRecords(from: records)
                
                self.totalStats = StatsSummary(
                    totalBet: totalBet,
                    totalReturn: totalReturn,
                    profit: profit,
                    roi: roi,
                    betCount: records.count,
                    winCount: wins,
                    winRate: winRate
                )
                
                // 実際のデータから損益チャートとROIチャートを生成
                self.generateChartData(from: records)
                
                self.isLoading = false
            }
        }
    }
    
    // allRecordsを更新
    private func updateAllRecords(from records: [NSManagedObject]) {
        // NSManagedObjectからBetDisplayModelに変換
        var displayRecords: [BetDisplayModel] = []
        
        for record in records {
            let betRecord = BetRecordModel.fromManagedObject(record)
            // ギャンブル種別の情報を取得
            let gambleType = gambleTypesCache.first { $0.id == betRecord.gambleTypeID }
            let displayModel = betRecord.toDisplayModel(with: gambleType)
            displayRecords.append(displayModel)
        }
        
        self.allRecords = displayRecords
    }
    
    // 追加の統計を計算
    private func calculateAdditionalStats(from records: [NSManagedObject]) {
        // 平均ベット金額
        let totalBet = records.reduce(Decimal(0)) { result, record in
            let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
            return result + betAmount
        }
        
        if !records.isEmpty {
            averageBetAmount = totalBet / Decimal(records.count)
        } else {
            averageBetAmount = 0
        }
        
        // 最大勝ち額
        var maxWin: Decimal = 0
        // 最大負け額（正の値で保存）
        var maxLoss: Decimal = 0
        
        for record in records {
            let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
            let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
            let profit = returnAmount - betAmount
            
            if profit > 0 && profit > maxWin {
                maxWin = profit
            } else if profit < 0 && abs(profit) > maxLoss {
                maxLoss = abs(profit)
            }
        }
        
        maxWinAmount = maxWin
        maxLossAmount = maxLoss
        
        // 連勝記録
        calculateWinStreak(from: records)
    }
    
    // 連勝記録の計算
    private func calculateWinStreak(from records: [NSManagedObject]) {
        // 日付でソート
        let sortedRecords = records.sorted {
            let date1 = $0.value(forKey: "date") as? Date ?? Date()
            let date2 = $1.value(forKey: "date") as? Date ?? Date()
            return date1 > date2
        }
        
        var currentStreak = 0
        var maxStreak = 0
        
        for record in sortedRecords {
            let isWin = record.value(forKey: "isWin") as? Bool ?? false
            
            if isWin {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        // 現在進行中の連勝も考慮
        let currentWinStreak = calculateCurrentWinStreak(from: sortedRecords)
        
        maxWinStreak = max(maxStreak, currentWinStreak)
    }
    
    // 現在進行中の連勝
    private func calculateCurrentWinStreak(from sortedRecords: [NSManagedObject]) -> Int {
        var streak = 0
        
        for record in sortedRecords {
            let isWin = record.value(forKey: "isWin") as? Bool ?? false
            
            if isWin {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    // 実際のデータからチャートデータを生成する
    private func generateChartData(from records: [NSManagedObject]) {
        // レコードを日付でグループ化
        let calendar = Calendar.current
        var dailyProfits: [Date: Decimal] = [:]
        var dailyROIs: [Date: Decimal] = [:]
        var dailyBets: [Date: Decimal] = [:]
        var dailyReturns: [Date: Decimal] = [:]
        
        // 日付ごとにデータを集計
        for record in records {
            guard let date = record.value(forKey: "date") as? Date else { continue }
            
            // 日付のみの部分を抽出（時間を除く）
            let dayStart = calendar.startOfDay(for: date)
            
            let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
            let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
            
            // 日毎の集計に追加
            dailyBets[dayStart] = (dailyBets[dayStart] ?? 0) + betAmount
            dailyReturns[dayStart] = (dailyReturns[dayStart] ?? 0) + returnAmount
        }
        
        // 損益とROIを計算
        for (date, betAmount) in dailyBets {
            let returnAmount = dailyReturns[date] ?? 0
            let profit = returnAmount - betAmount
            dailyProfits[date] = profit
            
            if betAmount > 0 {
                dailyROIs[date] = ((returnAmount / betAmount) - 1) * 100
            } else {
                dailyROIs[date] = 0
            }
        }
        
        // 日付でソート
        let sortedDates = dailyProfits.keys.sorted()
        
        // チャートデータを生成
        var profitData: [ChartPointData] = []
        var roiData: [ChartPointData] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        for date in sortedDates {
            if let profit = dailyProfits[date] {
                profitData.append(ChartPointData(
                    date: date,
                    value: NSDecimalNumber(decimal: profit).doubleValue,
                    label: dateFormatter.string(from: date)
                ))
            }
            
            if let roi = dailyROIs[date] {
                roiData.append(ChartPointData(
                    date: date,
                    value: NSDecimalNumber(decimal: roi).doubleValue,
                    label: dateFormatter.string(from: date)
                ))
            }
        }
        
        DispatchQueue.main.async {
            self.profitChartData = profitData
            self.roiChartData = roiData
        }
    }
    
    private func fetchGambleTypeStats(startDate: Date, endDate: Date) {
        // ギャンブル種別ごとの統計情報を取得するコード
        // 実際のデータベースからデータを取得する実装へ変更
    }
    
    private func fetchDailyStats(startDate: Date, endDate: Date) {
        // 日別統計を取得するコード
        // 実際のデータベースからデータを取得する実装へ変更
    }
    
    // StatCardData配列を生成するメソッド
    func generateAdditionalStats() -> [StatCardData] {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "¥"
        formatter.currencyCode = "JPY"
        
        // 平均ベット金額
        let formattedAverage = formatter.string(from: NSDecimalNumber(decimal: averageBetAmount)) ?? "¥0"
        
        // 最大勝ち金額
        let formattedMaxWin = formatter.string(from: NSDecimalNumber(decimal: maxWinAmount)) ?? "¥0"
        
        // 最大負け金額
        let formattedMaxLoss = formatter.string(from: NSDecimalNumber(decimal: maxLossAmount)) ?? "¥0"
        
        return [
            StatCardData(
                title: "平均ベット金額",
                value: formattedAverage,
                icon: "banknote",
                color: .primaryColor
            ),
            StatCardData(
                title: "最大勝ち金額",
                value: formattedMaxWin,
                icon: "arrow.up.forward",
                color: .accentSuccess
            ),
            StatCardData(
                title: "最大負け金額",
                value: formattedMaxLoss,
                icon: "arrow.down.forward",
                color: .accentDanger
            ),
            StatCardData(
                title: "連勝記録",
                value: "\(maxWinStreak)回",
                icon: "flame",
                color: .gambleHorse
            )
        ]
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
    let roi: Double
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
