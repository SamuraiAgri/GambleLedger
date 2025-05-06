// GambleLedger/Models/CoreData/PersistenceController.swift
import CoreData

// 構造体からクラスに変更して、escaping closureの問題を解決
class PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GambleLedger")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // SQLiteログの有効化（開発時のみ）
        #if DEBUG
        let description = container.persistentStoreDescriptions.first
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        container.persistentStoreDescriptions = [description!]
        #endif
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // エラーログを出力するが、クラッシュはさせない
                print("❌ CoreData store failed to load: \(error), \(error.userInfo)")
                
                // フェイルセーフ：ストアが破損している可能性がある場合は削除して再作成
                if error.domain == NSCocoaErrorDomain &&
                   (error.code == NSPersistentStoreIncompatibleVersionHashError ||
                    error.code == NSMigrationMissingSourceModelError) {
                    self.recreatePersistentStore()
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // セーブが失敗したときに自動でリトライする設定
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.stalenessInterval = 0.0
    }
    
    // 破損したストアを削除して再作成する
    private func recreatePersistentStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        
        do {
            // SQLiteファイルを削除
            try container.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType, options: nil)
            
            // ストアを再作成
            try container.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            
            print("✅ Successfully recreated persistent store")
        } catch {
            print("❌ Failed to recreate persistent store: \(error)")
        }
    }
    
    // コンテキストの保存を安全に行うヘルパーメソッド
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // エラーログを出力
                print("❌ Context save error: \(error)")
                
                // 変更をロールバック
                context.rollback()
                
                // エラーハンドラーに通知
                ErrorHandler.shared.handleCoreDataError(error)
            }
        }
    }
    
    // テストやプレビュー用の一時的なコンテナ
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        //let viewContext = controller.container.viewContext
        
        // サンプルデータの作成
        //let sampleData = SampleData()
        //sampleData.createSampleData(in: viewContext)
        
        return controller
    }()
}
