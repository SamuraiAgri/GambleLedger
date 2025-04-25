// GambleLedger/ViewModels/BudgetViewModel.swift
import Foundation
import Combine
import SwiftUI

class BudgetViewModel: ObservableObject {
    // 入力フィールド
    @Published var budgetAmount: String = ""
    @Published var selectedStartDate: Date = Date().startOfMonth()
    @Published var selectedEndDate: Date = Date().endOfMonth()
    @Published var notifyThreshold: Int = 80
    @Published var selectedGambleTypeID: UUID?
    
    // 表示データ
    @Published var currentBudget: BudgetDisplayModel?
    @Published var gambleTypeBudgets: [BudgetDisplayModel] = []
    @Published var totalSpentAmount: Decimal = 0
    @Published var budgetProgress: Double = 0
    
    // 状態管理
    @Published var isLoading: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var gambleTypes: [GambleTypeModel] = []
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        
        // ギャンブル種別のロード
        loadGambleTypes()
        
        // 予算データのロード
        loadBudgetData()
    }
    
    // ギャンブル種別のロード
    private func loadGambleTypes() {
        isLoading = true
        
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            let types = results.compactMap { GambleTypeModel.fromManagedObject($0) }
            
            DispatchQueue.main.async {
                self.gambleTypes = types
                self.isLoading = false
            }
        }
    }
    
    // 予算データのロード
    func loadBudgetData() {
        isLoading = true
        
        // 全体予算の取得
        loadMainBudget()
        
        // ギャンブル種別ごとの予算取得
        loadGambleTypeBudgets()
    }
    
    // メイン予算の取得
    private func loadMainBudget() {
        let today = Date()
        
        coreDataManager.fetchCurrentBudget(forDate: today) { [weak self] budgetObject in
            guard let self = self else { return }
            
            if let budgetObject = budgetObject {
                let budget = BudgetModel.fromManagedObject(budgetObject)
                
                // 使用額を計算
                self.calculateSpentAmount(startDate: budget.startDate, endDate: budget.endDate) { spentAmount in
                    DispatchQueue.main.async {
                        self.totalSpentAmount = spentAmount
                        self.currentBudget = budget.toDisplayModel(with: nil, usedAmount: spentAmount)
                        self.budgetProgress = Double(truncating: (spentAmount / budget.amount) as NSNumber)
                        self.isLoading = false
                    }
                }
            } else {
                // 予算が未設定の場合はデフォルト値を表示
                let defaultBudget = BudgetModel.createMonthlyBudget(amount: Constants.Budget.defaultMonthlyAmount)
                
                DispatchQueue.main.async {
                    self.currentBudget = defaultBudget.toDisplayModel(with: nil, usedAmount: 0)
                    self.budgetProgress = 0
                    self.isLoading = false
                    
                    // 未設定の場合は予算入力欄にデフォルト値をセット
                    self.budgetAmount = String(describing: Constants.Budget.defaultMonthlyAmount)
                }
            }
        }
    }
    
    // ギャンブル種別ごとの予算取得
    private func loadGambleTypeBudgets() {
        // 実装を省略（実際のアプリでは各ギャンブル種別の予算を取得・計算）
        DispatchQueue.main.async {
            self.gambleTypeBudgets = []  // 空の配列をセット
        }
    }
    
    // 使用金額の計算
    private func calculateSpentAmount(startDate: Date, endDate: Date, completion: @escaping (Decimal) -> Void) {
        coreDataManager.fetchBetRecords(startDate: startDate, endDate: endDate) { records in
            let totalBet = records.reduce(Decimal(0)) { total, record in
                let betAmount = (record.value(forKey: "betAmount") as? NSDecimalNumber)?.decimalValue ?? Decimal(0)
                return total + betAmount
            }
            
            completion(totalBet)
        }
    }
    
    // 予算の保存
    func saveBudget() {
        guard validateInput() else { return }
        
        isLoading = true
        
        guard let amountDecimal = Decimal(string: budgetAmount.replacingOccurrences(of: ",", with: "")) else {
            showError(message: "入力金額の変換に失敗しました。")
            return
        }
        
        // 予算データの作成
        let budgetData = BudgetModel(
            id: UUID(),
            amount: amountDecimal,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            notifyThreshold: notifyThreshold,
            gambleTypeID: selectedGambleTypeID,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        // TODO: CoreDataに保存する処理を実装
        
        DispatchQueue.main.async {
            self.isLoading = false
            self.showSuccessMessage = true
            
            // 成功メッセージを3秒後に非表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showSuccessMessage = false
            }
            
            // データを再読み込み
            self.loadBudgetData()
        }
    }
    
    // 入力検証
    private func validateInput() -> Bool {
        // 金額の入力チェック
        if budgetAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "予算金額を入力してください。")
            return false
        }
        
        // 数値変換チェック
        if Decimal(string: budgetAmount.replacingOccurrences(of: ",", with: "")) == nil {
            showError(message: "有効な金額を入力してください。")
            return false
        }
        
        // 日付範囲チェック
        if selectedEndDate < selectedStartDate {
            showError(message: "終了日は開始日以降に設定してください。")
            return false
        }
        
        return true
    }
    
    // エラー表示
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
}
