// GambleLedger/Models/BettingSystem.swift
import Foundation

// ベッティングシステム（賭け方）の定義
struct BettingSystem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let gambleTypeID: UUID?  // 特定のギャンブル種別に限定するか
    
    // Hashable実装
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BettingSystem, rhs: BettingSystem) -> Bool {
        return lhs.id == rhs.id
    }
}

// ギャンブル種別ごとの賭式データプロバイダ
class BettingSystemProvider {
    static let shared = BettingSystemProvider()
    
    // 競馬の賭式
    var horseSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "単勝",
            description: "1着になる馬を当てる",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "複勝",
            description: "3着以内に入る馬を当てる",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "馬連",
            description: "1着と2着になる馬を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "馬単",
            description: "1着と2着になる馬を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "ワイド",
            description: "3着以内に入る2頭の馬を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "3連複",
            description: "1〜3着になる3頭の馬を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.horse.id
        ),
        BettingSystem(
            id: UUID(),
            name: "3連単",
            description: "1〜3着になる3頭の馬を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.horse.id
        )
    ]
    
    // 競艇の賭式
    var boatSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "3連単",
            description: "1〜3着の艇を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.boat.id
        ),
        BettingSystem(
            id: UUID(),
            name: "3連複",
            description: "1〜3着の艇を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.boat.id
        ),
        BettingSystem(
            id: UUID(),
            name: "2連単",
            description: "1着と2着の艇を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.boat.id
        ),
        BettingSystem(
            id: UUID(),
            name: "2連複",
            description: "1着と2着の艇を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.boat.id
        ),
        BettingSystem(
            id: UUID(),
            name: "単勝",
            description: "1着の艇を当てる",
            gambleTypeID: Constants.GambleTypes.boat.id
        ),
        BettingSystem(
            id: UUID(),
            name: "複勝",
            description: "2着以内に入る艇を当てる",
            gambleTypeID: Constants.GambleTypes.boat.id
        )
    ]
    
    // 競輪の賭式
    var bikeSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "単勝",
            description: "1着の選手を当てる",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "複勝",
            description: "2着以内に入る選手を当てる",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "2車単",
            description: "1着と2着の選手を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "2車複",
            description: "1着と2着の選手を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "ワイド",
            description: "3着以内に入る2人の選手を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "3連単",
            description: "1〜3着の選手を当てる（順序通り）",
            gambleTypeID: Constants.GambleTypes.bike.id
        ),
        BettingSystem(
            id: UUID(),
            name: "3連複",
            description: "1〜3着の選手を当てる（順不同）",
            gambleTypeID: Constants.GambleTypes.bike.id
        )
    ]
    
    // スポーツベットの賭式
    var sportsSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "勝敗",
            description: "試合の勝敗を当てる",
            gambleTypeID: Constants.GambleTypes.sports.id
        ),
        BettingSystem(
            id: UUID(),
            name: "ハンデ",
            description: "ハンデを考慮した勝敗を当てる",
            gambleTypeID: Constants.GambleTypes.sports.id
        ),
        BettingSystem(
            id: UUID(),
            name: "オーバー/アンダー",
            description: "合計得点が基準値より上か下かを当てる",
            gambleTypeID: Constants.GambleTypes.sports.id
        ),
        BettingSystem(
            id: UUID(),
            name: "スコア",
            description: "正確なスコアを当てる",
            gambleTypeID: Constants.GambleTypes.sports.id
        ),
        BettingSystem(
            id: UUID(),
            name: "特定選手得点",
            description: "特定選手の得点を当てる",
            gambleTypeID: Constants.GambleTypes.sports.id
        )
    ]
    
    // パチンコの記録方法
    var pachinkoSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "1日集計",
            description: "1日の総投資額と回収額",
            gambleTypeID: Constants.GambleTypes.pachinko.id
        ),
        BettingSystem(
            id: UUID(),
            name: "台ごと",
            description: "遊技台ごとの投資額と回収額",
            gambleTypeID: Constants.GambleTypes.pachinko.id
        ),
        BettingSystem(
            id: UUID(),
            name: "時間ごと",
            description: "時間帯ごとの投資額と回収額",
            gambleTypeID: Constants.GambleTypes.pachinko.id
        )
    ]
    
    // その他のギャンブル記録方法
    var otherSystems: [BettingSystem] = [
        BettingSystem(
            id: UUID(),
            name: "通常ベット",
            description: "一般的な賭け方",
            gambleTypeID: Constants.GambleTypes.other.id
        ),
        BettingSystem(
            id: UUID(),
            name: "特殊ベット",
            description: "特殊な賭け方や条件付きベット",
            gambleTypeID: Constants.GambleTypes.other.id
        )
    ]
    
    // ギャンブル種別IDから対応する賭式一覧を取得
    func getBettingSystems(for gambleTypeID: UUID) -> [BettingSystem] {
        let gambleTypeString = gambleTypeID.uuidString
        
        if gambleTypeString == Constants.GambleTypes.horse.id.uuidString {
            return horseSystems
        } else if gambleTypeString == Constants.GambleTypes.boat.id.uuidString {
            return boatSystems
        } else if gambleTypeString == Constants.GambleTypes.bike.id.uuidString {
            return bikeSystems
        } else if gambleTypeString == Constants.GambleTypes.sports.id.uuidString {
            return sportsSystems
        } else if gambleTypeString == Constants.GambleTypes.pachinko.id.uuidString {
            return pachinkoSystems
        } else {
            return otherSystems
        }
    }
    
    // 全ての賭式一覧を取得
    func getAllBettingSystems() -> [BettingSystem] {
        return horseSystems + boatSystems + bikeSystems + sportsSystems + pachinkoSystems + otherSystems
    }
    
    // 賭式名から賭式を検索
    func findBettingSystem(byName name: String) -> BettingSystem? {
        return getAllBettingSystems().first { $0.name == name }
    }
}
