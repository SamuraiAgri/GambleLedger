// GambleLedger/Views/BetRecord/DetailedBetRecordView.swift
import SwiftUI

/// 詳細記録モード - すべての情報を入力可能
struct DetailedBetRecordView: View {
    let initialDate: Date?
    @StateObject private var viewModel = BetRecordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // キーボード管理
    @FocusState private var focusedField: Field?
    
    enum Field {
        case eventName, bettingSystem, betAmount, returnAmount, memo
    }
    
    init(initialDate: Date? = nil) {
        self.initialDate = initialDate
    }
    
    var body: some View {
        NavigationView {
            if viewModel.isLoading && viewModel.gambleTypes.isEmpty {
                // データロード中
                VStack {
                    ProgressView("読み込み中...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundPrimary)
                .navigationTitle("詳細記録")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            dismiss()
                        }
                    }
                }
            } else {
                // データロード完了
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
                                DetailedTypeButton(
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
                    
                    // 賭式（任意）
                    HStack {
                        TextField("賭式（任意）", text: $viewModel.bettingSystem)
                            .focused($focusedField, equals: .bettingSystem)
                            .autocapitalization(.none)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .betAmount
                            }
                        
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
                    
                    Text("※ 賭式は任意です。選択または入力できます。")
                        .font(.caption)
                        .foregroundColor(.secondary)
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
                        
                        HStack {
                            Text("回収率")
                            Spacer()
                            Text("\(roi, specifier: "%.1f") %")
                                .foregroundColor(roi >= 0 ? .accentSuccess : .accentDanger)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                // メモセクション（任意）
                Section(header: Text("メモ（任意）")) {
                    TextField("メモ", text: $viewModel.memo)
                        .focused($focusedField, equals: .memo)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                }
                
                // 保存ボタン
                Section {
                    Button(action: {
                        focusedField = nil
                        saveDetailedRecord()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("詳細記録を保存")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isSaving)
                    .listRowBackground(Color.primaryColor)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("詳細記録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
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
            .alert(isPresented: $viewModel.showError) {
                Alert(
                    title: Text("エラー"),
                    message: Text(viewModel.errorMessage ?? "不明なエラーが発生しました"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(
                viewModel.showSuccessMessage ?
                    VStack {
                        Spacer()
                        Text("保存しました！")
                            .padding()
                            .background(Color.accentSuccess)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                            .padding(.bottom, 16)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.spring(), value: viewModel.showSuccessMessage)
                    }
                    : nil
            )
            .sheet(isPresented: $viewModel.showBettingSystemPicker) {
                DetailedBettingSystemPickerView(
                    bettingSystems: viewModel.availableBettingSystems,
                    onSelect: { system in
                        viewModel.selectBettingSystem(system)
                        viewModel.showBettingSystemPicker = false
                    }
                )
            }
            .onAppear {
                // カレンダーから選択された日付を設定
                if let initialDate = initialDate {
                    viewModel.selectedDate = initialDate
                }
                // データがまだロードされていない場合は再ロード
                if viewModel.gambleTypes.isEmpty {
                    viewModel.loadGambleTypes()
                }
            }
        }
    }
    
    // 詳細記録の保存（賭式を任意にする）
    private func saveDetailedRecord() {
        // 賭式が空の場合はデフォルト値を設定
        if viewModel.bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.bettingSystem = "-"
        }
        
        viewModel.saveBetRecord()
        
        // 保存成功したら1.5秒後に閉じる
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if viewModel.showSuccessMessage {
                dismiss()
            }
        }
    }
}

// 詳細版ギャンブル種別ボタン
private struct DetailedTypeButton: View {
    let gambleType: GambleTypeModel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? gambleType.color : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: gambleType.icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isSelected ? .white : .gray)
                }
                
                Text(gambleType.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? gambleType.color : .gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// 詳細版賭式選択ピッカー
private struct DetailedBettingSystemPickerView: View {
    let bettingSystems: [BettingSystem]
    let onSelect: (BettingSystem) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bettingSystems) { system in
                    Button(action: {
                        onSelect(system)
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(system.name)
                                .font(.headline)
                            
                            Text(system.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("賭式を選択")
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

#Preview {
    DetailedBetRecordView()
        .environmentObject(AppState())
}
