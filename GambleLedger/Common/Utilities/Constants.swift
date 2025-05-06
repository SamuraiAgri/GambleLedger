// GambleLedger/Common/Utilities/Constants.swift
import SwiftUI

struct Constants {
    struct GambleTypes {
        // 競馬 - horseshoeを別のアイコンに変更
        static let horse = GambleTypeDefinition(
            name: "競馬",
            icon: "figure.equestrian", // iOS 16以降で使用可能なアイコン
            // アイコンがない場合の代替
            // icon: "crown.fill", // より一般的なアイコン
            color: "#00ACC1"
        )
        
        // 競艇
        static let boat = GambleTypeDefinition(
            name: "競艇",
            icon: "sailboat.fill",
            color: "#039BE5"
        )
        
        // 競輪
        static let bike = GambleTypeDefinition(
            name: "競輪",
            icon: "bicycle.circle.fill",
            color: "#8E24AA"
        )
        
        // スポーツベット
        static let sports = GambleTypeDefinition(
            name: "スポーツ",
            icon: "sportscourt.fill",
            color: "#7B1FA2"
        )
        
        // パチンコ
        static let pachinko = GambleTypeDefinition(
            name: "パチンコ",
            icon: "dollarsign.circle.fill",
            color: "#FFC107"
        )
        
        // その他
        static let other = GambleTypeDefinition(
            name: "その他",
            icon: "dice.fill",
            color: "#00ACC1"
        )
    }
    
    struct Budget {
        static let defaultMonthlyAmount: Decimal = 30000
        static let defaultWarningThreshold: Int = 60 // 予算の60%で警告
        static let defaultDangerThreshold: Int = 80  // 予算の80%で危険警告
    }
    
    struct Notifications {
        // 予算関連通知
        static let budgetWarningTitle = "予算警告"
        static let budgetWarningBody = "予算の%d%%を消化しました。注意しましょう。"
        static let budgetDangerTitle = "予算危険"
        static let budgetDangerBody = "予算の%d%%を消化しました！残りの予算を慎重に使いましょう。"
        
        // 連敗警告
        static let consecutiveLossTitle = "連敗警告"
        static let consecutiveLossBody = "%d連敗中です。ベット額の見直しを検討しましょう。"
    }
}

// ギャンブル種別の定義
struct GambleTypeDefinition {
    let name: String
    let icon: String
    let color: String
}
