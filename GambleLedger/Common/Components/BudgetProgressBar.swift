// GambleLedger/Common/Components/BudgetProgressBar.swift
import SwiftUI

struct BudgetProgressBar: View {
    let current: Decimal
    let total: Decimal
    let showPercentage: Bool
    
    init(current: Decimal, total: Decimal, showPercentage: Bool = true) {
        self.current = current
        self.total = total
        self.showPercentage = showPercentage
    }
    
    private var percentage: Double {
        if total == 0 { return 0 }
        let value = Double(truncating: (current / total) as NSNumber)
        return min(max(value, 0), 1)
    }
    
    private var color: Color {
        if percentage < 0.5 {
            return .accentSuccess
        } else if percentage < 0.8 {
            return .accentWarning
        } else {
            return .accentDanger
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showPercentage {
                HStack {
                    Text("\(Int(percentage * 100))%使用")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(current.formatted(.currency(code: "JPY"))) / \(total.formatted(.currency(code: "JPY")))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 8)
                        .opacity(0.2)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: geometry.size.width * CGFloat(percentage), height: 8)
                        .foregroundColor(color)
                }
                .cornerRadius(4)
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BudgetProgressBar(current: 2500, total: 10000)
        BudgetProgressBar(current: 6000, total: 10000)
        BudgetProgressBar(current: 9000, total: 10000)
    }
    .padding()
}
