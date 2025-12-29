// GambleLedger/Views/BetRecord/BetRecordView.swift
import SwiftUI

struct BetRecordView: View {
    @StateObject private var viewModel = BetRecordViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // キーボード管理
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
                    
                    HStack {
                        TextField("賭式", text: $viewModel.bettingSystem)
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
                
                // メモセクション
                Section(header: Text("メモ")) {
                    TextField("メモ（任意）", text: $viewModel.memo)
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
                        viewModel.saveBetRecord()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("ベット記録を保存")
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
            .navigationTitle("ベット記録")
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
            .overlay(
                viewModel.isLoading && !viewModel.isSaving ?
                    ZStack {
                        Color.black.opacity(0.2)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .primaryColor))
                            
                            Text("読み込み中...")
                                .font(.caption)
                                .foregroundColor(.primaryColor)
                        }
                        .padding(24)
                        .background(Color.backgroundSecondary)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    : nil
            )
            .sheet(isPresented: $viewModel.showBettingSystemPicker) {
                BettingSystemPickerView(
                    bettingSystems: viewModel.availableBettingSystems,
                    onSelect: { system in
                        viewModel.selectBettingSystem(system)
                        viewModel.showBettingSystemPicker = false
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Button(action: {
                            if let currentField = focusedField {
                                switch currentField {
                                case .eventName:
                                    focusedField = nil
                                case .bettingSystem:
                                    focusedField = .eventName
                                case .betAmount:
                                    focusedField = .bettingSystem
                                case .returnAmount:
                                    focusedField = .betAmount
                                case .memo:
                                    focusedField = .returnAmount
                                }
                            }
                        }) {
                            Image(systemName: "chevron.up")
                        }
                        
                        Button(action: {
                            if let currentField = focusedField {
                                switch currentField {
                                case .eventName:
                                    focusedField = .bettingSystem
                                case .bettingSystem:
                                    focusedField = .betAmount
                                case .betAmount:
                                    focusedField = .returnAmount
                                case .returnAmount:
                                    focusedField = .memo
                                case .memo:
                                    focusedField = nil
                                }
                            }
                        }) {
                            Image(systemName: "chevron.down")
                        }
                        Spacer()
                                                
                                                Button("完了") {
                                                    focusedField = nil
                                                }
                                            }
                                        }
                                    }
                                    .onTapGesture {
                                        // キーボード外タップでフォーカス解除
                                        focusedField = nil
                                    }
                                }
                            }
                        }

                        // ギャンブル種別ボタン (名前を変更)
                        struct TypeButton: View {
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
                            }
                        }

                        // 賭式選択ピッカービュー
                        struct BettingSystemPickerView: View {
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
                                            Button("キャンセル") {
                                                dismiss()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        #Preview {
                            BetRecordView().environmentObject(AppState())
                        }
