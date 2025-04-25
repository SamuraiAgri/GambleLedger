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
        
        guard let gambleTypeID = selectedGambleTypeID,
              let betAmountDecimal = Decimal(string: betAmount.replacingOccurrences(of: ",", with: "")),
              let returnAmountDecimal = Decimal(string: returnAmount.replacingOccurrences(of: ",", with: "")) else {
            showError(message: "入力データの変換に失敗しました。")
            return
        }
        
        coreDataManager.saveBetRecord(
            date: selectedDate,
            gambleTypeID: gambleTypeID,
            eventName: eventName,
            bettingSystem: bettingSystem,
            betAmount: betAmountDecimal,
            returnAmount: returnAmountDecimal,
            memo: memo
        ) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if success {
                    self.resetForm()
                    self.showSuccessMessage = true
                    
                    // 3秒後に成功メッセージを非表示
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.showSuccessMessage = false
                    }
                } else {
                    self.showError(message: "データの保存に失敗しました。")
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
