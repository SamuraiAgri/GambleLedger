// GambleLedger/ViewModels/BetRecordViewModel.swift
import Foundation
import Combine
import SwiftUI

@MainActor
class BetRecordViewModel: ObservableObject {
    // 入力フィールド
    @Published var selectedDate: Date = Date()
    @Published var selectedGambleTypeID: UUID?
    @Published var eventName: String = ""
    @Published var raceNumber: String = ""
    @Published var bettingSystem: String = ""
    @Published var betAmount: String = ""
    @Published var returnAmount: String = ""
    @Published var memo: String = ""
    
    // 状態管理
    @Published var gambleTypes: [GambleTypeModel] = []
    @Published var isLoading: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // 拡張状態
    @Published var isSaving: Bool = false
    @Published var availableBettingSystems: [BettingSystem] = []
    @Published var showBettingSystemPicker: Bool = false
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
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
    
    func loadGambleTypes() {
        isLoading = true
        
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            let types = results.compactMap { GambleTypeModel.fromManagedObject($0) }
            
            DispatchQueue.main.async {
                self.gambleTypes = types
                self.isLoading = false
                
                // デフォルト選択（最初の要素）
                if self.selectedGambleTypeID == nil && !types.isEmpty {
                    self.selectedGambleTypeID = types.first?.id
                }
            }
        }
    }
    
    func saveBetRecord() {
        guard validateInput() else { return }
        
        isLoading = true
        isSaving = true
        
        // 入力値の変換を強化 - 条件バインディングの修正
        guard let gambleTypeID = selectedGambleTypeID else {
            showError(message: "ギャンブル種別を選択してください。")
            return
        }
        
        // 文字列から数値への変換を改善
        let betAmountText = betAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let returnAmountText = returnAmount.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let betAmountDecimal = Decimal(string: betAmountText),
              let returnAmountDecimal = Decimal(string: returnAmountText) else {
            showError(message: "入力データの変換に失敗しました。正しい数値を入力してください。")
            return
        }
        
        // 金額の妥当性チェック
        guard betAmountDecimal >= 0 && betAmountDecimal <= 10000000,
              returnAmountDecimal >= 0 && returnAmountDecimal <= 100000000 else {
            showError(message: "金額が許容範囲外です。0〜10,000,000円の範囲で入力してください。")
            return
        }
        
        // 簡易モード対応：イベント名と賭式が空の場合はデフォルト値を使用
        let finalEventName = eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? "記録" : eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalBettingSystem = bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? "-" : bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines)
        
        coreDataManager.saveBetRecord(
            date: selectedDate,
            gambleTypeID: gambleTypeID,
            eventName: finalEventName,
            bettingSystem: finalBettingSystem,
            betAmount: betAmountDecimal,
            returnAmount: returnAmountDecimal,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
        ) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isSaving = false
                
                if success {
                    self.resetForm()
                    self.showSuccessMessage = true
                    self.showSuccessAlert = true
                    self.provideHapticFeedback()
                    
                    // 3秒後に成功メッセージを非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.showSuccessMessage = false
                    }
                } else {
                    self.showError(message: "データの保存に失敗しました。もう一度お試しください。")
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
        // ギャンブル種別の選択チェック
        if selectedGambleTypeID == nil {
            showError(message: "ギャンブル種別を選択してください。")
            return false
        }
        
        // 金額の入力チェック（必須）
        if betAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "賭け金額を入力してください。")
            return false
        }
        
        if returnAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "払戻金額を入力してください。")
            return false
        }
        
        // 数値変換チェック
        if Decimal(string: betAmount.replacingOccurrences(of: ",", with: "")) == nil {
            showError(message: "有効な賭け金額を入力してください。")
            return false
        }
        
        if Decimal(string: returnAmount.replacingOccurrences(of: ",", with: "")) == nil {
            showError(message: "有効な払戻金額を入力してください。")
            return false
        }
        
        // イベント名と賭式は任意（簡易モード対応）
        return true
    }
    
    func showError(message: String) {
        errorMessage = message
        showError = true
        showErrorAlert = true
        isLoading = false
        isSaving = false
    }
    
    private func resetForm() {
        // 日付とギャンブル種別はリセットしない（連続入力用）
        eventName = ""
        bettingSystem = ""
        betAmount = ""
        returnAmount = ""
        memo = ""
    }
    
    // 賭式選択
    func selectBettingSystem(_ system: BettingSystem) {
        bettingSystem = system.name
    }
    
    // MARK: - 計算プロパティ
    
    /// 選択されたギャンブル種別の名前
    var selectedGambleTypeName: String {
        guard let typeID = selectedGambleTypeID,
              let type = gambleTypes.first(where: { $0.id == typeID }) else {
            return ""
        }
        return type.name
    }
    
    /// 計算された損益
    var calculatedProfit: Decimal? {
        guard let bet = Decimal(string: betAmount.replacingOccurrences(of: ",", with: "")),
              let return_ = Decimal(string: returnAmount.replacingOccurrences(of: ",", with: "")) else {
            return nil
        }
        return return_ - bet
    }
    
    /// 入力が有効かどうか（簡易モード用）
    var isValidSimple: Bool {
        guard selectedGambleTypeID != nil else { return false }
        guard !betAmount.isEmpty else { return false }
        guard !returnAmount.isEmpty else { return false }
        guard Decimal(string: betAmount.replacingOccurrences(of: ",", with: "")) != nil else { return false }
        guard Decimal(string: returnAmount.replacingOccurrences(of: ",", with: "")) != nil else { return false }
        return true
    }
    
    /// 入力が有効かどうか（詳細モード用）
    var isValid: Bool {
        return isValidSimple
    }
    
    /// 成功アラート表示フラグ
    @Published var showSuccessAlert: Bool = false
    
    /// エラーアラート表示フラグ
    @Published var showErrorAlert: Bool = false
}
