// GambleLedger/Views/BetRecord/BetRecordView.swift
import SwiftUI

struct BetRecordView: View {
    @StateObject private var viewModel = BetRecordViewModel()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // 日時選択セクション
                Section(header: Text("日時")) {
                    DatePicker("", selection: $viewModel.selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .labelsHidden()
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
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                }
                
                // イベント情報セクション
                Section(header: Text("イベント情報")) {
                    TextField("試合/レース名", text: $viewModel.eventName)
                    TextField("賭式", text: $viewModel.bettingSystem)
                }
                
                // 金額情報セクション
                Section(header: Text("金額情報")) {
                    HStack {
                        Text("賭け金")
                        TextField("0", text: $viewModel.betAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("円")
                    }
                    
                    HStack {
                        Text("払戻金")
                        TextField("0", text: $viewModel.returnAmount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
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
                }
                
                // 保存ボタン
                Section {
                    Button(action: {
                        viewModel.saveBetRecord()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("ベット記録を保存")
                                    .fontWeight(.bold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(viewModel.isLoading)
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
                    }
                    : nil
            )
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

#Preview {
    BetRecordView().environmentObject(AppState())
}
