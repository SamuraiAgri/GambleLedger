// GambleLedger/Common/Extensions/Color+Extension.swift
import SwiftUI

extension Color {
    // メインカラー
    static let primaryColor = Color(hex: "#2E7D32") // より鮮やかな緑色
    static let secondaryColor = Color(hex: "#00796B") // ティール色
    
    // アクセントカラー
    static let accentSuccess = Color(hex: "#43A047") // 成功/利益表示用
    static let accentWarning = Color(hex: "#FF9800") // 警告用
    static let accentDanger = Color(hex: "#D32F2F") // 失敗/損失表示用
    
    // 背景カラー
    static let backgroundPrimary = Color(hex: "#F5F5F5") // メイン背景
    static let backgroundSecondary = Color(hex: "#FFFFFF") // カード背景
    static let backgroundTertiary = Color(hex: "#EEEEEE") // 区切り背景
    
    // ギャンブル種別カラー - より鮮やかなカラーパレット
    static let gambleHorse = Color(hex: "#1E88E5") // 競馬
    static let gambleBoat = Color(hex: "#039BE5") // 競艇
    static let gambleBike = Color(hex: "#8E24AA") // 競輪
    static let gambleSports = Color(hex: "#7B1FA2") // スポーツベット
    static let gamblePachinko = Color(hex: "#FFC107") // パチンコ
    static let gambleOther = Color(hex: "#00ACC1") // その他
    
    // グラデーションカラー
    static let gradientSuccess = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#43A047"), Color(hex: "#2E7D32")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#2E7D32"), Color(hex: "#1B5E20")]),
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
