// GambleLedger/ViewModels/AppState.swift
import Foundation
import Combine
import SwiftUI
import CoreData

class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showAddBetSheet: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String?
    @Published var gambleTypes: [GambleTypeModel] = []
    @Published var isDarkMode: Bool = false
    @Published var useSystemTheme: Bool = true
    
    func showAlertMessage(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // エラーハンドリング
    func handleError(_ error: AppError) {
        ErrorHandler.shared.handle(error)
    }
    
    // ギャンブル種別をデータベースに保存
    private func saveGambleTypeToDatabase(_ type: GambleTypeModel) {
        let context = PersistenceController.shared.container.viewContext
        
        // エンティティの作成
        let newType = NSEntityDescription.insertNewObject(forEntityName: "GambleType", into: context)
        
        // 値の設定
        newType.setValue(type.id, forKey: "id")
        newType.setValue(type.name, forKey: "name")
        newType.setValue(type.icon, forKey: "icon")
        
        // ColorをHEX文字列に変換する処理が必要
        let colorHex = "#" + String(describing: type.color).replacingOccurrences(of: "Color(", with: "").replacingOccurrences(of: ")", with: "")
        newType.setValue(colorHex, forKey: "color")
        
        newType.setValue(Date(), forKey: "createdAt")
        newType.setValue(Date(), forKey: "updatedAt")
        
        // 保存
        do {
            try context.save()
        } catch {
            // エラーハンドリング
            print("Failed to save gamble type: \(error)")
            showAlertMessage("ギャンブル種別の保存に失敗しました")
        }
    }
    
    // 既存のloadGambleTypesメソッドを修正
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
                
                // デフォルト値をCoreDataに保存
                for type in loadedTypes {
                    self.saveGambleTypeToDatabase(type)
                }
            }
            
            DispatchQueue.main.async {
                self.gambleTypes = loadedTypes
            }
        }
    }
}
