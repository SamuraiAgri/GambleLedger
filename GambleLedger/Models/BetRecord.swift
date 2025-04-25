// GambleLedger/Models/BetRecord.swift
import Foundation
import CoreData
import SwiftUI

// BetRecord用のデータ構造体
struct BetRecordModel: Identifiable {
    var id: UUID
    var date: Date
    var gambleTypeID: UUID
    var eventName: String
    var bettingSystem: String
    var betAmount: Decimal
    var returnAmount: Decimal
    var memo: String
    var isWin: Bool
    var createdAt: Date
    var updatedAt: Date
    
    // 計算プロパティ
    var profit: Decimal {
        returnAmount - betAmount
    }
    
    var roi: Decimal {
        if betAmount == 0 { return 0 }
        return ((returnAmount / betAmount) - 1) * 100
    }
    
    // NSManagedObjectからの変換
    static func fromManagedObject(_ object: NSManagedObject) -> BetRecordModel {
        let id = object.value(forKey: "id") as? UUID ?? UUID()
        let date = object.value(forKey: "date") as? Date ?? Date()
        let gambleTypeID = object.value(forKey: "gambleTypeID") as? UUID ?? UUID()
        let eventName = object.value(forKey: "eventName") as? String ?? ""
        let bettingSystem = object.value(forKey: "bettingSystem") as? String ?? ""
        let betAmount = (object.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
        let returnAmount = (object.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
        let memo = object.value(forKey: "memo") as? String ?? ""
        let isWin = object.value(forKey: "isWin") as? Bool ?? false
        let createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
        
        return BetRecordModel(
            id: id,
            date: date,
            gambleTypeID: gambleTypeID,
            eventName: eventName,
            bettingSystem: bettingSystem,
            betAmount: betAmount,
            returnAmount: returnAmount,
            memo: memo,
            isWin: isWin,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // 表示用のモデルに変換
    func toDisplayModel(with gambleType: GambleTypeModel?) -> BetDisplayModel {
        return BetDisplayModel(
            id: id.uuidString,
            date: date,
            gambleType: gambleType?.name ?? "不明",
            gambleTypeColor: gambleType?.color ?? .gray,
            eventName: eventName,
            bettingSystem: bettingSystem,
            betAmount: NSDecimalNumber(decimal: betAmount).doubleValue,
            returnAmount: NSDecimalNumber(decimal: returnAmount).doubleValue,
            isWin: isWin
        )
    }
    
    // 新規作成用の空モデル
    static func empty() -> BetRecordModel {
        return BetRecordModel(
            id: UUID(),
            date: Date(),
            gambleTypeID: UUID(),
            eventName: "",
            bettingSystem: "",
            betAmount: 0,
            returnAmount: 0,
            memo: "",
            isWin: false,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// 表示用のモデル（UI表示に最適化）
struct BetDisplayModel: Identifiable {
    let id: String
    let date: Date
    let gambleType: String
    let gambleTypeColor: Color
    let eventName: String
    let bettingSystem: String
    let betAmount: Double
    let returnAmount: Double
    let isWin: Bool
    
    var profit: Double {
        returnAmount - betAmount
    }
    
    var roi: Double {
        if betAmount == 0 { return 0 }
        return ((returnAmount / betAmount) - 1) * 100
    }
    
    // フォーマット済みの文字列
    var formattedDate: String {
        date.formattedString(format: "yyyy/MM/dd HH:mm")
    }
    
    var formattedBetAmount: String {
        String(format: "¥%@", betAmount.formattedWithSeparator())
    }
    
    var formattedReturnAmount: String {
        String(format: "¥%@", returnAmount.formattedWithSeparator())
    }
    
    var formattedProfit: String {
        String(format: "¥%@", profit.formattedWithSeparator())
    }
    
    var formattedROI: String {
        String(format: "%.1f%%", roi)
    }
}

// Double型の拡張（金額のフォーマット用）
extension Double {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}
