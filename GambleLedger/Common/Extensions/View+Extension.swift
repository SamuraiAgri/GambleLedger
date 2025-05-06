// GambleLedger/Common/Extensions/View+Extension.swift
import SwiftUI

extension View {
    // ベーシックなカードスタイル
    func cardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(Color.backgroundSecondary)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // グラデーションを使用した高級感あるカードスタイル
    func premiumCardStyle(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardGradient)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
    }
    
    // アクセントカラーを使ったカードスタイル
    func accentCardStyle(color: Color, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(color, lineWidth: 2)
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    // グラデーションアクセントを使ったカードスタイル
    func gradientCardStyle(colors: [Color], cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: colors),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
    
    // ボタンスタイル
    func primaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: Color.primaryColor.opacity(0.4), radius: 5, x: 0, y: 3)
    }
    
    // セカンダリボタンスタイル
    func secondaryButtonStyle() -> some View {
        self
            .padding()
            .background(Color.secondaryColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(color: Color.secondaryColor.opacity(0.4), radius: 5, x: 0, y: 3)
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
                    
                    // アニメーションエフェクト
                    func withBounceAnimation() -> some View {
                        self.modifier(BounceAnimationModifier())
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
                    
                    // キーボードを閉じる
                    func dismissKeyboard() -> some View {
                        self.onTapGesture {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
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

                // バウンスアニメーション用モディファイア
                struct BounceAnimationModifier: ViewModifier {
                    @State private var animate = false
                    
                    func body(content: Content) -> some View {
                        content
                            .scaleEffect(animate ? 1.03 : 1)
                            .animation(animate ?
                                       Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                                        .default,
                                      value: animate)
                            .onAppear {
                                animate = true
                            }
                    }
                }

                // ローディングオーバーレイ（再利用可能コンポーネント）
                struct LoadingOverlay: ViewModifier {
                    let isLoading: Bool
                    let message: String
                    
                    func body(content: Content) -> some View {
                        ZStack {
                            content
                            
                            if isLoading {
                                Color.black.opacity(0.3)
                                    .edgesIgnoringSafeArea(.all)
                                
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    
                                    Text(message)
                                        .font(.callout)
                                        .foregroundColor(.white)
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.8))
                                )
                            }
                        }
                    }
                }

                extension View {
                    func loadingOverlay(isLoading: Bool, message: String = "読み込み中...") -> some View {
                        self.modifier(LoadingOverlay(isLoading: isLoading, message: message))
                    }
                }
