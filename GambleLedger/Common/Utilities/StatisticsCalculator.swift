// GambleLedger/Common/Utilities/StatisticsCalculator.swift
import Foundation

struct StatisticsCalculator {
    // MARK: - Basic Statistics
    
    /// 勝率を計算
    static func calculateWinRate(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let wins = records.filter { $0.isWin }.count
        return (Double(wins) / Double(records.count)) * 100.0
    }
    
    /// 平均ROIを計算
    static func calculateAverageROI(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let totalROI = records.reduce(0.0) { $0 + $1.roi }
        return totalROI / Double(records.count)
    }
    
    /// 総賭け金を計算
    static func calculateTotalBetAmount(records: [BetDisplayModel]) -> Double {
        return records.reduce(0.0) { $0 + $1.betAmount }
    }
    
    /// 総払戻金を計算
    static func calculateTotalReturnAmount(records: [BetDisplayModel]) -> Double {
        return records.reduce(0.0) { $0 + $1.returnAmount }
    }
    
    /// 総損益を計算
    static func calculateTotalProfit(records: [BetDisplayModel]) -> Double {
        return records.reduce(0.0) { $0 + $1.profit }
    }
    
    /// 平均賭け金を計算
    static func calculateAverageBetAmount(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        return calculateTotalBetAmount(records: records) / Double(records.count)
    }
    
    /// 平均払戻金を計算
    static func calculateAverageReturnAmount(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        return calculateTotalReturnAmount(records: records) / Double(records.count)
    }
    
    /// 平均損益を計算
    static func calculateAverageProfit(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        return calculateTotalProfit(records: records) / Double(records.count)
    }
    
    // MARK: - Advanced Statistics
    
    /// 最大勝利金額
    static func calculateMaxWin(records: [BetDisplayModel]) -> Double {
        return records.filter { $0.isWin }.map { $0.profit }.max() ?? 0.0
    }
    
    /// 最大損失金額
    static func calculateMaxLoss(records: [BetDisplayModel]) -> Double {
        return records.filter { !$0.isWin }.map { abs($0.profit) }.max() ?? 0.0
    }
    
    /// 連勝数を計算
    static func calculateWinStreak(records: [BetDisplayModel]) -> Int {
        var maxStreak = 0
        var currentStreak = 0
        
        for record in records.sorted(by: { $0.date < $1.date }) {
            if record.isWin {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    /// 連敗数を計算
    static func calculateLossStreak(records: [BetDisplayModel]) -> Int {
        var maxStreak = 0
        var currentStreak = 0
        
        for record in records.sorted(by: { $0.date < $1.date }) {
            if !record.isWin {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        
        return maxStreak
    }
    
    /// ギャンブル種別ごとの統計
    static func calculateStatsByType(records: [BetDisplayModel]) -> [String: TypeStatistics] {
        var statsByType: [String: TypeStatistics] = [:]
        
        let groupedRecords = Dictionary(grouping: records, by: { $0.gambleType })
        
        for (type, typeRecords) in groupedRecords {
            let stats = TypeStatistics(
                gambleType: type,
                totalBets: typeRecords.count,
                winRate: calculateWinRate(records: typeRecords),
                totalProfit: calculateTotalProfit(records: typeRecords),
                averageROI: calculateAverageROI(records: typeRecords),
                totalBetAmount: calculateTotalBetAmount(records: typeRecords)
            )
            statsByType[type] = stats
        }
        
        return statsByType
    }
    
    /// 期間ごとの統計（月別）
    static func calculateMonthlyStats(records: [BetDisplayModel]) -> [MonthlyStatistics] {
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: records) { record -> String in
            let components = calendar.dateComponents([.year, .month], from: record.date)
            return "\(components.year!)-\(String(format: "%02d", components.month!))"
        }
        
        var monthlyStats: [MonthlyStatistics] = []
        
        for (monthKey, monthRecords) in groupedByMonth.sorted(by: { $0.key < $1.key }) {
            let stats = MonthlyStatistics(
                month: monthKey,
                totalBets: monthRecords.count,
                winRate: calculateWinRate(records: monthRecords),
                totalProfit: calculateTotalProfit(records: monthRecords),
                totalBetAmount: calculateTotalBetAmount(records: monthRecords),
                totalReturnAmount: calculateTotalReturnAmount(records: monthRecords)
            )
            monthlyStats.append(stats)
        }
        
        return monthlyStats
    }
    
    /// 標準偏差を計算
    static func calculateStandardDeviation(records: [BetDisplayModel]) -> Double {
        guard records.count > 1 else { return 0.0 }
        
        let mean = calculateAverageProfit(records: records)
        let variance = records.reduce(0.0) { sum, record in
            let diff = record.profit - mean
            return sum + (diff * diff)
        } / Double(records.count - 1)
        
        return sqrt(variance)
    }
    
    /// シャープレシオを計算（リスク調整後リターン）
    static func calculateSharpeRatio(records: [BetDisplayModel]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        
        let averageProfit = calculateAverageProfit(records: records)
        let standardDeviation = calculateStandardDeviation(records: records)
        
        guard standardDeviation > 0 else { return 0.0 }
        
        return averageProfit / standardDeviation
    }
}

// MARK: - Statistics Models

struct TypeStatistics: Identifiable {
    let id = UUID()
    let gambleType: String
    let totalBets: Int
    let winRate: Double
    let totalProfit: Double
    let averageROI: Double
    let totalBetAmount: Double
}

struct MonthlyStatistics: Identifiable {
    let id = UUID()
    let month: String
    let totalBets: Int
    let winRate: Double
    let totalProfit: Double
    let totalBetAmount: Double
    let totalReturnAmount: Double
    
    var displayMonth: String {
        let components = month.split(separator: "-")
        if components.count == 2 {
            return "\(components[0])年\(components[1])月"
        }
        return month
    }
}

struct DetailedStatistics {
    let winRate: Double
    let averageROI: Double
    let totalBetAmount: Double
    let totalReturnAmount: Double
    let totalProfit: Double
    let averageBetAmount: Double
    let averageProfit: Double
    let maxWin: Double
    let maxLoss: Double
    let winStreak: Int
    let lossStreak: Int
    let standardDeviation: Double
    let sharpeRatio: Double
    let totalBets: Int
    let wins: Int
    let losses: Int
    
    static func calculate(from records: [BetDisplayModel]) -> DetailedStatistics {
        let wins = records.filter { $0.isWin }.count
        let losses = records.count - wins
        
        return DetailedStatistics(
            winRate: StatisticsCalculator.calculateWinRate(records: records),
            averageROI: StatisticsCalculator.calculateAverageROI(records: records),
            totalBetAmount: StatisticsCalculator.calculateTotalBetAmount(records: records),
            totalReturnAmount: StatisticsCalculator.calculateTotalReturnAmount(records: records),
            totalProfit: StatisticsCalculator.calculateTotalProfit(records: records),
            averageBetAmount: StatisticsCalculator.calculateAverageBetAmount(records: records),
            averageProfit: StatisticsCalculator.calculateAverageProfit(records: records),
            maxWin: StatisticsCalculator.calculateMaxWin(records: records),
            maxLoss: StatisticsCalculator.calculateMaxLoss(records: records),
            winStreak: StatisticsCalculator.calculateWinStreak(records: records),
            lossStreak: StatisticsCalculator.calculateLossStreak(records: records),
            standardDeviation: StatisticsCalculator.calculateStandardDeviation(records: records),
            sharpeRatio: StatisticsCalculator.calculateSharpeRatio(records: records),
            totalBets: records.count,
            wins: wins,
            losses: losses
        )
    }
}
