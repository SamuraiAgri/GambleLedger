// GambleLedger/Views/Home/Components/CalendarView.swift
import SwiftUI

/// カレンダービュー - 日別の収支を視覚的に表示
struct CalendarView: View {
    let month: Date
    let dailyProfits: [Date: Decimal]
    let dailyBets: [Date: Decimal] // 日別の賭け金額を追加
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
                            betAmount: dailyBets[calendar.startOfDay(for: date)],
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                            action: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 70)
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
    let betAmount: Decimal?
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
    
    // 賭け金額のフォーマット
    private func formatBetAmount(_ amount: Decimal) -> String {
        let nsNumber = NSDecimalNumber(decimal: amount)
        let value = nsNumber.intValue
        
        if value >= 10000 {
            let man = value / 10000
            let sen = (value % 10000) / 1000
            if sen > 0 {
                return "\(man)万\(sen)千"
            } else {
                return "\(man)万"
            }
        } else if value >= 1000 {
            return "\(value / 1000)千"
        } else {
            return "\(value)"
        }
    }
    
    // 収支のフォーマット（+2千円、-1万など）
    private func formatProfit(_ profit: Decimal) -> String {
        let nsNumber = NSDecimalNumber(decimal: profit)
        let value = abs(nsNumber.intValue)
        let sign = profit > 0 ? "+" : (profit < 0 ? "-" : "")
        
        if value >= 10000 {
            let man = value / 10000
            let sen = (value % 10000) / 1000
            if sen > 0 {
                return "\(sign)\(man)万\(sen)千"
            } else {
                return "\(sign)\(man)万"
            }
        } else if value >= 1000 {
            return "\(sign)\(value / 1000)千"
        } else if value > 0 {
            return "\(sign)\(value)"
        } else {
            return "±0"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // 日付（固定位置）
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .bold : .regular))
                    .foregroundColor(isToday ? .white : (isSelected ? .primaryColor : .primary))
                    .frame(height: 16)
                
                // 賭け金額（あれば表示）
                if let betAmount = betAmount, betAmount > 0 {
                    Text(formatBetAmount(betAmount))
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                        .frame(height: 12)
                } else {
                    Spacer()
                        .frame(height: 12)
                }
                
                // 収支（あれば表示）
                if let profit = profit {
                    Text(formatProfit(profit))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(profitColor)
                        .frame(height: 14)
                } else {
                    Spacer()
                        .frame(height: 14)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 70)
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
        dailyBets: [
            Date().addingTimeInterval(-86400 * 2): Decimal(10000),
            Date().addingTimeInterval(-86400): Decimal(5000),
            Date(): Decimal(20000)
        ],
        onDateSelected: { _ in }
    )
    .padding()
}
