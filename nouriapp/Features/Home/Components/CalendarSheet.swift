//
//  CalendarSheet.swift
//  nouriapp
//
//  Custom bottom sheet calendar picker matching the specific iOS graphical style.
//

import SwiftUI

struct CalendarSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    
    @State private var currentMonth: Date
    
    let calendar = Calendar.current
    let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._currentMonth = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag indicator
            Capsule()
                .fill(Color.black.opacity(0.12))
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)
            
            // Header Row
            HStack {
                Button("Today") {
                    withAnimation {
                        selectedDate = Date()
                        currentMonth = Date()
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(NouriColors.brandGreen)
                
                Spacer()
                
                Text(monthYearString(from: currentMonth))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(NouriColors.title)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(NouriColors.brandGreen)
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 24)
            
            // Days Header
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.gray.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            
            // Grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 12) {
                ForEach(extractDates()) { dateValue in
                    CardView(value: dateValue)
                        .onTapGesture {
                            if dateValue.day != -1 {
                                selectedDate = dateValue.date
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        // Basic swiping to change month
        .gesture(
            DragGesture().onEnded { value in
                if value.translation.width < -50 {
                    // Swipe Left (Next Month)
                    changeMonth(by: 1)
                } else if value.translation.width > 50 {
                    // Swipe Right (Prev Month)
                    changeMonth(by: -1)
                }
            }
        )
    }
    
    // MARK: - Subcomponents
    
    @ViewBuilder
    private func CardView(value: DateValue) -> some View {
        if value.day != -1 {
            let isSelected = calendar.isDate(value.date, inSameDayAs: selectedDate)
            
            ZStack {
                if isSelected {
                    Circle()
                        .fill(NouriColors.brandGreen)
                        .frame(width: 36, height: 36)
                }
                
                Text("\(value.day)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(isSelected ? Color.white : NouriColors.title)
            }
            .frame(height: 40)
        } else {
            // Empty placeholder for offset
            Color.clear
                .frame(height: 40)
        }
    }
    
    // MARK: - Helpers
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    private func changeMonth(by amount: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: amount, to: currentMonth) {
            withAnimation(.easeInOut) {
                currentMonth = newMonth
            }
        }
    }
    
    private func extractDates() -> [DateValue] {
        var days = [DateValue]()
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        
        // Add offset placeholders
        for _ in 1..<firstWeekday {
            days.append(DateValue(day: -1, date: Date()))
        }
        
        // Add actual days
        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)!
            days.append(DateValue(day: day, date: date))
        }
        
        return days
    }
}

// Data Model for the grid
struct DateValue: Identifiable {
    var id = UUID()
    var day: Int
    var date: Date
}

#Preview {
    CalendarSheet(selectedDate: .constant(Date()))
        .ignoresSafeArea(edges: .bottom)
}
