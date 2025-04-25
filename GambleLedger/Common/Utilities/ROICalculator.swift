// GambleLedger/Common/Utilities/ROICalculator.swift
import Foundation

class ROICalculator {
    // 基本的なROI計算（投資利回り）
    static func calculateROI(betAmount: Decimal, returnAmount: Decimal) -> Decimal {
        if betAmount == 0 { return 0 }
        return ((returnAmount / betAmount) - 1) * 100
    }
    
    // 損益計算
    static func calculateProfit(betAmount: Decimal, returnAmount: Decimal) -> Decimal {
        return returnAmount - betAmount
    }
    
    // 勝率計算
    static func calculateWinRate(totalBets: Int, wins: Int) -> Double {
        if totalBets == 0 { return 0 }
        return Double(wins) / Double(totalBets) * 100
    }
    
    // ケリー基準によるベット額計算
    // b: オッズ（配当率）、p: 勝率（0〜1）、bankroll: 資金
    static func calculateKellyCriterion(odds: Decimal, probability: Decimal, bankroll: Decimal) -> Decimal {
        // ケリー基準: f* = (p(b+1) - 1) / b
        // ここで、f*は賭け比率、pは勝率、bはオッズ-1
        
        let b = odds - 1
        if b <= 0 || probability <= 0 || probability >= 1 { return 0 }
        
        let kellyCriterion = (probability * (b + 1) - 1) / b
        
        // 負の値（賭けるべきでない）または過度に高い値の場合は調整
        if kellyCriterion <= 0 { return 0 }
        
        // 通常、ケリー基準の半分（ハーフケリー）が推奨される
        let halfKelly = kellyCriterion / 2
        
        // 最大でも資金の25%までに制限
        let maxBetRatio: Decimal = 0.25
        let betRatio = min(halfKelly, maxBetRatio)
        
        return bankroll * betRatio
    }
    
    // 移動平均ROI計算（直近N回分）
    static func calculateMovingAverageROI(betAmounts: [Decimal], returnAmounts: [Decimal], windowSize: Int) -> [Decimal] {
        guard betAmounts.count == returnAmounts.count else { return [] }
        
        let totalCount = betAmounts.count
        if totalCount == 0 { return [] }
        
        var result: [Decimal] = []
        
        for i in 0..<totalCount {
            let startIndex = max(0, i - windowSize + 1)
            let currentWindowSize = i - startIndex + 1
            
            var windowBetSum: Decimal = 0
            var windowReturnSum: Decimal = 0
            
            for j in startIndex...i {
                windowBetSum += betAmounts[j]
                windowReturnSum += returnAmounts[j]
            }
            
            let roi = windowBetSum > 0 ? ((windowReturnSum / windowBetSum) - 1) * 100 : 0
            result.append(roi)
        }
        
        return result
    }
    
    // 最適なベット額の計算（予算と連敗状況を考慮）
    static func suggestBetAmount(
        budget: Decimal,
        usedBudget: Decimal,
        consecutiveLosses: Int,
        averageBetAmount: Decimal,
        winRate: Decimal
    ) -> Decimal {
        // 残りの予算
        let remainingBudget = max(0, budget - usedBudget)
        if remainingBudget <= 0 { return 0 }
        
        // 基本ベット額（平均または残予算の5%のいずれか小さい方）
        var baseBetAmount = min(averageBetAmount, remainingBudget * Decimal(0.05))
        
        // 連敗による減額係数
        let lossReduceFactor: Decimal
        switch consecutiveLosses {
        case 0...2:
            lossReduceFactor = 1.0  // 通常
        case 3...4:
            lossReduceFactor = 0.8  // 少し減額
        case 5...6:
            lossReduceFactor = 0.6  // 減額
        case 7...8:
            lossReduceFactor = 0.4  // かなり減額
        default:
            lossReduceFactor = 0.25 // 大幅減額
        }
        
        // 勝率による調整係数
        let winRateFactor: Decimal
        switch winRate {
        case 0..<Decimal(0.2):
            winRateFactor = 0.7  // 低勝率
        case Decimal(0.2)..<Decimal(0.4):
            winRateFactor = 0.9  // やや低勝率
        case Decimal(0.4)..<Decimal(0.6):
            winRateFactor = 1.0  // 通常
        case Decimal(0.6)..<Decimal(0.8):
            winRateFactor = 1.1  // やや高勝率
        default:
            winRateFactor = 1.2  // 高勝率
        }
        
        // 予算消化率による調整
        let budgetUsageRatio = usedBudget / budget
        let budgetFactor: Decimal
        if budgetUsageRatio > Decimal(0.9) {
            budgetFactor = 0.5  // 予算の90%以上使用
        } else if budgetUsageRatio > Decimal(0.7) {
            budgetFactor = 0.7  // 予算の70%以上使用
        } else if budgetUsageRatio < Decimal(0.3) {
            budgetFactor = 1.1  // 予算の30%未満使用
        } else {
            budgetFactor = 1.0  // 通常
        }
        
        // 最終的なベット額を計算
        baseBetAmount = baseBetAmount * lossReduceFactor * winRateFactor * budgetFactor
        
        // 最小ベット額と残予算のチェック
        let minBetAmount: Decimal = 100  // 最小ベット額（100円）
        baseBetAmount = max(minBetAmount, baseBetAmount)
        
        // 残予算を超えないようにする
        return min(baseBetAmount, remainingBudget)
    }
}
