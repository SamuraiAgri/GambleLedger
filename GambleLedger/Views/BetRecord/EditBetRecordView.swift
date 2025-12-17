// GambleLedger/Views/BetRecord/EditBetRecordView.swift
import SwiftUI

struct EditBetRecordView: View {
    @StateObject var viewModel: EditBetRecordViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field {
        case eventName, bettingSystem, betAmount, returnAmount, memo
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 日時選択セクション
                Section(header: Text("日時")) {
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
                        .onChange(of: viewModel.selectedDate) { _, _ in
                            focusedField = nil
                        }
                }
                
                // ギャンブル種別選択セクション
                Section(header: Text("ギャンブル種別")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.gambleTypes) { type in
                                TypeButton(
                                    gambleType: type,
                                    isSelected: viewModel.selectedGambleTypeID == type.id,
                                    action: {
                                        viewModel.selectedGambleTypeID = type.id
                                        focusedField = nil
                                    }
                                )
                                .accessibilityLabel(type.name)
                                .accessibilityHint("タップして\(type.name)を選択")
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                // イベント情報セクション
                Section(header: Text("イベント情報")) {
                    TextField("試合/レース名", text: $viewModel.eventName)
                        .focused($focusedField, equals: .eventName)
                        .autocapitalization(.none)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .bettingSystem
                        }
                        .accessibilityLabel("試合またはレース名")
                    
                    HStack {
                        TextField("賭式", text: $viewModel.bettingSystem)
                            .focused($focusedField, equals: .bettingSystem)
                            .autocapitalization(.none)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .betAmount
                            }
                            .accessibilityLabel("賭式")
                        
                        if !viewModel.availableBettingSystems.isEmpty {
                            Button(action: {
                                viewModel.showBettingSystemPicker = true
                                focusedField = nil
                            }) {
                                Image(systemName: "list.bullet")
                                    .foregroundColor(.primaryColor)
                            }
                            .accessibilityLabel("賭式一覧から選択")
                        }
                    }
                }
                
                // 金額情報セクション
                Section(header: Text("金額情報")) {
                    HStack {
                        Text("賭け金")
                        TextField("0", text: $viewModel.betAmount)
                            .focused($focusedField, equals: .betAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .returnAmount
                            }
                            .accessibilityLabel("賭け金")
                        Text("円")
                    }
                    
                    HStack {
                        Text("払戻金")
                        TextField("0", text: $viewModel.returnAmount)
                            .focused($focusedField, equals: .returnAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .memo
                            }
                            .accessibilityLabel("払戻金")
                        Text("円")
                    }
                    
                    if let betAmount = Double(viewModel.betAmount.replacingOccurrences(of: ",", with: "")),
                       let returnAmount = Double(viewModel.returnAmount.replacingOccurrences(of: ",", with: "")),
                       betAmount > 0 {
                        
                        let profit = returnAmount - betAmount
                        let roi = (returnAmount / betAmount - 1) * 100
                        
                        HStack {
                            Text("損益")
                            Spacer()
                            Text("\(Int(profit)) 円")
                                .foregroundColor(profit >= 0 ? .accentSuccess : .accentDanger)
                                .fontWeight(.bold)
                        }
                        .accessibilityElement(children: .combine)
                        
                        HStack {
                            Text("回収率")
                            Spacer()
                            Text("\(roi, specifier: "%.1f") %")
                                .foregroundColor(roi >= 0 ? .accentSuccess : .accentDanger)
                                .fontWeight(.bold)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                
                // メモセクション
                Section(header: Text("メモ")) {
                    TextField("メモ（任意）", text: $viewModel.memo, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .memo)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .accessibilityLabel("メモ")
                }
                
                // 更新ボタン
                Section {
                    Button(action: {
                        focusedField = nil
                        viewModel.updateBetRecord { success in
                            if success {
                                dismiss()
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                            }
                            Text(viewModel.isSaving ? "更新中..." : "更新する")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSaving || viewModel.isLoading)
                    .listRowBackground(Color.primaryColor)
                    .foregroundColor(.white)
                    .accessibilityLabel(viewModel.isSaving ? "更新中" : "記録を更新")
                }
            }
            .navigationTitle("記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .accessibilityLabel("キャンセル")
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("完了") {
                            focusedField = nil
                        }
                        .fontWeight(.semibold)
                        .accessibilityLabel("キーボードを閉じる")
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
                            Text("更新しました")
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
            .sheet(isPresented: $viewModel.showBettingSystemPicker) {
                BettingSystemPickerView(
                    systems: viewModel.availableBettingSystems,
                    onSelect: { system in
                        viewModel.selectBettingSystem(system)
                        viewModel.showBettingSystemPicker = false
                    }
                )
            }
        }
    }
}

// TypeButtonコンポーネント（既存のコンポーネントを使用）
private struct TypeButton: View {
    let gambleType: GambleTypeModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: gambleType.icon)
                    .font(.system(size: 24))
                Text(gambleType.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 70, height: 70)
            .foregroundColor(isSelected ? .white : gambleType.color)
            .background(isSelected ? gambleType.color : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(gambleType.color, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 賭式選択ピッカー
private struct BettingSystemPickerView: View {
    let systems: [BettingSystem]
    let onSelect: (BettingSystem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(systems) { system in
                Button(action: {
                    onSelect(system)
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(system.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(system.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("賭式を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
