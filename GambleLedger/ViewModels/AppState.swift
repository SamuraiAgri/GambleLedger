// GambleLedger/ViewModels/AppState.swift
import Foundation
import Combine
import SwiftUI
import CoreData

@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showAddBetSheet: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String?
    @Published var gambleTypes: [GambleTypeModel] = []
    @Published var isDarkMode: Bool = false
    @Published var useSystemTheme: Bool = true
    
    private let coreDataManager: CoreDataManager
    private var cancellables = Set<AnyCancellable>()
    
    init(coreDataManager: CoreDataManager = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
        
        // アプリ設定の復元
        restoreAppSettings()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // エラーハンドリング
    func handleError(_ error: AppError) {
        ErrorHandler.shared.handle(error)
    }
    
    // アプリ設定の保存
    private func restoreAppSettings() {
        if let isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool {
            self.isDarkMode = isDarkMode
        }
        
        if let useSystemTheme = UserDefaults.standard.object(forKey: "useSystemTheme") as? Bool {
            self.useSystemTheme = useSystemTheme
        }
    }
    
    // ダークモード設定の保存
    func saveThemeSettings() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(useSystemTheme, forKey: "useSystemTheme")
    }
    
    // ギャンブル種別をデータベースに保存
    private func saveGambleTypeToDatabase(_ type: GambleTypeModel) {
        // Colorを文字列に変換
        let colorHex = type.color.toHex() ?? "#000000"
        
        coreDataManager.saveGambleType(
            id: type.id,
            name: type.name,
            icon: type.icon,
            color: colorHex
        ) { [weak self] success in
            if !success {
                self?.showAlertMessage("ギャンブル種別の保存に失敗しました")
            }
        }
    }
    
    // 既存のloadGambleTypesメソッドを修正
    func loadGambleTypes() {
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            var loadedTypes: [GambleTypeModel] = []
            
            for object in results {
                if let type = GambleTypeModel.fromManagedObject(object) {
                    loadedTypes.append(type)
                }
            }
            
            // データが存在しない場合、またはデフォルトデータと数が異なる場合は同期
            let defaultTypes = GambleTypeModel.defaultTypes()
            if loadedTypes.isEmpty || loadedTypes.count != defaultTypes.count {
                // デフォルト値をCoreDataに保存
                for type in defaultTypes {
                    self.saveGambleTypeToDatabase(type)
                }
                loadedTypes = defaultTypes
            } else {
                // 既存データがある場合もアイコンと順序を更新
                self.updateGambleTypesInDatabase()
            }
            
            DispatchQueue.main.async {
                self.gambleTypes = defaultTypes // 常に最新のデフォルト順序を使用
            }
        }
    }
    
    // ギャンブル種別のアイコンと色を更新
    private func updateGambleTypesInDatabase() {
        let defaultTypes = GambleTypeModel.defaultTypes()
        for type in defaultTypes {
            saveGambleTypeToDatabase(type)
        }
    }
}

// Color型のHEX文字列変換拡張
extension Color {
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components else { return nil }
        
        let r = components[0]
        let g = components[1]
        let b = components[2]
        
        let hexString = String(format: "#%02X%02X%02X",
                              Int(r * 255),
                              Int(g * 255),
                              Int(b * 255))
        return hexString
    }
}
