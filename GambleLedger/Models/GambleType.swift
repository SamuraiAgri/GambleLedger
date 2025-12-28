// GambleLedger/Models/GambleType.swift
import Foundation
import CoreData
import SwiftUI

// ギャンブル種別のデータモデル
struct GambleTypeModel: Identifiable {
    let id: UUID
    let name: String
    let icon: String
    let color: Color
    
    // NSManagedObjectからの変換
    static func fromManagedObject(_ object: NSManagedObject) -> GambleTypeModel? {
        guard let id = object.value(forKey: "id") as? UUID,
              let name = object.value(forKey: "name") as? String,
              let icon = object.value(forKey: "icon") as? String,
              let colorHex = object.value(forKey: "color") as? String else {
            return nil
        }
        
        return GambleTypeModel(
            id: id,
            name: name,
            icon: icon,
            color: Color(hex: colorHex)
        )
    }
    
    // デフォルトのギャンブル種別一覧
    static func defaultTypes() -> [GambleTypeModel] {
        return [
            // その他
            GambleTypeModel(
                id: Constants.GambleTypes.other.id,
                name: Constants.GambleTypes.other.name,
                icon: Constants.GambleTypes.other.icon,
                color: Color(hex: Constants.GambleTypes.other.color)
            ),
            // スポーツベット
            GambleTypeModel(
                id: Constants.GambleTypes.sports.id,
                name: Constants.GambleTypes.sports.name,
                icon: Constants.GambleTypes.sports.icon,
                color: Color(hex: Constants.GambleTypes.sports.color)
            ),
            // 競輪
            GambleTypeModel(
                id: Constants.GambleTypes.bike.id,
                name: Constants.GambleTypes.bike.name,
                icon: Constants.GambleTypes.bike.icon,
                color: Color(hex: Constants.GambleTypes.bike.color)
            ),
            // 競艇
            GambleTypeModel(
                id: Constants.GambleTypes.boat.id,
                name: Constants.GambleTypes.boat.name,
                icon: Constants.GambleTypes.boat.icon,
                color: Color(hex: Constants.GambleTypes.boat.color)
            ),
            // 競馬
            GambleTypeModel(
                id: Constants.GambleTypes.horse.id,
                name: Constants.GambleTypes.horse.name,
                icon: Constants.GambleTypes.horse.icon,
                color: Color(hex: Constants.GambleTypes.horse.color)
            ),
            // パチンコ
            GambleTypeModel(
                id: Constants.GambleTypes.pachinko.id,
                name: Constants.GambleTypes.pachinko.name,
                icon: Constants.GambleTypes.pachinko.icon,
                color: Color(hex: Constants.GambleTypes.pachinko.color)
            )
        ]
    }
    
    // ID文字列からギャンブル種別を取得
    static func getType(byID id: UUID, from types: [GambleTypeModel]) -> GambleTypeModel? {
        return types.first { $0.id == id }
    }
    
    // 名前からギャンブル種別を取得
    static func getType(byName name: String, from types: [GambleTypeModel]) -> GambleTypeModel? {
        return types.first { $0.name == name }
    }
}
