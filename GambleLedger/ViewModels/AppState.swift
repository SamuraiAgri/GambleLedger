// GambleLedger/ViewModels/AppState.swift
import Foundation
import Combine
import SwiftUI

extension AppState {
    // UIに必要な追加プロパティ
    var isDarkMode: Bool {
        get { UserDefaults.standard.bool(forKey: "isDarkMode") }
        set { UserDefaults.standard.set(newValue, forKey: "isDarkMode") }
    }
    
    var useSystemTheme: Bool {
        get { UserDefaults.standard.bool(forKey: "useSystemTheme") }
        set { UserDefaults.standard.set(newValue, forKey: "useSystemTheme") }
    }
    
    var notificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }
    
    // 共通データロード処理
    func loadGambleTypes() {
        let coreDataManager = CoreDataManager.shared
        
        coreDataManager.fetchGambleTypes { [weak self] results in
            guard let self = self else { return }
            
            var loadedTypes: [GambleTypeModel] = []
            
            for object in results {
                if let type = GambleTypeModel.fromManagedObject(object) {
                    loadedTypes.append(type)
                }
            }
            
            // データが存在しない場合はデフォルト値を使用
            if loadedTypes.isEmpty {
                loadedTypes = GambleTypeModel.defaultTypes()
                
                // TODO: デフォルト値をCoreDataに保存するコードを追加
            }
            
            DispatchQueue.main.async {
                self.gambleTypes = loadedTypes
            }
        }
    }
    
    // アラートの表示
    func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
}
