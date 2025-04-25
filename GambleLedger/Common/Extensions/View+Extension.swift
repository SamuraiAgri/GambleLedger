// GambleLedger/Common/Extensions/View+Extension.swift
import SwiftUI

extension View {
    // カードスタイル
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // Viewの外接矩形サイズを取得
    func getSize(completion: @escaping (CGSize) -> Void) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear.onAppear {
                    completion(geometry.size)
                }
            }
        )
    }
    
    // 条件付きで修飾子を適用
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // タップ効果（少し押し込む感じ）
    func pressableStyle() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
    
    // エラーメッセージを表示
    func withErrorMessage(_ message: String?, isShowing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            self
            
            if isShowing, let errorText = message {
                Text(errorText)
                    .font(.caption)
                    .foregroundColor(.accentDanger)
                    .padding(.horizontal, 4)
            }
        }
    }
    
    // キーボードが表示されたときにViewをスクロールで調整
    func adaptToKeyboard() -> some View {
        modifier(KeyboardAdaptiveModifier())
    }
}

// 押し込み効果のあるボタンスタイル
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// キーボード表示に応じて調整するモディファイア
struct KeyboardAdaptiveModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                        return
                    }
                    
                    keyboardHeight = keyboardFrame.height
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    keyboardHeight = 0
                }
            }
    }
}
