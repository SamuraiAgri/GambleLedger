// GambleLedger/Common/Utilities/Constants.swift
import SwiftUI

struct Constants {
    struct GambleTypes {
        // パチンコ
        static let pachinko = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "パチンコ",
            icon: "dollarsign.circle.fill",
            color: "#FFC107"
        )
        
        // 競馬
        static let horse = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "競馬",
            icon: "🏇",
            color: "#D32F2F"
        )
        
        // 競艇
        static let boat = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            name: "競艇",
            icon: "sailboat.fill",
            color: "#039BE5"
        )
        
        // 競輪
        static let bike = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            name: "競輪",
            icon: "bicycle.circle.fill",
            color: "#8E24AA"
        )
        
        // スポーツベット
        static let sports = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            name: "スポーツ",
            icon: "sportscourt.fill",
            color: "#7B1FA2"
        )
        
        // その他
        static let other = GambleTypeDefinition(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
            name: "その他",
            icon: "dice.fill",
            color: "#78909C"
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
    let id: UUID
    let name: String
    let icon: String
    let color: String
}
