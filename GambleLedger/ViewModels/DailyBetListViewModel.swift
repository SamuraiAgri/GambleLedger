// GambleLedger/ViewModels/DailyBetListViewModel.swift
import Foundation
import CoreData
import SwiftUI

@MainActor
class DailyBetListViewModel: ObservableObject {
    @Published var records: [BetRecordModel] = []
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
            
            // NSManagedObjectをBetRecordModelに変換
            let models = fetchedRecords.compactMap { record -> BetRecordModel? in
                guard let id = record.value(forKey: "id") as? String,
                      let date = record.value(forKey: "date") as? Date,
                      let gambleTypeName = record.value(forKey: "gambleType") as? String else {
                    return nil
                }
                
                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                let returnAmount = (record.value(forKey: "returnAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                let memo = record.value(forKey: "memo") as? String ?? ""
                let profit = returnAmount - betAmount
                
                return BetRecordModel(
                    id: id,
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
        coreDataManager.deleteBetRecord(id: id) { [weak self] success in
            if success {
                DispatchQueue.main.async {
                    self?.loadRecords()
                }
            }
        }
    }
}
