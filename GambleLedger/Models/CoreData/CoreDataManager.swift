// GambleLedger/Models/CoreData/CoreDataManager.swift
import CoreData
import Foundation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistenceController = PersistenceController.shared
    private var viewContext: NSManagedObjectContext {
        return persistenceController.container.viewContext
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
        
        // 非同期で実行
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let results = try self.viewContext.fetch(request)
                completion(results)
            } catch {
                print("Error fetching bet records: \(error)")
                completion([])
            }
        }
    }
    
    // MARK: - ギャンブル種別の取得
    
    func fetchGambleTypes(completion: @escaping ([NSManagedObject]) -> Void) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "GambleType")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let results = try self.viewContext.fetch(request)
                completion(results)
            } catch {
                print("Error fetching gamble types: \(error)")
                completion([])
            }
        }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let results = try self.viewContext.fetch(request)
                completion(results.first)
            } catch {
                print("Error fetching budget: \(error)")
                completion(nil)
            }
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
        let context = viewContext
        
        context.performAndWait {
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
                completion(true)
            } catch {
                print("Failed to save bet record: \(error)")
                completion(false)
            }
        }
    }
    
    // ベット記録の削除メソッド追加
    func deleteBetRecord(id: UUID, completion: @escaping (Bool) -> Void) {
        let context = viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "BetRecord")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        context.perform {
            do {
                let records = try context.fetch(request)
                if let recordToDelete = records.first {
                    context.delete(recordToDelete)
                    try context.save()
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("Delete error: \(error)")
                completion(false)
            }
        }
    }
    
    // その他のCRUD操作メソッド省略
}
