// GambleLedger/Models/CoreData/CoreDataManager.swift
import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        return persistenceController.container.viewContext
    }
    
    // データ取得の新たな処理を追加
    private func executeAsyncFetch<T>(_ request: NSFetchRequest<T>, completion: @escaping ([T]) -> Void) where T: NSFetchRequestResult {
        // バックグラウンドコンテキストを作成して処理を実行
        let context = persistenceController.container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        
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
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
        let context = persistenceController.container.newBackgroundContext()
        
        context.perform {
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
            
            do {
                try context.save()
                
                // メインスレッドでコールバック実行
                DispatchQueue.main.async {
                    completion(true)
                }
            } catch {
                print("Failed to save bet record: \(error)")
                
                // メインスレッドでコールバック実行
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    // ベット記録の削除メソッド
    func deleteBetRecord(id: UUID, completion: @escaping (Bool) -> Void) {
        // バックグラウンドコンテキストで削除処理を実行
        let context = persistenceController.container.newBackgroundContext()
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let records = try context.fetch(request)
                if let recordToDelete = records.first {
                    context.delete(recordToDelete)
                    try context.save()
                    
                    DispatchQueue.main.async {
                        completion(true)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion(false)
                    }
                }
            } catch {
                print("Delete error: \(error)")
                
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
}
