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
    @Published var isSaving: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var gambleTypes: [GambleTypeModel] = []
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        setupBindings()
        
        // ギャンブル種別のロード
        loadGambleTypes()
        
        // 予算データのロード
        loadBudgetData()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // バインディングの設定
    private func setupBindings() {
        // 金額入力のフォーマット処理
        $budgetAmount
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.formatAmountInput(value: value) { formatted in
                    if formatted != value {
                        self?.budgetAmount = formatted
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // 金額入力のフォーマット
    private func formatAmountInput(value: String, completion: @escaping (String) -> Void) {
        // すでにカンマが含まれている場合はスキップ
        if value.contains(",") && !value.hasSuffix(",") {
            return
        }
        
        // 数字以外を除去
        let numbersOnly = value.filter { "0123456789".contains($0) }
        
        // 空なら空文字を返す
        if numbersOnly.isEmpty {
            completion("")
            return
        }
        
        // 数値を整形
        if let intValue = Int(numbersOnly) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = ","
            
            if let formattedString = formatter.string(from: NSNumber(value: intValue)) {
                completion(formattedString)
            } else {
                completion(numbersOnly)
            }
        } else {
            completion(numbersOnly)
        }
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
                    if self.budgetAmount.isEmpty {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .decimal
                        formatter.groupingSeparator = ","
                        if let formattedString = formatter.string(from: NSDecimalNumber(decimal: Constants.Budget.defaultMonthlyAmount)) {
                            self.budgetAmount = formattedString
                        } else {
                            self.budgetAmount = "\(Constants.Budget.defaultMonthlyAmount)"
                        }
                    }
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

    func saveBudget() {
        guard validateInput() else { return }
        
        isLoading = true
        isSaving = true
        
        // カンマを除去して処理
        let amountText = budgetAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let amountDecimal = Decimal(string: amountText) else {
            self.displayError(message: "入力金額の変換に失敗しました。")
            return
        }
        
        // 予算データの作成
        let budgetID = UUID()
        
        print("予算保存開始: \(amountDecimal)円, 期間[\(selectedStartDate) - \(selectedEndDate)]")
        
        coreDataManager.saveBudget(
            id: budgetID,
            amount: amountDecimal,
            startDate: selectedStartDate,
            endDate: selectedEndDate,
            notifyThreshold: notifyThreshold,
            gambleTypeID: selectedGambleTypeID
        ) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isSaving = false
                
                if success {
                    print("予算保存成功")
                    self.showSuccessMessage = true
                    self.generateHapticFeedback()
                    
                    // 成功メッセージを3秒後に非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                    
                    // データを再読み込み
                    self.loadBudgetData()
                } else {
                    print("予算保存失敗")
                    self.displayError(message: "予算の保存に失敗しました。もう一度お試しください。")
                }
            }
        }
    }
    
    // 触覚フィードバック
    private func generateHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // 入力検証
    private func validateInput() -> Bool {
        // 金額の入力チェック
        if budgetAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            displayError(message: "予算金額を入力してください。")
            return false
        }
        
        // 数値変換チェック
        let amountText = budgetAmount.replacingOccurrences(of: ",", with: "")
        if Decimal(string: amountText) == nil {
            displayError(message: "有効な金額を入力してください。")
            return false
        }
        
        // 金額範囲チェック
        if let amount = Decimal(string: amountText), amount <= 0 || amount > 10000000 {
            displayError(message: "予算金額は1〜10,000,000円の範囲で入力してください。")
            return false
        }
        
        // 日付範囲チェック
        if selectedEndDate < selectedStartDate {
            displayError(message: "終了日は開始日以降に設定してください。")
            return false
        }
        
        return true
    }
    
    // エラー表示
    private func displayError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
        isSaving = false
    }
    
    // 予算期間を今月にセット
    func setCurrentMonth() {
        let today = Date()
        selectedStartDate = today.startOfMonth()
        selectedEndDate = today.endOfMonth()
    }
    
    // 予算期間を来月にセット
    func setNextMonth() {
        let calendar = Calendar.current
        if let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) {
            selectedStartDate = nextMonth.startOfMonth()
            selectedEndDate = nextMonth.endOfMonth()
        }
    }
}
