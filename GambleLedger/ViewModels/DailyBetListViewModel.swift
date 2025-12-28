// GambleLedger/ViewModels/DailyBetListViewModel.swift
import Foundation
import CoreData
import SwiftUI

@MainActor
class DailyBetListViewModel: ObservableObject {
    @Published var records: [DailyBetRecord] = []
    @Published var totalBet: Decimal = 0
    @Published var totalReturn: Decimal = 0
    @Published var profit: Decimal = 0
    @Published var isLoading: Bool = false
    
    private let date: Date
    private let coreDataManager: CoreDataManager
    
    init(date: Date, coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.date = date
        self.coreDataManager = coreDataManager
        loadRecords()
    }
    
    func loadRecords() {
        isLoading = true
        
        // 指定日の開始と終了を取得
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        coreDataManager.fetchBetRecords(
            startDate: startOfDay,
            endDate: endOfDay
        ) { [weak self] fetchedRecords in
            guard let self = self else { return }
            
            // NSManagedObjectをDailyBetRecordに変換
            let models = fetchedRecords.compactMap { record -> DailyBetRecord? in
                guard let id = record.value(forKey: "id") as? UUID,
                      let date = record.value(forKey: "date") as? Date else {
                    return nil
                }
                
                // gambleTypeのリレーションから名前を取得
                var gambleTypeName = "不明"
                if let gambleTypeObject = record.value(forKey: "gambleType") as? NSManagedObject {
                    gambleTypeName = gambleTypeObject.value(forKey: "name") as? String ?? "不明"
                }
                
                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                let memo = record.value(forKey: "memo") as? String ?? ""
                let profit = returnAmount - betAmount
                
                return DailyBetRecord(
                    id: id.uuidString,
                    date: date,
                    gambleTypeName: gambleTypeName,
                    betAmount: betAmount,
                    returnAmount: returnAmount,
                    profit: profit,
                    memo: memo
                )
            }
            
            // 時刻順にソート（新しい順）
            let sortedModels = models.sorted { $0.date > $1.date }
            
            // 合計を計算
            let totalBet = models.reduce(Decimal(0)) { $0 + $1.betAmount }
            let totalReturn = models.reduce(Decimal(0)) { $0 + $1.returnAmount }
            let profit = totalReturn - totalBet
            
            DispatchQueue.main.async {
                self.records = sortedModels
                self.totalBet = totalBet
                self.totalReturn = totalReturn
                self.profit = profit
                self.isLoading = false
            }
        }
    }
    
    func deleteRecord(id: String) {
        guard let uuid = UUID(uuidString: id) else {
            print("Invalid UUID string: \(id)")
            return
        }
        
        coreDataManager.deleteBetRecord(id: uuid) { [weak self] success, error in
            if success {
                DispatchQueue.main.async {
                    self?.loadRecords()
                }
            } else if let error = error {
                print("Delete error: \(error)")
            }
        }
    }
    
    /// UUIDから完全なBetRecordModelを取得
    func getBetRecordModel(for id: UUID) -> BetRecordModel? {
        var result: BetRecordModel?
        let semaphore = DispatchSemaphore(value: 0)
        
        coreDataManager.fetchBetRecord(id: id) { record in
            if let record = record {
                result = BetRecordModel.fromManagedObject(record)
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
}
