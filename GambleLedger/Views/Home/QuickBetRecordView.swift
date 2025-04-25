// GambleLedger/Views/BetRecord/QuickBetRecordView.swift
import SwiftUI

struct QuickBetRecordView: View {
    @StateObject private var viewModel = BetRecordViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // 入力ステップ
    @State private var currentStep = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // ステップインジケーター
                StepIndicator(
                    currentStep: currentStep,
                    totalSteps: 4,
                    labels: ["種別", "イベント", "金額", "確認"]
                )
                .padding()
                
                // ステップごとの内容
                switch currentStep {
                case 0:
                    // 種別選択
                    GambleTypeStep(
                        gambleTypes: viewModel.gambleTypes,
                        selectedTypeID: $viewModel.selectedGambleTypeID
                    )
                case 1:
                    // イベント情報
                    EventInfoStep(
                        date: $viewModel.selectedDate,
                        eventName: $viewModel.eventName,
                        bettingSystem: $viewModel.bettingSystem
                    )
                case 2:
                    // 金額情報
                    AmountInfoStep(
                        betAmount: $viewModel.betAmount,
                        returnAmount: $viewModel.returnAmount,
                        memo: $viewModel.memo
                    )
                case 3:
                    // 確認
                    ConfirmationStep(viewModel: viewModel)
                default:
                    EmptyView()
                }
                
                Spacer()
                
                // ナビゲーションボタン
                HStack {
                    // 戻るボタン
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "xmark")
                                Text("キャンセル")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                        .frame(width: 16)
                    
                    // 次へ／保存ボタン
                    if currentStep < 3 {
                        Button(action: {
                            withAnimation {
                                if validateCurrentStep() {
                                    currentStep += 1
                                }
                            }
                        }) {
                            HStack {
                                Text("次へ")
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    } else {
                        Button(action: {
                            viewModel.saveBetRecord()
                            dismiss()
                        }) {
                            HStack {
                                Text("保存")
                                Image(systemName: "checkmark")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.primaryColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }
                .padding()
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
                viewModel.isLoading ?
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle())
                    : nil
            )
        }
    }
    
    // 現在のステップの入力を検証
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 0:
            // 種別選択の検証
            if viewModel.selectedGambleTypeID == nil {
                appState.showAlert(message: "ギャンブル種別を選択してください。")
                return false
            }
        case 1:
            // イベント情報の検証
            if viewModel.eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appState.showAlert(message: "イベント名を入力してください。")
                return false
            }
            
            if viewModel.bettingSystem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appState.showAlert(message: "賭式を入力してください。")
                return false
            }
        case 2:
            // 金額情報の検証
            if viewModel.betAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appState.showAlert(message: "賭け金額を入力してください。")
                return false
            }
            
            if viewModel.returnAmount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                appState.showAlert(message: "払戻金額を入力してください。")
                return false
            }
            
            if Decimal(string: viewModel.betAmount.replacingOccurrences(of: ",", with: "")) == nil {
                appState.showAlert(message: "有効な賭け金額を入力してください。")
                return false
            }
            
            if Decimal(string: viewModel.returnAmount.replacingOccurrences(of: ",", with: "")) == nil {
                appState.showAlert(message: "有効な払戻金額を入力してください。")
                return false
            }
        default:
            break
        }
        
        return true
    }
}

// ステップインジケーター
struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let labels: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            // インジケーターバー
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .frame(height: 4)
                        .foregroundColor(index <= currentStep ? .primaryColor : .gray.opacity(0.3))
                    
                    if index < totalSteps - 1 {
                        Spacer()
                            .frame(width: 2)
                    }
                }
            }
            
            // ステップラベル
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Text(labels[index])
                        .font(.caption)
                        .foregroundColor(index <= currentStep ? .primaryColor : .gray)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// ギャンブル種別選択ステップ
struct GambleTypeStep: View {
    let gambleTypes: [GambleTypeModel]
    @Binding var selectedTypeID: UUID?
    
    var body: some View {
        VStack(spacing: 24) {
            Text("ギャンブル種別を選択してください")
                .font(.headline)
            
            GambleTypeSelector(
                gambleTypes: gambleTypes,
                selectedTypeID: $selectedTypeID,
                horizontalScroll: false
            )
            .padding(.horizontal)
        }
        .padding()
    }
}

// イベント情報ステップ
struct EventInfoStep: View {
    @Binding var date: Date
    @Binding var eventName: String
    @Binding var bettingSystem: String
    
