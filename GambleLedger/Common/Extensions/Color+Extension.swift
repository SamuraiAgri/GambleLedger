// GambleLedger/Common/Extensions/Color+Extension.swift
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
    
    // ギャンブル種別カラー - より鮮やかなカラーに変更
    static let gambleHorse = Color("GambleHorse") // 競馬 #16A085
    static let gambleBoat = Color("GambleBoat") // 競艇 #2980B9
    static let gambleBike = Color("GambleBike") // 競輪 #3498DB
    static let gambleSports = Color("GambleSports") // スポーツベット #9B59B6
    static let gamblePachinko = Color("GamblePachinko") // パチンコ #F1C40F
    static let gambleOther = Color("GambleOther") // その他 #2ECC71
    
    // ダークモード対応グラデーションカラー - 新規追加
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [Color("GradientStart"), Color("GradientEnd")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // カード背景用グラデーション - 新規追加
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.95)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    // カテゴリー区分用カラー - 新規追加
    static let categoryColors: [Color] = [
        Color("Category1"),  // #3498db
        Color("Category2"),  // #2ecc71
        Color("Category3"),  // #e74c3c
        Color("Category4"),  // #f39c12
        Color("Category5"),  // #9b59b6
        Color("Category6")   // #1abc9c
    ]
    
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
    
    // 明暗調整関数 - 新規追加
    func adjusted(brightness: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if canImport(UIKit)
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(UIColor(hue: hue, saturation: saturation, brightness: min(max(CGFloat(brightness), 0), 1), alpha: alpha))
        #else
        return self
        #endif
    }
}
