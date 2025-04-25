// Color+Extension.swift
import SwiftUI

extension Color {
    // メインカラー
    static let primaryColor = Color("PrimaryColor") // 深緑系 #1E6F5C
    static let secondaryColor = Color("SecondaryColor") // 薄緑系 #29BB89
    
    // アクセントカラー
    static let accentSuccess = Color("AccentSuccess") // 利益表示用 #289672
    static let accentWarning = Color("AccentWarning") // 注意喚起用 #FFCE54
    static let accentDanger = Color("AccentDanger") // 損失表示用 #ED5565
    
    // 背景カラー
    static let backgroundPrimary = Color("BackgroundPrimary") // メイン背景 #F5F7FA
    static let backgroundSecondary = Color("BackgroundSecondary") // カード背景 #FFFFFF
    static let backgroundTertiary = Color("BackgroundTertiary") // 区切り背景 #E6E9ED
    
    // ギャンブル種別カラー
    static let gambleHorse = Color("GambleHorse") // 競馬 #1ABC9C
    static let gambleBoat = Color("GambleBoat") // 競艇 #3BAFDA
    static let gambleBike = Color("GambleBike") // 競輪 #4FC1E9
    static let gambleSports = Color("GambleSports") // スポーツベット #AC92EC
    static let gamblePachinko = Color("GamblePachinko") // パチンコ #FFCE54
    static let gambleOther = Color("GambleOther") // その他 #A0D468
    
    // 16進数から色を生成
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