    var body: some View {
        Form {
            Section(header: Text("日時")) {
                DatePicker("日付", selection: $date, displayedComponents: [.date, .hourAndMinute])
            }
            
            Section(header: Text("イベント情報")) {
                TextField("イベント/試合名", text: $eventName)
                    .autocapitalization(.none)
                
                TextField("賭式", text: $bettingSystem)
                    .autocapitalization(.none)
            }
        }
    }
}

// 金額情報ステップ
struct AmountInfoStep: View {
    @Binding var betAmount: String
    @Binding var returnAmount: String
    @Binding var memo: String
    
    private var profit: Double {
        let bet = Double(betAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let ret = Double(returnAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        return ret - bet
    }
    
    private var roi: Double {
        let bet = Double(betAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        let ret = Double(returnAmount.replacingOccurrences(of: ",", with: "")) ?? 0
        
        if bet == 0 { return 0 }
        return ((ret / bet) - 1) * 100
    }
    
    var body: some View {
        Form {
            Section(header: Text("金額情報")) {
                HStack {
                    Text("賭け金額")
                    TextField("0", text: $betAmount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("円")
                }
                
                HStack {
                    Text("払戻金額")
                    TextField("0", text: $returnAmount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("円")
                }
                
                if let bet = Double(betAmount.replacingOccurrences(of: ",", with: "")),
                   let ret = Double(returnAmount.replacingOccurrences(of: ",", with: "")),
                   bet > 0 {
                    
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
            
            Section(header: Text("メモ (任意)")) {
                TextField("メモを入力", text: $memo)
            }
        }
    }
}

// 確認ステップ
struct ConfirmationStep: View {
    @ObservedObject var viewModel: BetRecordViewModel
    
    private var selectedGambleType: GambleTypeModel? {
        viewModel.gambleTypes.first { $0.id == viewModel.selectedGambleTypeID }
    }
    
    private var profit: Decimal {
        guard let betAmount = Decimal(string: viewModel.betAmount.replacingOccurrences(of: ",", with: "")),
              let returnAmount = Decimal(string: viewModel.returnAmount.replacingOccurrences(of: ",", with: "")) else {
            return 0
        }
        
        return returnAmount - betAmount
    }
    
    private var roi: Decimal {
        guard let betAmount = Decimal(string: viewModel.betAmount.replacingOccurrences(of: ",", with: "")),
              let returnAmount = Decimal(string: viewModel.returnAmount.replacingOccurrences(of: ",", with: "")),
              betAmount > 0 else {
            return 0
        }
        
        return ((returnAmount / betAmount) - 1) * 100
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("入力内容の確認")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // ギャンブル種別
                ConfirmationRow(
                    label: "ギャンブル種別",
                    value: selectedGambleType?.name ?? "未選択",
                    icon: selectedGambleType?.icon ?? "questionmark.circle",
                    color: selectedGambleType?.color ?? .gray
                )
                
                // イベント情報
                ConfirmationRow(
                    label: "日時",
                    value: viewModel.selectedDate.formattedString(format: "yyyy/MM/dd HH:mm"),
                    icon: "calendar",
                    color: .primaryColor
                )
                
                ConfirmationRow(
                    label: "イベント名",
                    value: viewModel.eventName,
                    icon: "ticket",
                    color: .secondaryColor
                )
                
                ConfirmationRow(
                    label: "賭式",
                    value: viewModel.bettingSystem,
                    icon: "list.bullet",
                    color: .secondaryColor
                )
                
                // 金額情報
                ConfirmationRow(
                    label: "賭け金額",
                    value: "\(viewModel.betAmount) 円",
                    icon: "banknote",
                    color: .primaryColor
                )
                
                ConfirmationRow(
                    label: "払戻金額",
                    value: "\(viewModel.returnAmount) 円",
                    icon: "arrow.left.arrow.right",
                    color: .primaryColor
                )
                
                ConfirmationRow(
                    label: "損益",
                    value: "\(profit.formatted(.currency(code: "JPY")))",
                    icon: "arrow.up.arrow.down",
                    color: profit >= 0 ? .accentSuccess : .accentDanger
                )
                
                ConfirmationRow(
                    label: "回収率",
                    value: "\(roi, specifier: "%.1f") %",
                    icon: "percent",
                    color: roi >= 0 ? .accentSuccess : .accentDanger
                )
                
                // メモ（あれば）
                if !viewModel.memo.isEmpty {
                    ConfirmationRow(
                        label: "メモ",
                        value: viewModel.memo,
                        icon: "note.text",
                        color: .gray
                    )
                }
            }
            .padding()
        }
    }
}

// 確認行
struct ConfirmationRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .padding(6)
                .background(color)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    QuickBetRecordView().environmentObject(AppState())
}
