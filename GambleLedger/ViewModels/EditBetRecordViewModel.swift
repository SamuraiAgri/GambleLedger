// GambleLedger/ViewModels/EditBetRecordViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
class EditBetRecordViewModel: ObservableObject {
    // 編集対象のID
    let recordID: UUID
    
    // 入力フィールド
    @Published var selectedDate: Date
    @Published var selectedGambleTypeID: UUID?
    @Published var eventName: String
    @Published var bettingSystem: String
    @Published var betAmount: String
    @Published var returnAmount: String
    @Published var memo: String
    
    // 状態管理
    @Published var gambleTypes: [GambleTypeModel] = []
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // 拡張状態
    @Published var availableBettingSystems: [BettingSystem] = []
    @Published var showBettingSystemPicker: Bool = false
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    // 初期化 - 既存レコードから値を設定
    init(record: BetRecordModel, coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.recordID = record.id
        self.selectedDate = record.date
        self.selectedGambleTypeID = record.gambleTypeID
        self.eventName = record.eventName
        self.bettingSystem = record.bettingSystem
        self.betAmount = NSDecimalNumber(decimal: record.betAmount).stringValue
        self.returnAmount = NSDecimalNumber(decimal: record.returnAmount).stringValue
        self.memo = record.memo
        self.coreDataManager = coreDataManager
        
        setupBindings()
        loadGambleTypes()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // バインディングの設定
    private func setupBindings() {
        // ギャンブル種別変更時の処理
        $selectedGambleTypeID
            .compactMap { $0 }
            .sink { [weak self] typeID in
                self?.updateBettingSystems(for: typeID)
            }
            .store(in: &cancellables)
        
        // 金額入力のフォーマット処理
        $betAmount
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.formatAmountInput(value: value) { formatted in
                    if formatted != value {
                        self?.betAmount = formatted
                    }
                }
            }
            .store(in: &cancellables)
        
        $returnAmount
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.formatAmountInput(value: value) { formatted in
                    if formatted != value {
                        self?.returnAmount = formatted
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // 賭式リストの更新
    private func updateBettingSystems(for typeID: UUID) {
        let provider = BettingSystemProvider.shared
        self.availableBettingSystems = provider.getBettingSystems(for: typeID)
    }
    
    // 金額入力のフォーマット
    private func formatAmountInput(value: String, completion: @escaping (String) -> Void) {
        if value.contains(",") && !value.hasSuffix(",") {
            return
        }
        
        let numbersOnly = value.filter { "0123456789".contains($0) }
        
        if numbersOnly.isEmpty {
            completion("")
            return
        }
        
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
    
    func loadGambleTypes() {
        isLoading = true
        
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            let types = results.compactMap { GambleTypeModel.fromManagedObject($0) }
            
            DispatchQueue.main.async {
                self.gambleTypes = types
                self.isLoading = false
                
                // 選択されたギャンブル種別の賭式を更新
                if let typeID = self.selectedGambleTypeID {
                    self.updateBettingSystems(for: typeID)
                }
            }
        }
    }
    
    func updateBetRecord(completion: @escaping (Bool) -> Void) {
        guard validateInput() else {
            completion(false)
            return
        }
        
        isLoading = true
        isSaving = true
        
        guard let gambleTypeID = selectedGambleTypeID else {
            showError(message: "ギャンブル種別を選択してください。")
            completion(false)
            return
        }
        
        let betAmountText = betAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let returnAmountText = returnAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let betAmountDecimal = Decimal(string: betAmountText),
              let returnAmountDecimal = Decimal(string: returnAmountText) else {
            showError(message: "入力データの変換に失敗しました。正しい数値を入力してください。")
            completion(false)
            return
        }
        
        guard betAmountDecimal >= 0 && betAmountDecimal <= 10000000,
              returnAmountDecimal >= 0 && returnAmountDecimal <= 100000000 else {
            showError(message: "金額が許容範囲外です。0〜10,000,000円の範囲で入力してください。")
            completion(false)
            return
        }
        
        coreDataManager.updateBetRecord(
            id: recordID,
            date: selectedDate,
            gambleTypeID: gambleTypeID,
            eventName: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            bettingSystem: bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines),
            betAmount: betAmountDecimal,
            returnAmount: returnAmountDecimal,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
        ) { [weak self] success, errorMsg in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isSaving = false
                
                if success {
                    self.showSuccessMessage = true
                    self.provideHapticFeedback()
                    
                    // 成功メッセージを表示後、画面を閉じる
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        completion(true)
                    }
                } else {
                    self.showError(message: errorMsg ?? "データの更新に失敗しました。もう一度お試しください。")
                    completion(false)
                }
            }
        }
    }
    
    // 触覚フィードバック
    private func provideHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func validateInput() -> Bool {
        if selectedGambleTypeID == nil {
            showError(message: "ギャンブル種別を選択してください。")
            return false
        }
        
        if eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "試合/レース名を入力してください。")
            return false
        }
        
        if bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "賭式を入力してください。")
            return false
        }
        
        if betAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "賭け金額を入力してください。")
            return false
        }
        
        if returnAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "払戻金額を入力してください。")
            return false
        }
        
        if Decimal(string: betAmount.replacingOccurrences(of: ",", with: "")) == nil {
            showError(message: "有効な賭け金額を入力してください。")
            return false
        }
        
        if Decimal(string: returnAmount.replacingOccurrences(of: ",", with: "")) == nil {
            showError(message: "有効な払戻金額を入力してください。")
            return false
        }
        
        return true
    }
    
    func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
        isSaving = false
    }
    
    // 賭式選択
    func selectBettingSystem(_ system: BettingSystem) {
        bettingSystem = system.name
    }
}
