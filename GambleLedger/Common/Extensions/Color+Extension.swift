// GambleLedger/Common/Extensions/Color+Extension.swift
import SwiftUI

extension Color {
    // メインカラー
    static let primaryColor = Color("PrimaryColor", bundle: nil) // カスタムダークグリーン #1E6F5C
    static let secondaryColor = Color("SecondaryColor", bundle: nil) // カスタムティール #29BB89
    
    // アクセントカラー
    static let accentSuccess = Color("AccentSuccess", bundle: nil) // 成功/利益表示用 #27AE60
    static let accentWarning = Color("AccentWarning", bundle: nil) // 警告用 #F39C12
    static let accentDanger = Color("AccentDanger", bundle: nil) // 失敗/損失表示用 #E74C3C
    
    // 背景カラー
    static let backgroundPrimary = Color("BackgroundPrimary", bundle: nil) // メイン背景 #F8F9FA
    static let backgroundSecondary = Color("BackgroundSecondary", bundle: nil) // カード背景 #FFFFFF
    static let backgroundTertiary = Color("BackgroundTertiary", bundle: nil) // 区切り背景 #E9ECEF
    
    // ギャンブル種別カラー
    static let gambleHorse = Color("GambleHorse", bundle: nil) // 競馬 #2E86C1
    static let gambleBoat = Color("GambleBoat", bundle: nil) // 競艇 #3498DB
    static let gambleBike = Color("GambleBike", bundle: nil) // 競輪 #9B59B6
    static let gambleSports = Color("GambleSports", bundle: nil) // スポーツベット #8E44AD
    static let gamblePachinko = Color("GamblePachinko", bundle: nil) // パチンコ #F1C40F
    static let gambleOther = Color("GambleOther", bundle: nil) // その他 #16A085
    
    // グラデーションカラー
    static let gradientSuccess = LinearGradient(
        gradient: Gradient(colors: [Color("GradientSuccessStart", bundle: nil), Color("GradientSuccessEnd", bundle: nil)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [Color("GradientPrimaryStart", bundle: nil), Color("GradientPrimaryEnd", bundle: nil)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // カード背景用グラデーション
    static let cardGradient = LinearGradient(
        gradient: Gradient(colors: [Color.white, Color.white.opacity(0.95)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
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
    
    // 明暗調整関数
    func adjusted(brightness: Double) -> Color {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        #if canImport(UIKit)
        UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return Color(UIColor(hue: hue, saturation: saturation, brightness: min(max(CGFloat(brightness + brightness), 0), 1), alpha: alpha))
        #else
        return self
        #endif
    }
}
