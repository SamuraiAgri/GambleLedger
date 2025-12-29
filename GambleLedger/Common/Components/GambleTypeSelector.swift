// GambleLedger/Common/Components/GambleTypeSelector.swift
import SwiftUI

struct GambleTypeSelector: View {
    let gambleTypes: [GambleTypeModel]
    @Binding var selectedTypeID: UUID?
    let horizontalScroll: Bool
    
    init(
        gambleTypes: [GambleTypeModel],
        selectedTypeID: Binding<UUID?>,
        horizontalScroll: Bool = true
    ) {
        self.gambleTypes = gambleTypes
        self._selectedTypeID = selectedTypeID
        self.horizontalScroll = horizontalScroll
    }
    
    var body: some View {
        Group {
            if horizontalScroll {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        typeButtons
                    }
                    .padding(.vertical, 8)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    typeButtons
                }
            }
        }
    }
    
    private var typeButtons: some View {
        ForEach(gambleTypes) { type in
            GambleTypeSelectorButton(
                gambleType: type,
                isSelected: selectedTypeID == type.id,
                action: {
                    selectedTypeID = type.id
                }
            )
        }
    }
}

// GambleTypeSelectorButton - 名前を変更して競合を解消
struct GambleTypeSelectorButton: View {
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

// プレビュー用のサンプルデータ
struct GambleSelectorPreview: View {
    @State private var selectedID: UUID? = nil
    let sampleTypes = [
        GambleTypeModel(id: UUID(), name: "競馬", icon: "horseshoe", color: .gambleHorse),
        GambleTypeModel(id: UUID(), name: "競艇", icon: "sailboat", color: .gambleBoat),
        GambleTypeModel(id: UUID(), name: "競輪", icon: "bicycle", color: .gambleBike),
        GambleTypeModel(id: UUID(), name: "スポーツ", icon: "sportscourt", color: .gambleSports),
        GambleTypeModel(id: UUID(), name: "パチンコ", icon: "bitcoinsign.circle", color: .gamblePachinko),
        GambleTypeModel(id: UUID(), name: "その他", icon: "dice", color: .gambleOther)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("横スクロール")
                .font(.headline)
            GambleTypeSelector(
                gambleTypes: sampleTypes,
                selectedTypeID: $selectedID
            )
            
            Text("グリッド")
                .font(.headline)
            GambleTypeSelector(
                gambleTypes: sampleTypes,
                selectedTypeID: $selectedID,
                horizontalScroll: false
            )
        }
        .padding()
    }
}

#Preview {
    GambleSelectorPreview()
}
