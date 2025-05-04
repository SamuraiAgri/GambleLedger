// GambleLedger/ViewModels/BetRecordViewModel.swift
import Foundation
import Combine
import SwiftUI

class BetRecordViewModel: ObservableObject {
    // 入力フィールド
    @Published var selectedDate: Date = Date()
    @Published var selectedGambleTypeID: UUID?
    @Published var eventName: String = ""
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
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        loadGambleTypes()
    }
    
    func loadGambleTypes() {
        isLoading = true
        
        // do-catch ブロックを使用せずに処理
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
        
        coreDataManager.saveBetRecord(
            date: selectedDate,
            gambleTypeID: gambleTypeID,
            eventName: eventName.trimmingCharacters(in: .whitespacesAndNewlines),
            bettingSystem: bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines),
            betAmount: betAmountDecimal,
            returnAmount: returnAmountDecimal,
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines)
        ) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.resetForm()
                    self.showSuccessMessage = true
                    
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
    
    private func validateInput() -> Bool {
        // ギャンブル種別の選択チェック
        if selectedGambleTypeID == nil {
            showError(message: "ギャンブル種別を選択してください。")
            return false
        }
        
        // イベント名の入力チェック
        if eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "試合/レース名を入力してください。")
            return false
        }
        
        // 賭式の入力チェック
        if bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError(message: "賭式を入力してください。")
            return false
        }
        
        // 金額の入力チェック
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
        
        return true
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
        isLoading = false
    }
    
    private func resetForm() {
        // 日付とギャンブル種別はリセットしない（連続入力用）
        eventName = ""
        bettingSystem = ""
        betAmount = ""
        returnAmount = ""
        memo = ""
    }
}
