// GambleLedger/Views/Home/Components/CalendarView.swift
import SwiftUI

/// カレンダービュー - 日別の収支を視覚的に表示
struct CalendarView: View {
    let month: Date
    let dailyProfits: [Date: Decimal]
    let onDateSelected: (Date) -> Void
    
    @State private var selectedDate: Date?
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "月", "火", "水", "木", "金", "土"]
    
    var body: some View {
        VStack(spacing: 16) {
            // 月の表示
            HStack {
                Text(month.formatted(.dateTime.year().month(.wide)))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            // 曜日ヘッダー
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
            
            // カレンダーグリッド
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            profit: dailyProfits[calendar.startOfDay(for: date)],
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            action: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 60)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.vertical)
    }
    
    // 月の日付配列を取得（空白含む）
    private func getDaysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        let numberOfDays = calendar.range(of: .day, in: .month, for: month)?.count ?? 0
        
        // 最初の空白
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)
        
        // 日付を追加
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                days.append(date)
            }
        }
        
        // 最後の空白を追加して7の倍数にする
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

/// カレンダーの日付セル
struct CalendarDayCell: View {
    let date: Date
    let profit: Decimal?
    let isToday: Bool
    let isSelected: Bool
    let action: () -> Void
    
    private var profitColor: Color {
        guard let profit = profit else { return .clear }
        if profit > 0 {
            return .accentSuccess
        } else if profit < 0 {
            return .accentDanger
        } else {
            return .secondary
        }
    }
    
    private var profitSymbol: String {
        guard let profit = profit else { return "" }
        if profit > 0 {
            return "+"
        } else if profit < 0 {
            return "-"
        } else {
            return "="
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : (isSelected ? .primaryColor : .primary))
                
                if profit != nil {
                    Text(profitSymbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(profitColor)
                } else {
                    Text(" ")
                        .font(.system(size: 14))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isToday ? Color.primaryColor : (isSelected ? Color.primaryColor.opacity(0.1) : Color.backgroundSecondary))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(profitColor.opacity(0.3), lineWidth: profit != nil ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CalendarView(
        month: Date(),
        dailyProfits: [
            Date().addingTimeInterval(-86400 * 2): Decimal(5000),
            Date().addingTimeInterval(-86400): Decimal(-3000),
            Date(): Decimal(10000)
        ],
        onDateSelected: { _ in }
    )
    .padding()
}
