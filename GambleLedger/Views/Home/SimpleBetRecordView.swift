// GambleLedger/Views/Home/SimpleBetRecordView.swift
import SwiftUI

/// 簡易記録モード - 最小限の入力で素早く記録
struct SimpleBetRecordView: View {
    @StateObject private var viewModel = BetRecordViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field {
        case betAmount, returnAmount
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // ギャンブル種別選択
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ギャンブル種別")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.gambleTypes) { type in
                                    SimpleTypeButton(
                                        gambleType: type,
                                        isSelected: viewModel.selectedGambleTypeID == type.id,
                                        action: {
                                            viewModel.selectedGambleTypeID = type.id
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 金額入力エリア
                    VStack(spacing: 16) {
                        // 賭け金入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("賭け金")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("¥")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: $viewModel.betAmount)
                                    .font(.system(size: 32, weight: .bold))
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .betAmount)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                        }
                        
                        // 払戻金入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("払戻金")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("¥")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: $viewModel.returnAmount)
                                    .font(.system(size: 32, weight: .bold))
                                    .keyboardType(.numberPad)
                                    .focused($focusedField, equals: .returnAmount)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding()
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                        }
                        
                        // 損益表示
                        if let betAmount = Double(viewModel.betAmount.replacingOccurrences(of: ",", with: "")),
                           let returnAmount = Double(viewModel.returnAmount.replacingOccurrences(of: ",", with: "")),
                           betAmount > 0 {
                            
                            let profit = returnAmount - betAmount
                            let roi = (returnAmount / betAmount - 1) * 100
                            
                            VStack(spacing: 12) {
                                Divider()
                                
                                HStack {
                                    Text("損益")
                                        .font(.headline)
                                    Spacer()
                                    Text("\(profit >= 0 ? "+" : "")\(Int(profit)) 円")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(profit >= 0 ? .accentSuccess : .accentDanger)
                                }
                                
                                HStack {
                                    Text("回収率")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(roi, specifier: "%.1f")%")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(roi >= 0 ? .accentSuccess : .accentDanger)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(profit >= 0 ? Color.accentSuccess.opacity(0.1) : Color.accentDanger.opacity(0.1))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // 詳細記録へのリンク
                    Button(action: {
                        // 詳細モードへ切り替え
                        dismiss()
                        // TODO: 詳細モードを開く
                    }) {
                        HStack {
                            Image(systemName: "square.and.pencil")
                            Text("詳細を記録する")
                        }
                        .foregroundColor(.secondaryColor)
                        .padding()
                    }
                    
                    Spacer()
                }
                .padding(.top)
            }
            .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            .navigationTitle("簡易記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        focusedField = nil
                        saveSimpleRecord()
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("保存")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSaving || !isValidInput())
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("完了") {
                            focusedField = nil
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "不明なエラーが発生しました。")
            }
            .overlay {
                if viewModel.showSuccessMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                            Text("記録しました")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color.accentSuccess)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        .padding(.bottom, 50)
                    }
                    .transition(.move(edge: .bottom))
                    .animation(.spring(), value: viewModel.showSuccessMessage)
                }
            }
        }
    }
    
    // 簡易記録の保存
    private func saveSimpleRecord() {
        // 最小限の情報で保存
        viewModel.eventName = "記録" // デフォルト値
        viewModel.bettingSystem = "-" // 賭式なし
        viewModel.memo = "" // メモなし
        
        viewModel.saveBetRecord()
        
        // 保存成功したら1秒後に閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if viewModel.showSuccessMessage {
                dismiss()
            }
        }
    }
    
    // 入力が有効かチェック
    private func isValidInput() -> Bool {
        guard viewModel.selectedGambleTypeID != nil else { return false }
        guard !viewModel.betAmount.isEmpty else { return false }
        guard !viewModel.returnAmount.isEmpty else { return false }
        return true
    }
}

// 簡易版ギャンブル種別ボタン
private struct SimpleTypeButton: View {
    let gambleType: GambleTypeModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? gambleType.color : Color.gray.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .shadow(color: isSelected ? gambleType.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    
                    Image(systemName: gambleType.icon)
                        .font(.system(size: 36))
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(gambleType.name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? gambleType.color : .secondary)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SimpleBetRecordView()
        .environmentObject(AppState())
}
