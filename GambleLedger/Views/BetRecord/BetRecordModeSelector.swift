// GambleLedger/Views/BetRecord/BetRecordModeSelector.swift
import SwiftUI

/// 記録モード選択画面 - 簡易/詳細を選択
struct BetRecordModeSelector: View {
    @State private var showSimpleMode = false
    @State private var showDetailedMode = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Text("記録方法を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                VStack(spacing: 24) {
                    // 簡易記録モードボタン
                    RecordModeCard(
                        icon: "bolt.fill",
                        iconColor: .accentSuccess,
                        title: "簡易記録",
                        description: "ギャンブル種別・賭け金・払戻金のみ",
                        features: ["3項目のみ入力", "30秒で完了", "詳細は後で追加可能"],
                        action: {
                            showSimpleMode = true
                        }
                    )
                    
                    // 詳細記録モードボタン
                    RecordModeCard(
                        icon: "doc.text.fill",
                        iconColor: .secondaryColor,
                        title: "詳細記録",
                        description: "イベント名・賭式・メモなど全て記録",
                        features: ["全項目入力可能", "賭式を選択可能", "メモを追加可能"],
                        action: {
                            showDetailedMode = true
                        }
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Text("※ 簡易記録後でも履歴から詳細を追加できます")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 20)
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("ベット記録")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showSimpleMode) {
                SimpleBetRecordView()
            }
            .fullScreenCover(isPresented: $showDetailedMode) {
                DetailedBetRecordView()
            }
        }
    }
}

// 記録モードカード
private struct RecordModeCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(iconColor.opacity(0.15))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 28))
                            .foregroundColor(iconColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(iconColor)
                            
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.backgroundSecondary)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(iconColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BetRecordModeSelector()
        .environmentObject(AppState())
}
