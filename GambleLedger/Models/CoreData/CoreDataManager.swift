// GambleLedger/Models/CoreData/CoreDataManager.swift
import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // バックグラウンド処理用のコンテキスト作成
    private func createBackgroundContext() -> NSManagedObjectContext {
        let context = persistenceController.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // データ取得の新たな処理を追加
    private func executeAsyncFetch<T>(_ request: NSFetchRequest<T>, completion: @escaping ([T]) -> Void) where T: NSFetchRequestResult {
        // バックグラウンドコンテキストを作成して処理を実行
        let context = createBackgroundContext()
        
        context.perform {
            do {
                let results = try context.fetch(request)
                completion(results)
            } catch {
                print("Error executing fetch request: \(error)")
                completion([])
            }
        }
    }
    
    // MARK: - ベット記録の取得
    
    func fetchBetRecords(
        startDate: Date? = nil,
        endDate: Date? = nil,
        gambleTypeID: UUID? = nil,
        limit: Int = 0,
        completion: @escaping ([NSManagedObject]) -> Void
    ) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        
        // 条件設定
        var predicates: [NSPredicate] = []
        
        if let startDate = startDate, let endDate = endDate {
            predicates.append(NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate))
        }
        
        if let gambleTypeID = gambleTypeID {
            predicates.append(NSPredicate(format: "gambleTypeID == %@", gambleTypeID as CVarArg))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // ソート
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        // 制限
        if limit > 0 {
            request.fetchLimit = limit
        }
        
        // 改善したフェッチ実行
        executeAsyncFetch(request, completion: completion)
    }
    
    // MARK: - ギャンブル種別の取得
    
    func fetchGambleTypes(completion: @escaping ([NSManagedObject]) -> Void) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "GambleType")
        // ソートを削除して、挿入順を保持
        
        // 改善したフェッチ実行
        executeAsyncFetch(request, completion: completion)
    }
    
    // MARK: - 予算の取得
    
    func fetchCurrentBudget(
        forDate date: Date = Date(),
        gambleTypeID: UUID? = nil,
        completion: @escaping (NSManagedObject?) -> Void
    ) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "Budget")
        
        var predicates: [NSPredicate] = [
            NSPredicate(format: "startDate <= %@ AND endDate >= %@", date as NSDate, date as NSDate)
        ]
        
        if let gambleTypeID = gambleTypeID {
            predicates.append(NSPredicate(format: "gambleTypeID == %@", gambleTypeID as CVarArg))
        } else {
            predicates.append(NSPredicate(format: "gambleTypeID == nil"))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // 改善したフェッチ実行
        executeAsyncFetch(request) { results in
            completion(results.first)
        }
    }
    
    // MARK: - 単一のベット記録を取得
    
    func fetchBetRecord(id: UUID, completion: @escaping (NSManagedObject?) -> Void) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        executeAsyncFetch(request) { results in
            completion(results.first)
        }
    }
    
    // MARK: - データの保存
    
    func saveBetRecord(
        date: Date,
        gambleTypeID: UUID,
        eventName: String,
        bettingSystem: String,
        betAmount: Decimal,
        returnAmount: Decimal,
        memo: String = "",
        completion: @escaping (Bool) -> Void
    ) {
        // バックグラウンドコンテキストで保存処理を実行
        let context = createBackgroundContext()
        
        context.perform {
            do {
                let newRecord = NSEntityDescription.insertNewObject(forEntityName: "BetRecord", into: context)
                
                newRecord.setValue(UUID(), forKey: "id")
                newRecord.setValue(date, forKey: "date")
                newRecord.setValue(gambleTypeID, forKey: "gambleTypeID")
                newRecord.setValue(eventName, forKey: "eventName")
                newRecord.setValue(bettingSystem, forKey: "bettingSystem")
                newRecord.setValue(NSDecimalNumber(decimal: betAmount), forKey: "betAmount")
                newRecord.setValue(NSDecimalNumber(decimal: returnAmount), forKey: "returnAmount")
                newRecord.setValue(memo, forKey: "memo")
                newRecord.setValue(returnAmount > betAmount, forKey: "isWin")
                newRecord.setValue(Date(), forKey: "createdAt")
                newRecord.setValue(Date(), forKey: "updatedAt")
                
                try context.save()
                
                // メインスレッドでコールバック実行
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Failed to save bet record: \(error)")
                
                // エラー時にロールバック
                context.rollback()
                
                // メインスレッドでコールバック実行
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // ベット記録の更新メソッド
    func updateBetRecord(
        id: UUID,
        date: Date,
        gambleTypeID: UUID,
        eventName: String,
        bettingSystem: String,
        betAmount: Decimal,
        returnAmount: Decimal,
        memo: String = "",
        completion: @escaping (Bool, String?) -> Void
    ) {
        let context = createBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let records = try context.fetch(request)
                guard let recordToUpdate = records.first else {
                    DispatchQueue.main.async {
                        completion(false, "更新対象の記録が見つかりませんでした。")
                    }
                    return
                }
                
                // 値を更新
                recordToUpdate.setValue(date, forKey: "date")
                recordToUpdate.setValue(gambleTypeID, forKey: "gambleTypeID")
                recordToUpdate.setValue(eventName, forKey: "eventName")
                recordToUpdate.setValue(bettingSystem, forKey: "bettingSystem")
                recordToUpdate.setValue(NSDecimalNumber(decimal: betAmount), forKey: "betAmount")
                recordToUpdate.setValue(NSDecimalNumber(decimal: returnAmount), forKey: "returnAmount")
                recordToUpdate.setValue(memo, forKey: "memo")
                recordToUpdate.setValue(returnAmount > betAmount, forKey: "isWin")
                recordToUpdate.setValue(Date(), forKey: "updatedAt")
                
                try context.save()
                
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                print("Update error: \(error)")
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false, "更新中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ベット記録の削除メソッド
    func deleteBetRecord(id: UUID, completion: @escaping (Bool, String?) -> Void) {
        // バックグラウンドコンテキストで削除処理を実行
        let context = createBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let records = try context.fetch(request)
                if let recordToDelete = records.first {
                    context.delete(recordToDelete)
                    try context.save()
                    
                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "削除対象の記録が見つかりませんでした。")
                    }
                }
            } catch {
                print("Delete error: \(error)")
                
                // エラー時にロールバック
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false, "削除中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 予算の更新メソッド
    func updateBudget(
        id: UUID,
        amount: Decimal,
        startDate: Date,
        endDate: Date,
        notifyThreshold: Int,
        gambleTypeID: UUID? = nil,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let context = createBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "Budget")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let budgets = try context.fetch(request)
                guard let budgetToUpdate = budgets.first else {
                    DispatchQueue.main.async {
                        completion(false, "更新対象の予算が見つかりませんでした。")
                    }
                    return
                }
                
                // 値を更新
                budgetToUpdate.setValue(NSDecimalNumber(decimal: amount), forKey: "amount")
                budgetToUpdate.setValue(startDate, forKey: "startDate")
                budgetToUpdate.setValue(endDate, forKey: "endDate")
                budgetToUpdate.setValue(notifyThreshold, forKey: "notifyThreshold")
                budgetToUpdate.setValue(gambleTypeID, forKey: "gambleTypeID")
                budgetToUpdate.setValue(Date(), forKey: "updatedAt")
                
                try context.save()
                
                DispatchQueue.main.async {
                    completion(true, nil)
                }
            } catch {
                print("Update budget error: \(error)")
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false, "予算の更新中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // 予算の削除メソッド
    func deleteBudget(id: UUID, completion: @escaping (Bool, String?) -> Void) {
        let context = createBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "Budget")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let budgets = try context.fetch(request)
                if let budgetToDelete = budgets.first {
                    context.delete(budgetToDelete)
                    try context.save()
                    
                    DispatchQueue.main.async {
                        completion(true, nil)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false, "削除対象の予算が見つかりませんでした。")
                    }
                }
            } catch {
                print("Delete budget error: \(error)")
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false, "予算の削除中にエラーが発生しました: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - 予算の保存
    
    func saveBudget(
        id: UUID = UUID(),
        amount: Decimal,
        startDate: Date,
        endDate: Date,
        notifyThreshold: Int,
        gambleTypeID: UUID? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        let context = createBackgroundContext()
        
        context.perform {
            do {
                // 既存の予算をチェック（期間が重複する場合は更新）
                let existingBudgetRequest = NSFetchRequest<NSManagedObject>(entityName: "Budget")
                
                var predicates: [NSPredicate] = [
                    NSPredicate(format: "(startDate <= %@ AND endDate >= %@) OR (startDate <= %@ AND endDate >= %@)",
                               endDate as NSDate, startDate as NSDate,
                               startDate as NSDate, startDate as NSDate)
                ]
                
                if let gambleTypeID = gambleTypeID {
                    predicates.append(NSPredicate(format: "gambleTypeID == %@", gambleTypeID as CVarArg))
                } else {
                    predicates.append(NSPredicate(format: "gambleTypeID == nil"))
                }
                
                existingBudgetRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                
                let existingBudgets = try context.fetch(existingBudgetRequest)
                
                // 既存予算の削除（同期間の予算を更新するため）
                for existingBudget in existingBudgets {
                    context.delete(existingBudget)
                }
                
                // 新規予算の作成
                let budgetObject = NSEntityDescription.insertNewObject(forEntityName: "Budget", into: context)
                budgetObject.setValue(id, forKey: "id")
                budgetObject.setValue(NSDecimalNumber(decimal: amount), forKey: "amount")
                budgetObject.setValue(startDate, forKey: "startDate")
                budgetObject.setValue(endDate, forKey: "endDate")
                budgetObject.setValue(notifyThreshold, forKey: "notifyThreshold")
                budgetObject.setValue(gambleTypeID, forKey: "gambleTypeID")
                budgetObject.setValue(Date(), forKey: "createdAt")
                budgetObject.setValue(Date(), forKey: "updatedAt")
                
                // デバッグ出力
                print("保存する予算: 期間[\(startDate) - \(endDate)], 金額: \(amount)")
                
                // 保存を試行
                try context.save()
                print("予算の保存に成功しました")
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("予算の保存に失敗しました: \(error)")
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - ギャンブル種別の保存
    
    func saveGambleType(
        id: UUID,
        name: String,
        icon: String,
        color: String,
        completion: @escaping (Bool) -> Void
    ) {
        let context = createBackgroundContext()
        
        context.perform {
            do {
                // 既存の種別をチェック
                let request = NSFetchRequest<NSManagedObject>(entityName: "GambleType")
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                let existingTypes = try context.fetch(request)
                
                let gambleType: NSManagedObject
                
                if let existingType = existingTypes.first {
                    // 既存の種別を更新
                    gambleType = existingType
                } else {
                    // 新規作成
                    gambleType = NSEntityDescription.insertNewObject(forEntityName: "GambleType", into: context)
                    gambleType.setValue(id, forKey: "id")
                    gambleType.setValue(Date(), forKey: "createdAt")
                }
                
                // 値を設定
                gambleType.setValue(name, forKey: "name")
                gambleType.setValue(icon, forKey: "icon")
                gambleType.setValue(color, forKey: "color")
                gambleType.setValue(Date(), forKey: "updatedAt")
                
                try context.save()
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Failed to save gamble type: \(error)")
                
                // エラー時にロールバック
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - ギャンブル種別の全削除（リセット用）
    func deleteAllGambleTypes(completion: @escaping (Bool) -> Void) {
        let context = createBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "GambleType")
        
        context.perform {
            do {
                let results = try context.fetch(request)
                for object in results {
                    context.delete(object)
                }
                
                try context.save()
                
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Failed to delete all gamble types: \(error)")
                context.rollback()
                
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
