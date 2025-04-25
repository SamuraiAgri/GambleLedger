// GambleLedger/Models/Budget.swift
import Foundation
import CoreData
import SwiftUI

// 予算データモデル
struct BudgetModel: Identifiable {
    var id: UUID
    var amount: Decimal
    var startDate: Date
    var endDate: Date
    var notifyThreshold: Int
    var gambleTypeID: UUID?
    var createdAt: Date
    var updatedAt: Date
    
    // NSManagedObjectからの変換
    static func fromManagedObject(_ object: NSManagedObject) -> BudgetModel {
        let id = object.value(forKey: "id") as? UUID ?? UUID()
        let amount = (object.value(forKey: "amount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
        let startDate = object.value(forKey: "startDate") as? Date ?? Date()
        let endDate = object.value(forKey: "endDate") as? Date ?? Date()
        let notifyThreshold = object.value(forKey: "notifyThreshold") as? Int ?? 80
        let gambleTypeID = object.value(forKey: "gambleTypeID") as? UUID
        let createdAt = object.value(forKey: "createdAt") as? Date ?? Date()
        let updatedAt = object.value(forKey: "updatedAt") as? Date ?? Date()
        
        return BudgetModel(
            id: id,
            amount: amount,
            startDate: startDate,
            endDate: endDate,
            notifyThreshold: notifyThreshold,
            gambleTypeID: gambleTypeID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // 表示用のモデルに変換
    func toDisplayModel(with gambleType: GambleTypeModel?, usedAmount: Decimal) -> BudgetDisplayModel {
        return BudgetDisplayModel(
            id: id.uuidString,
            period: "\(startDate.formattedString()) - \(endDate.formattedString())",
            totalAmount: amount,
            usedAmount: usedAmount,
            remainingAmount: amount - usedAmount,
            usagePercentage: amount > 0 ? Double(truncating: (usedAmount / amount * 100) as NSNumber) : 0,
            gambleType: gambleType?.name,
            gambleTypeColor: gambleType?.color ?? .gray
        )
    }
    
    // 新規予算の作成
    static func createMonthlyBudget(
        amount: Decimal,
        forDate date: Date = Date(),
        gambleTypeID: UUID? = nil
    ) -> BudgetModel {
        // calendar変数を削除し、直接メソッドを呼び出す
        let startOfMonth = date.startOfMonth()
        let endOfMonth = date.endOfMonth()
        
        return BudgetModel(
            id: UUID(),
            amount: amount,
            startDate: startOfMonth,
            endDate: endOfMonth,
            notifyThreshold: 80,  // デフォルト：80%で通知
            gambleTypeID: gambleTypeID,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// 予算の表示用モデル
struct BudgetDisplayModel: Identifiable {
    let id: String
    let period: String
    let totalAmount: Decimal
    let usedAmount: Decimal
    let remainingAmount: Decimal
    let usagePercentage: Double
    let gambleType: String?
    let gambleTypeColor: Color?
    
    // 予算状態
    var status: BudgetStatus {
        if usagePercentage >= 100 {
            return .depleted
        } else if usagePercentage >= 80 {
            return .danger
        } else if usagePercentage >= 60 {
            return .warning
        } else {
            return .good
        }
    }
    
    // 状態に応じた色
    var statusColor: Color {
        switch status {
        case .good:
            return .accentSuccess
        case .warning:
            return .accentWarning
        case .danger, .depleted:
            return .accentDanger
        }
    }
    
    // 状態に応じたメッセージ
    var statusMessage: String {
        switch status {
        case .good:
            return "予算は十分あります"
        case .warning:
            return "予算の60%以上を使用しています"
        case .danger:
            return "予算の80%以上を使用しています"
        case .depleted:
            return "予算を使い切りました"
        }
    }
    
    // フォーマット済みの文字列
    var formattedTotalAmount: String {
        totalAmount.formatted(.currency(code: "JPY"))
    }
    
    var formattedUsedAmount: String {
        usedAmount.formatted(.currency(code: "JPY"))
    }
        
    var formattedRemainingAmount: String {
        remainingAmount.formatted(.currency(code: "JPY"))
    }
        
    var formattedUsagePercentage: String {
        String(format: "%.1f%%", usagePercentage)
    }
}

// 予算状態の列挙型
enum BudgetStatus {
    case good       // 良好（0〜60%）
    case warning    // 警告（60〜80%）
    case danger     // 危険（80〜100%）
    case depleted   // 枯渇（100%以上）
}

// 予算関連のユーティリティ関数
struct BudgetUtility {
    // 今月の予算を取得または作成
    static func getCurrentMonthBudget(
        coreDataManager: CoreDataManager,
        completion: @escaping (BudgetModel) -> Void
    ) {
        coreDataManager.fetchCurrentBudget { budgetObject in
            if let budgetObject = budgetObject {
                let budget = BudgetModel.fromManagedObject(budgetObject)
                completion(budget)
            } else {
                // 予算が見つからない場合はデフォルト予算を作成
                let defaultBudget = BudgetModel.createMonthlyBudget(
                    amount: Constants.Budget.defaultMonthlyAmount
                )
                
                // TODO: CoreDataに保存するコードを追加
                
                completion(defaultBudget)
            }
        }
    }
    
    // 予算の使用状況をチェックし、必要に応じて通知を送信
    static func checkBudgetUsage(
        budget: BudgetModel,
        usedAmount: Decimal
    ) {
        guard budget.amount > 0 else { return }
        
        let usagePercentage = Int(truncating: (usedAmount / budget.amount * 100) as NSNumber)
        
        // 予算警告通知
        if usagePercentage >= budget.notifyThreshold && usagePercentage < Constants.Budget.defaultDangerThreshold {
            NotificationManager.shared.scheduleBudgetWarning(percentage: usagePercentage)
        }
        
        // 予算危険通知
        if usagePercentage >= Constants.Budget.defaultDangerThreshold {
            NotificationManager.shared.scheduleBudgetDanger(percentage: usagePercentage)
        }
    }
}
