import SwiftUI
import SwiftData
import Foundation
import UserNotifications
import Combine

// MARK: - Главный экран модуля Work
struct WorkSchedulerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.exitPortfolioApp) var exitApp // 🔹 Наша команда для выхода в портфолио
    
    @Query(sort: \Shift.date) private var shifts: [Shift]
    @Query(sort: \PartnerShift.date) private var partnerShifts: [PartnerShift]
    
    @State private var showReminder = false
    @State private var showEditSchedule = false
    @State private var showAllShifts = false
    
    @State private var today = Date()
    @State private var referenceDate = Date()
    
    @GestureState private var dragOffset: CGFloat = 0
    @State private var isAnimating = false
    
    private var todayShift: Shift? {
        shifts.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    private var status: String {
        todayShift == nil ? "Выходной" : "Рабочий"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 🔹 Фон
                LinearGradient(colors: [.blue.opacity(0.4), .green.opacity(0.3)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Обновленный минималистичный хедер
                    headerPanel
                    
                    Spacer()
                    monthSelector
                    
                    CalendarView(
                        shifts: shifts,
                        partnerShifts: partnerShifts,
                        referenceDate: referenceDate
                    )
                    .padding(.horizontal)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 5)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 40)
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                guard !isAnimating else { return }
                                let threshold: CGFloat = 80
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    if value.translation.width < -threshold {
                                        goToNextMonth()
                                    } else if value.translation.width > threshold {
                                        goToPreviousMonth()
                                    }
                                }
                            }
                    )
                    Spacer()
                }
                
                // 🔹 Плавающая кнопка (Все смены)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAllShifts = true
                        } label: {
                            Image(systemName: "list.bullet.rectangle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .padding()
                                .foregroundColor(.white)
                                .background(
                                    LinearGradient(colors: [.blue, .green],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                                .shadow(radius: 6)
                        }
                        .padding()
                    }
                }
            }
            // Скрываем стандартный навигационный бар для минимализма
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                    today = Date()
                }
            }
            .sheet(isPresented: $showEditSchedule) {
                EditScheduleView()
            }
            .sheet(isPresented: $showReminder) {
                ReminderView()
            }
            .sheet(isPresented: $showAllShifts) {
                AllShiftsView(shifts: shifts)
            }
        }
    }
    
    // MARK: - Header Panel (Обновленный минималистичный дизайн)
    private var headerPanel: some View {
        HStack {
            // 🔹 Меню Настроек
            Menu {
                Button(action: { showEditSchedule = true }) {
                    Label("Редактировать смены", systemImage: "calendar.badge.clock")
                }
                
                Divider()
                
                Button(role: .destructive, action: { exitApp() }) {
                    Label("Выйти в меню", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack {
                Text(today, format: .dateTime.day().month().year())
                    .font(.headline)
                Text(status)
                    .font(.subheadline)
                    .foregroundColor(status == "Рабочий" ? .green : .red)
            }
            
            Spacer()
            
            // 🔹 Кнопка Уведомлений
            Button(action: { showReminder = true }) {
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.primary)
                    .padding(8)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 5)
        .padding(.horizontal)
        // Делаем отступ от верхнего края экрана (безопасной зоны)
        .padding(.top, 10)
    }
    
    // MARK: - Month selector
    private var monthSelector: some View {
        HStack {
            Button(action: { goToPreviousMonth() }) {
                Image(systemName: "chevron.left")
            }
            
            Spacer()
            Text(referenceDate, format: .dateTime.month().year())
                .font(.headline)
            Spacer()
            
            Button(action: { goToNextMonth() }) {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 3)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    private func goToNextMonth() {
        guard let next = Calendar.current.date(byAdding: .month, value: 1, to: referenceDate) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            referenceDate = next
        }
    }
    
    private func goToPreviousMonth() {
        guard let prev = Calendar.current.date(byAdding: .month, value: -1, to: referenceDate) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            referenceDate = prev
        }
    }
}

// MARK: - Остальные View (Оставил без изменений, они отлично работают)

struct AllShiftsView: View {
    let shifts: [Shift]
    
    private var groupedByMonth: [(month: String, shifts: [Shift])] {
        let dict = Dictionary(grouping: shifts) { shift in
            shift.date.formatted(.dateTime.year().month(.wide))
        }
        return dict
            .map { ($0.key, $0.value.sorted(by: { $0.date < $1.date })) }
            .sorted { $0.month > $1.month }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByMonth, id: \.month) { monthGroup in
                    Section(monthGroup.month) {
                        ForEach(monthGroup.shifts, id: \.id) { shift in
                            AllShiftRowView(shift: shift)
                        }
                    }
                }
            }
            .navigationTitle("Усі зміни")
            .listStyle(.insetGrouped)
        }
    }
}

private struct AllShiftRowView: View {
    let shift: Shift
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(shift.date.formatted(date: .abbreviated, time: .omitted))
                .font(.headline)
            Text("\(shift.startTime!.formatted(date: .omitted, time: .shortened)) - \(shift.endTime!.formatted(date: .omitted, time: .shortened))")
            
            if let breakStart = shift.breakStart {
                Text("Обід: \(breakStart.formatted(date: .omitted, time: .shortened))")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

struct CalendarView: View {
    let shifts: [Shift]
    let partnerShifts: [PartnerShift]
    let referenceDate: Date

    @State private var selectedDay: Date?
    @State private var selectedShift: Shift?
    @State private var selectedPartnerShift: PartnerShift?
    @State private var showDetail = false
    @State private var showDayOffOverlay = false

    private let calendar = Calendar.current

    var body: some View {
        let days = makeMonthDays(for: referenceDate)

        VStack(spacing: 8) {
            HStack(spacing: 0) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { day in
                    Text(day)
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(days.indices, id: \.self) { index in
                    if let day = days[index] {
                        let shift = shifts.first { calendar.isDate($0.date, inSameDayAs: day) }
                        let partnerShift = partnerShifts.first { calendar.isDate($0.date, inSameDayAs: day) }

                        CalendarDayCell(
                            day: day,
                            shift: shift,
                            partnerShift: partnerShift,
                            calendar: calendar
                        )
                        .onTapGesture {
                            selectedDay = day
                            selectedShift = shift
                            selectedPartnerShift = partnerShift
                            if shift != nil || partnerShift != nil {
                                showDetail = true
                            } else {
                                showDayOffOverlay = true
                            }
                        }
                    } else {
                        Color.clear.frame(height: 70)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .sheet(isPresented: $showDetail) {
            if let day = selectedDay {
                WorkDayDetailView(day: day, shift: selectedShift, partnerShift: selectedPartnerShift)
            }
        }
        .overlay {
            if showDayOffOverlay, let day = selectedDay {
                DayOffOverlay(day: day, show: $showDayOffOverlay)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.spring(duration: 0.35), value: showDayOffOverlay)
    }

    private func makeMonthDays(for reference: Date) -> [Date?] {
        guard
            let range = calendar.range(of: .day, in: .month, for: reference),
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: reference))
        else { return [] }

        let firstWeekday = (calendar.component(.weekday, from: startOfMonth) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: startOfMonth))
        }
        return days
    }
}

struct CalendarDayCell: View {
    let day: Date
    let shift: Shift?
    let partnerShift: PartnerShift?
    let calendar: Calendar

    private func timeText(_ date: Date?) -> String {
        date?.formatted(date: .omitted, time: .shortened) ?? ""
    }

    private func background(for shift: Shift?, partner: PartnerShift?) -> some View {
        let gradient: LinearGradient
        switch (shift, partner) {
        case (nil, nil):
            gradient = LinearGradient(colors: [.green.opacity(0.15), .green.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case (_?, nil):
            gradient = LinearGradient(colors: [.blue.opacity(0.15), .blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case (nil, _?):
            gradient = LinearGradient(colors: [.purple.opacity(0.15), .purple.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case (_?, _?):
            gradient = LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        return RoundedRectangle(cornerRadius: 12)
            .fill(gradient)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(calendar.component(.day, from: day))")
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .padding(.top, 4)

            Spacer(minLength: 2)

            if shift == nil && partnerShift == nil {
                VStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.green.opacity(0.7))
                    Text("Выходной")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .transition(.opacity)
            } else {
                if let shift = shift, let start = shift.startTime, let end = shift.endTime {
                    Label("\(timeText(start)) – \(timeText(end))", systemImage: "person.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                if let partner = partnerShift, let start = partner.startTime, let end = partner.endTime {
                    Label("\(timeText(start)) – \(timeText(end))", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, minHeight: 60, maxHeight: 60)
        .padding(4)
        .background(background(for: shift, partner: partnerShift))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.1), lineWidth: 0.5))
        .contentShape(Rectangle())
    }
}

// MARK: - Остальные View вырезаны для краткости обзора (Добавь сюда DayOffOverlay, WorkDayDetailView, ShiftProgressSection, EditScheduleView, ReminderView и т.д. из своего исходника без изменений)
struct EditScheduleView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    @Query private var templates: [ShiftTemplate]
    
    enum SelectionMode { case days, period }
    enum ShiftOwner { case me, partner }
    
    @State private var selectionMode: SelectionMode = .days
    @State private var selectedDates: Set<Date> = []
    @State private var startPeriod = Date()
    @State private var endPeriod = Date()
    
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isAddingShift = false
    @State private var shiftOwner: ShiftOwner = .me
    @State private var isCrossDay = false
    
    @State private var referenceDate = Date()
    @State private var showAddTemplate = false
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.12), .purple.opacity(0.1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                headerView
                selectionControls
                
                ScrollView {
                    if selectionMode == .days {
                        calendarGrid
                    } else {
                        periodPickers
                    }
                }
                
                templateSection
                actionsSection
            }
            .sheet(isPresented: $showAddTemplate) {
                AddTemplateView()
            }
        }
    }
}

// MARK: - Верхняя панель месяца
private extension EditScheduleView {
    var headerView: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(referenceDate, format: .dateTime.month(.wide).year())
                .font(.title2).bold()
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

// MARK: - Переключатель режима
private extension EditScheduleView {
    var selectionControls: some View {
        VStack {
            Picker("Режим", selection: $selectionMode) {
                Text("Отдельные дни").tag(SelectionMode.days)
                Text("Период").tag(SelectionMode.period)
            }
            .pickerStyle(.segmented)
            .padding(10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}

// MARK: - Календарь
private extension EditScheduleView {
    var calendarGrid: some View {
        let days = makeMonthDay(for: referenceDate)
        return VStack(spacing: 8) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { dow in
                    Text(dow)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0 ..< days.count, id: \.self) { idx in
                    let optionalDay = days[idx]
                    if let day = optionalDay {
                        let isSelected = selectedDates.contains { calendar.isDate($0, inSameDayAs: day) }
                        CalendarDayCellSimple(day: day, isSelected: isSelected) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                toggleDate(day)
                            }
                        }
                    } else {
                        Color.clear.frame(minWidth: 42, minHeight: 42)
                    }
                }
            }
            .padding(.horizontal, 6)
            .animation(.easeInOut(duration: 0.25), value: selectedDates)
        }
        .padding(.horizontal)
    }
    
    func makeMonthDay(for reference: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: reference),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: reference)) else {
            return []
        }
        var days: [Date?] = []
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth)
        let mondayIndex = 2
        let leadingBlanks = (weekdayOfFirst - mondayIndex + 7) % 7
        days.append(contentsOf: Array(repeating: nil, count: leadingBlanks))
        for d in range {
            if let date = calendar.date(byAdding: .day, value: d - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        return days
    }
}

// MARK: - Период выбора
private extension EditScheduleView {
    var periodPickers: some View {
        VStack(spacing: 10) {
            DatePicker("Начало", selection: $startPeriod, displayedComponents: .date)
            DatePicker("Конец", selection: $endPeriod, displayedComponents: .date)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

// MARK: - Шаблоны смен
private extension EditScheduleView {
    var templateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Шаблоны смен").font(.headline)
                Spacer()
                Button(action: { showAddTemplate = true }) {
                    Image(systemName: "plus.circle")
                }
            }
            
            if templates.isEmpty {
                Text("Пока нет шаблонов")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(templates) { template in
                            TemplateCard(template: template) {
                                // 🔹 действие при удалении
                                withAnimation(.spring()) {
                                    context.delete(template)
                                    try? context.save()
                                }
                            }
                            .onTapGesture {
                                // 🔹 логика добавления шаблона по нажатию
                                withAnimation(.spring()) {
                                    if selectionMode == .days {
                                        addTemplate(template, to: Array(selectedDates))
                                    } else {
                                        addTemplateInPeriod(template, from: startPeriod, to: endPeriod)
                                    }
                                    try? context.save()
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 3)
        .padding(.horizontal)
    }
}

// MARK: - Логика
private extension EditScheduleView {
    func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: referenceDate) {
            referenceDate = newDate
            selectedDates.removeAll()
        }
    }
    
    func toggleDate(_ date: Date) {
        if let existing = selectedDates.first(where: { calendar.isDate($0, inSameDayAs: date) }) {
            selectedDates.remove(existing)
        } else {
            selectedDates.insert(date)
        }
    }
    
    func addShiftWithCrossDay(startDate: Date, startTime: Date, endTime: Date, isCrossDay: Bool) {
        let endDate = isCrossDay ? calendar.date(byAdding: .day, value: 1, to: startDate)! : startDate
        let start = combine(date: startDate, time: startTime)
        let end = combine(date: endDate, time: endTime)
        
        if shiftOwner == .me {
            context.insert(Shift(date: startDate, startTime: start, endTime: end))
        } else {
            context.insert(PartnerShift(date: startDate, startTime: start, endTime: end))
        }
    }
    
    func addTemplate(_ template: ShiftTemplate, to dates: [Date]) {
        for date in dates {
            let endDate = template.isCrossDay ? calendar.date(byAdding: .day, value: 1, to: date)! : date
            if template.owner == .me {
                context.insert(Shift(date: date, startTime: combine(date: date, time: template.startTime), endTime: combine(date: endDate, time: template.endTime)))
            } else {
                context.insert(PartnerShift(date: date, startTime: combine(date: date, time: template.startTime), endTime: combine(date: endDate, time: template.endTime)))
            }
        }
    }
    
    func addTemplateInPeriod(_ template: ShiftTemplate, from start: Date, to end: Date) {
        var current = start
        while current <= end {
            addTemplate(template, to: [current])
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
    }
    
    func deleteShifts(for dates: [Date]) {
        if let shifts = try? context.fetch(FetchDescriptor<Shift>()) {
            for shift in shifts where dates.contains(where: { calendar.isDate($0, inSameDayAs: shift.date) }) {
                context.delete(shift)
            }
        }
        if let partnerShifts = try? context.fetch(FetchDescriptor<PartnerShift>()) {
            for shift in partnerShifts where dates.contains(where: { calendar.isDate($0, inSameDayAs: shift.date) }) {
                context.delete(shift)
            }
        }
    }
    
    func deleteShiftsInPeriod(from start: Date, to end: Date) {
        if let shifts = try? context.fetch(FetchDescriptor<Shift>()) {
            for shift in shifts where shift.date >= start && shift.date <= end {
                context.delete(shift)
            }
        }
        if let partnerShifts = try? context.fetch(FetchDescriptor<PartnerShift>()) {
            for shift in partnerShifts where shift.date >= start && shift.date <= end {
                context.delete(shift)
            }
        }
    }
    
    func combine(date: Date, time: Date) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        return calendar.date(from: components) ?? date
    }
}

// MARK: - Карточка шаблона
private struct TemplateCard: View {
    let template: ShiftTemplate
    let onDelete: (() -> Void)?
    
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 🔹 Верхняя строка — название и владелец
            HStack {
                if template.isCrossDay {
                    Image(systemName: "moon.stars.fill")
                        .font(.caption2)
                }
                Text(template.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
                Text(template.owner == .me ? "🟦" : "🟣")
                    .font(.title3)
            }
            .padding(.top, 2)
            
            // 🔹 Время смены
            HStack(spacing: 6) {
                VStack{
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("\(template.startTime.formatted(date: .omitted, time: .shortened)) \(template.endTime.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center) // ⬅️ текст центрируется
                        .lineLimit(nil)                  // ⬅️ не ограничиваем количество строк
                        .fixedSize(horizontal: false, vertical: true) // ⬅️ разрешаем перенос по вертикали
                }
                
                // 🔹 Кнопка удаления (внизу)
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(6)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Spacer()
        }
        .padding(10)
        .frame(width: 140, height: 90)
        .background(
            LinearGradient(
                colors: template.isCrossDay
                ? [.indigo.opacity(0.8), .blue.opacity(0.6)]
                : template.owner == .me
                    ? [.blue.opacity(0.6), .cyan.opacity(0.45)]
                    : [.purple.opacity(0.6), .pink.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 2, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.2), lineWidth: 0.6)
        )
        .scaleEffect(template.isCrossDay ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: template.isCrossDay)
        .alert("Удалить шаблон?", isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive) {
                onDelete?()
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Это действие нельзя отменить.")
        }
    }
}

// MARK: - Действия
private extension EditScheduleView {
    var actionsSection: some View {
        VStack(spacing: 12) {
            Button("Добавить вручную") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isAddingShift.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .shadow(radius: 4)
            
            Button("Удалить смены") {
                if selectionMode == .days {
                    deleteShifts(for: Array(selectedDates))
                } else {
                    deleteShiftsInPeriod(from: startPeriod, to: endPeriod)
                }
                try? context.save()
                dismiss()
            }
            .foregroundColor(.red)
            
            if isAddingShift {
                VStack(spacing: 10) {
                    Picker("Чьи смены", selection: $shiftOwner) {
                        Text("Мої").tag(ShiftOwner.me)
                        Text("Дарʼї").tag(ShiftOwner.partner)
                    }
                    .pickerStyle(.segmented)
                    
                    DatePicker("Дата начала", selection: $startPeriod, displayedComponents: .date)
                    DatePicker("Время начала", selection: $startTime, displayedComponents: .hourAndMinute)
                    Toggle("Смена через полночь", isOn: $isCrossDay)
                        .tint(.purple)
                        .padding(.vertical, 4)
                    DatePicker("Время конца", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    Button("Сохранить") {
                        addShiftWithCrossDay(startDate: startPeriod, startTime: startTime, endTime: endTime, isCrossDay: isCrossDay)
                        try? context.save()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(radius: 6)
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

// MARK: - Окно добавления шаблона
struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var name = ""
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var owner: ShiftTemplate.Owner = .me
    @State private var isCrossDay = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Название шаблона") {
                    TextField("Например: Ночная смена", text: $name)
                }
                
                Section("Чьи смены") {
                    Picker("Чьи смены", selection: $owner) {
                        ForEach(ShiftTemplate.Owner.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    DatePicker("Время начала", selection: $startTime, displayedComponents: .hourAndMinute)
                    Toggle("Смена через полночь", isOn: $isCrossDay)
                        .tint(.purple)
                    DatePicker("Время конца", selection: $endTime, displayedComponents: .hourAndMinute)
                } header: {
                    Text("Параметры смены")
                } footer: {
                    if isCrossDay {
                        Text("Смена закончится на следующий день").foregroundColor(.secondary)
                    }
                }
                
                Button("Сохранить шаблон") {
                    let newTemplate = ShiftTemplate(
                        name: name,
                        startTime: startTime,
                        endTime: endTime,
                        owner: owner,
                        isCrossDay: isCrossDay
                    )
                    context.insert(newTemplate)
                    try? context.save()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(name.isEmpty)
            }
            .navigationTitle("Новый шаблон")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

struct ReminderView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Reminder.date) private var reminders: [Reminder]
    
    @State private var showAddReminder = false
    @State private var showCopiedBanner = false
    @State private var copiedText = ""
    @State private var showNotifications = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // фон
                LinearGradient(
                    colors: [.cyan.opacity(0.15), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Заголовок
                    HStack {
                        // 🔹 Кнопка уведомлений
                        Button {
                            showNotifications = true
                        } label: {
                            Image(systemName: "bell.badge")
                                .font(.system(size: 26))
                                .foregroundStyle(.blue)
                                .padding(.leading)
                        }
                        .sheet(isPresented: $showNotifications) {
                            NotificationHistoryView()
                        }
                        
                        Spacer()
                        
                        Text("Нагадування")
                            .font(.title2.bold())
                        
                        Spacer()
                        
                        Button {
                            showAddReminder = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.blue)
                                .shadow(radius: 3)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 10)
                    
                    // Список нагадувань
                    ScrollView {
                        VStack(spacing: 14) {
                            if reminders.isEmpty {
                                VStack(spacing: 12) {
                                    Spacer()
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("Поки немає нагадувань")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(.top, 60)
                            } else {
                                ForEach(reminders) { reminder in
                                    reminderCard(reminder)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Баннер копирования
                if showCopiedBanner {
                    VStack {
                        HStack {
                            Spacer()
                            Text("📋 Скопійовано!")
                                .font(.subheadline.bold())
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .background(.ultraThinMaterial)
                                .background(Color.green.opacity(0.9))
                                .clipShape(Capsule())
                                .shadow(radius: 3)
                                .padding(.top, 60)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .sheet(isPresented: $showAddReminder) {
                AddReminderView()
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Карточка напоминания
    private func reminderCard(_ reminder: Reminder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Верхняя строка
            HStack {
                Text("ID: \(reminder.clientId)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(reminder.date, format: .dateTime.day().month(.wide).hour().minute())
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            
            // Основной текст
            Text(reminder.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Ссылка (если есть)
            if !reminder.link.isEmpty {
                let link = reminder.link
                Link(destination: URL(string: link)!) {
                    HStack(spacing: 5) {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        Text(link)
                            .font(.caption)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Нижняя панель: копировать / удалить
            HStack {
                Button {
                    copyReminder(reminder)
                } label: {
                    Label("Копіювати", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(role: .destructive) {
                    delete(reminder)
                } label: {
                    Label("Видалити", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .gray.opacity(0.2), radius: 4, y: 2)
        .onTapGesture {
            copyReminder(reminder)
        }
    }
    
    // MARK: - Копирование напоминания
    private func copyReminder(_ reminder: Reminder) {
        var text = "ID клієнта: \(reminder.clientId)\n\(reminder.title)\n"
        if !reminder.link.isEmpty { text += "Посилання: \(reminder.link)\n" }
        
        UIPasteboard.general.string = text
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCopiedBanner = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                showCopiedBanner = false
            }
        }
    }
    
    // MARK: - Удаление
    private func delete(_ reminder: Reminder) {
        context.delete(reminder)
    }
}

struct DayOffOverlay: View {
    let day: Date
    @Binding var show: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0)
                .onTapGesture { show = false}

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(day, format: .dateTime.day().month(.wide).year())
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text("Выходной день 🌿")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Divider().background(.white.opacity(0.3))

                VStack(spacing: 6) {
                    Label("Нет запланированных смен", systemImage: "calendar.badge.clock")
                        .foregroundStyle(.white)
                    Label("Можно посвятить день друг другу", systemImage: "sun.max.fill")
                        .foregroundStyle(.yellow)
                }
                .font(.subheadline)

                Button {
                    withAnimation { show = false }
                } label: {
                    Text("Окей")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green.opacity(0.8))
                .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: 280)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(radius: 20)
            )
        }
    }
}

struct WorkDayDetailView: View {
    let day: Date
    let shift: Shift?
    let partnerShift: PartnerShift?
    
    @State private var showAddBreaks = false
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                headerView
                
                // MARK: - Моя зміна
                if let shift {
                    VStack(spacing: 20) {
                        ShiftSectionView(
                            title: "Моя зміна",
                            systemImage: "person.fill",
                            accentColor: .blue,
                            rows: buildShiftRows(for: shift),
                            onAdd: { showAddBreaks = true }
                        ) {
                            if isCrossDay(start: shift.startTime, end: shift.endTime) {
                                Label("Зміна проходить через північ", systemImage: "moon.zzz.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.blue)
                                    .padding(.top, 4)
                            }
                        }
                        
                        // 🔹 Прогрес-бары для моей смены
                        ShiftProgressSection(shift: shift, currentTime: currentTime)
                    }
                }
                
                // MARK: - Зміна Дарʼї
                if let partnerShift {
                    VStack(spacing: 20) {
                        ShiftSectionView(
                            title: "Зміна Дарʼї",
                            systemImage: "heart.fill",
                            accentColor: .pink,
                            rows: buildPartnerRows(for: partnerShift)
                        ) {
                            if isCrossDay(start: partnerShift.startTime, end: partnerShift.endTime) {
                                Label("Зміна проходить через північ", systemImage: "moon.zzz.fill")
                                    .font(.footnote)
                                    .foregroundStyle(.pink)
                                    .padding(.top, 4)
                            }
                        }
                        
                        ShiftProgressSection(shift: partnerShift, currentTime: currentTime, isPartner: true)
                    }
                }
                
                // MARK: - Якщо немає змін
                if shift == nil && partnerShift == nil {
                    VStack(spacing: 12) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 42))
                            .foregroundStyle(.secondary)
                        Text("На цей день немає змін 🌙")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
        .sheet(isPresented: $showAddBreaks) {
            if let shift {
                AddLunchView(shift: shift)
            }
        }
        .background(
            LinearGradient(colors: [.cyan.opacity(0.15), .purple.opacity(0.1)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Row Data
struct ShiftRowData: Identifiable {
    let id = UUID()
    let label: String
    let time: Date?
}

// MARK: - Components
private extension WorkDayDetailView {
    
    // MARK: Header
    var headerView: some View {
        VStack(spacing: 4) {
            Text(day, format: .dateTime.day().month().year())
                .font(.title2.bold())
            Text(day, format: .dateTime.weekday(.wide))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }
    
    // MARK: Cross-midnight check
    func isCrossDay(start: Date?, end: Date?) -> Bool {
        guard let start, let end else { return false }
        return end < start
    }
    
    // MARK: Build rows
    func buildShiftRows(for shift: Shift) -> [ShiftRowData] {
        [
            .init(label: "🕗 Початок зміни", time: shift.startTime),
            .init(label: "🍽️ Початок обіду", time: shift.breakStart),
            .init(label: "🥗 Кінець обіду", time: shift.breakEnd),
            .init(label: "🍜 Початок 2 обіду", time: shift.secondBreakStart),
            .init(label: "🍵 Кінець 2 обіду", time: shift.secondBreakEnd),
            .init(label: "📋 Планьорка", time: shift.meetingTime),
            .init(label: "🌙 Кінець зміни", time: shift.endTime)
        ].filter { $0.time != nil }
    }
    
    func buildPartnerRows(for partner: PartnerShift) -> [ShiftRowData] {
        [
            .init(label: "🕗 Початок зміни", time: partner.startTime),
            .init(label: "🍽️ Початок обіду", time: partner.breakStart),
            .init(label: "🥗 Кінець обіду", time: partner.breakEnd),
            .init(label: "🌙 Кінець зміни", time: partner.endTime)
        ].filter { $0.time != nil }
    }
}

struct NotificationHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \DailyNotificationRecord.triggerTime, order: .forward)
    private var allRecords: [DailyNotificationRecord]
    
    private var todayRecords: [DailyNotificationRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return allRecords.filter { calendar.isDate($0.date, inSameDayAs: today) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if todayRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                        Text("Сьогодні немає створених сповіщень")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 100)
                } else {
                    List(todayRecords) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(record.triggerTime, format: .dateTime.hour().minute())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(record.category.capitalized)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                            Text(record.title)
                                .font(.headline)
                            Text(record.body)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Сьогоднішні сповіщення")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрити") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Клетка календаря
private struct CalendarDayCellSimple: View {
    let day: Date
    let isSelected: Bool
    let action: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        let dayNumber = calendar.component(.day, from: day)
        Button(action: action) {
            Text("\(dayNumber)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 42, height: 42)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.gradient)
                            .shadow(color: Color.blue.opacity(0.25), radius: 5)
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.thinMaterial)
                    }
                }
                .shadow(radius: isSelected ? 3 : 0)
        }
        .buttonStyle(.plain)
    }
}

struct AddReminderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var clientID = ""
    @State private var title = ""
    @State private var link = ""
    @State private var date = Date()
    
    @FocusState private var focusedField: Field?
    enum Field { case client, title, link }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Заголовок
                    VStack(spacing: 4) {
                        Text("🧭 Нове нагадування")
                            .font(.title2.bold())
                        Text("Введи дані, щоб не забути про важливе")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 10)
                    
                    // Основная карточка формы
                    VStack(spacing: 16) {
                        
                        Group {
                            labeledField("ID клієнта", text: $clientID, placeholder: "Наприклад: 2415 або ABC-92")
                                .focused($focusedField, equals: .client)
                            
                            labeledField("Текст нагадування", text: $title, placeholder: "Наприклад: Зателефонувати клієнту")
                                .focused($focusedField, equals: .title)
                            
                            labeledField("Посилання (за бажанням)", text: $link, placeholder: "https://...")
                                .focused($focusedField, equals: .link)
                        }
                        
                        Divider().padding(.horizontal)
                        
                        // Выбор даты
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Дата та час")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .blue.opacity(0.1), radius: 8, y: 3)
                    .padding(.horizontal)
                    
                    // Кнопка сохранения
                    Button(action: saveReminder) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                            Text("Зберегти нагадування")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .blue.opacity(0.3), radius: 6, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                .padding(.bottom, 30)
            }
            .navigationTitle("Нагадування")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
            }
            .background(
                LinearGradient(
                    colors: [.cyan.opacity(0.18), .purple.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
    }
    
    // MARK: - Поле с заголовком
    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .padding(.vertical, 2)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Сохранение и уведомление
    private func saveReminder() {
        guard !title.isEmpty else { return }
        
        let reminder = Reminder(clientId: clientID, title: title, date: date, link: link)
        context.insert(reminder)
        
        scheduleNotification(for: reminder)
        dismiss()
    }
    
    private func scheduleNotification(for reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = "Нагадування: \(reminder.title)"
        if reminder.link.isEmpty {
            content.body = "Для клієнта: \(reminder.clientId)"
        } else {
            content.body = "Для клієнта: \(reminder.clientId)\nПосилання: \(reminder.link)"
        }
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - ShiftSectionView (без generic, с type-erased footer)
struct ShiftSectionView: View {
    let title: String
    let systemImage: String
    let accentColor: Color
    let rows: [ShiftRowData]
    let onAdd: (() -> Void)?
    private let footerView: AnyView

    // Основной инициализатор с @ViewBuilder footer (возвращаем AnyView)
    init(
        title: String,
        systemImage: String,
        accentColor: Color,
        rows: [ShiftRowData],
        onAdd: (() -> Void)? = nil,
        @ViewBuilder footer: @escaping () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.rows = rows
        self.onAdd = onAdd
        // type-erase footer
        self.footerView = AnyView(footer())
    }

    var body: some View {
        VStack(spacing: 12) {
            // Заголовок секции
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Spacer()
                if let onAdd = onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(accentColor)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Контейнер с данными
            VStack(spacing: 8) {
                ForEach(rows) { row in
                    ShiftRowView(row: row)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: accentColor.opacity(0.15), radius: 6, y: 2)

            // Footer (если не Empty)
            footerView
        }
    }
}

struct ShiftProgressSection: View {
    let shift: Any
    let currentTime: Date
    var isPartner: Bool = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // MARK: - Извлечение времён
    private var startTime: Date? {
        (shift as? Shift)?.startTime ?? (shift as? PartnerShift)?.startTime
    }
    private var breakStart: Date? {
        (shift as? Shift)?.breakStart ?? (shift as? PartnerShift)?.breakStart
    }
    private var breakEnd: Date? {
        (shift as? Shift)?.breakEnd ?? (shift as? PartnerShift)?.breakEnd
    }
    private var breakStart2: Date? {
        (shift as? Shift)?.secondBreakStart
    }
    private var breakEnd2: Date? {
        (shift as? Shift)?.secondBreakEnd
    }
    private var endTime: Date? {
        (shift as? Shift)?.endTime ?? (shift as? PartnerShift)?.endTime
    }
    
    private var color: Color {
        isPartner ? .pink : .blue
    }
    
    // MARK: - UI
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("⏱ Прогрес зміни")
                .font(.headline)
                .foregroundStyle(color)
            
            Group {
                // MARK: До початку зміни / Основний прогрес
                if let start = startTime, let end = endTime {
                    if currentTime < start {
                        Text("До початку зміни: \(timeRemaining(until: start))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if currentTime >= end {
                        Text("Зміна завершена ✅")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        let progress = progressBetween(start: start, end: end)
                        ProgressView(value: progress)
                            .tint(color)
                        Text("Пройшло: \(formattedDuration(since: start, until: currentTime)) із \(formattedDuration(since: start, until: end))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // MARK: Обіди
                if let bStart1 = breakStart, let bEnd1 = breakEnd {
                    if let bStart2 = breakStart2, let bEnd2 = breakEnd2 {
                        // === Первый обед
                        if currentTime < bStart1 {
                            Text("До першого обіду: \(timeRemaining(until: bStart1))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if currentTime >= bStart1 && currentTime <= bEnd1 {
                            let progress1 = progressBetween(start: bStart1, end: bEnd1)
                            ProgressView(value: progress1)
                                .tint(.orange)
                            Text("Перший обід триває: \(formattedDuration(since: bStart1, until: currentTime)) із \(formattedDuration(since: bStart1, until: bEnd1))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if currentTime > bEnd1 && currentTime < bStart2 {
                            Text("Перший обід завершено ☕️")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Divider()
                            Text("До другого обіду: \(timeRemaining(until: bStart2))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if currentTime >= bStart2 && currentTime <= bEnd2 {
                            let progress2 = progressBetween(start: bStart2, end: bEnd2)
                            ProgressView(value: progress2)
                                .tint(.orange)
                            Text("Другий обід триває: \(formattedDuration(since: bStart2, until: currentTime)) із \(formattedDuration(since: bStart2, until: bEnd2))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if currentTime > bEnd2 {
                            Text("Обіди завершено ☑️")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        // === Один обід
                        if currentTime < bStart1 {
                            Text("До обіду: \(timeRemaining(until: bStart1))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if currentTime >= bStart1 && currentTime <= bEnd1 {
                            let progress = progressBetween(start: bStart1, end: bEnd1)
                            ProgressView(value: progress)
                                .tint(.orange)
                            Text("Обід триває: \(formattedDuration(since: bStart1, until: currentTime)) із \(formattedDuration(since: bStart1, until: bEnd1))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else if currentTime > bEnd1 {
                            Text("Обід завершено ☕️")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Обід не заплановано")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let end = endTime, let start = startTime, currentTime >= start && currentTime < end {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        Text("⏳ До кінця зміни:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(timeRemaining(until: end))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(color)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 4)
    }
}

// MARK: - Utils
private extension ShiftProgressSection {
    func progressBetween(start: Date, end: Date) -> Double {
        guard end > start else { return 0 }
        let total = end.timeIntervalSince(start)
        let passed = min(Date().timeIntervalSince(start), total)
        return passed / total
    }
    
    func timeRemaining(until target: Date) -> String {
        let diff = Int(target.timeIntervalSince(Date()))
        guard diff > 0 else { return "00:00:00" }
        let h = diff / 3600
        let m = (diff % 3600) / 60
        let s = diff % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    
    func formattedDuration(since start: Date, until end: Date) -> String {
        let diff = Int(end.timeIntervalSince(start))
        let h = diff / 3600
        let m = (diff % 3600) / 60
        let s = diff % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}

struct AddLunchView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var context
    
    var shift: Shift
    
    // Первый обед
    @State private var breakStart = Date()
    @State private var breakEnd = Date()
    
    // Второй обед
    @State private var secondBreakStart: Date? = nil
    @State private var secondBreakEnd: Date? = nil
    @State private var hasSecondLunch = false
    
    // Планёрка
    @State private var meetingTime: Date? = nil
    @State private var hasMeeting = false
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: Первый обед
                Section("Перший обід") {
                    DatePicker("Початок", selection: $breakStart, displayedComponents: .hourAndMinute)
                    DatePicker("Кінець", selection: $breakEnd, displayedComponents: .hourAndMinute)
                }
                
                // MARK: Второй обед
                Section {
                    Toggle("Додати другий обід", isOn: $hasSecondLunch.animation())
                    if hasSecondLunch {
                        DatePicker("Початок 2 обіду", selection: Binding(
                            get: { secondBreakStart ?? Date() },
                            set: { secondBreakStart = $0 }
                        ), displayedComponents: .hourAndMinute)
                        
                        DatePicker("Кінець 2 обіду", selection: Binding(
                            get: { secondBreakEnd ?? Date() },
                            set: { secondBreakEnd = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
                
                // MARK: Планёрка
                Section {
                    Toggle("Додати планьорку", isOn: $hasMeeting.animation())
                    if hasMeeting {
                        DatePicker("Час планьорки", selection: Binding(
                            get: { meetingTime ?? Date() },
                            set: { meetingTime = $0 }
                        ), displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Обіди та планьорка")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Зберегти") {
                        saveBreaksAndMeeting()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Сохранение и уведомления
    private func saveBreaksAndMeeting() {
        // Сохраняем данные в смену
        shift.breakStart = breakStart
        shift.breakEnd = breakEnd
        
        if hasSecondLunch {
            shift.secondBreakStart = secondBreakStart
            shift.secondBreakEnd = secondBreakEnd
        } else {
            shift.secondBreakStart = nil
            shift.secondBreakEnd = nil
        }
        
        if hasMeeting {
            shift.meetingTime = meetingTime
        } else {
            shift.meetingTime = nil
        }
        
        try? context.save()
        
        // Создаём уведомления
        scheduleLunchNotifications(for: shift)
        scheduleMeetingNotification(for: shift)
        
        dismiss()
    }
    
    // MARK: - Уведомления для обедов
    private func scheduleLunchNotifications(for shift: Shift) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let shiftID = shift.id.uuidString
        
        // перед добавлением новых уведомлений — отменяем старые
        cancelLunchNotifications(for: shift)
        
        func createLunchNotifications(prefix: String, start: Date?, end: Date?) {
            guard let start, let end else { return }
            
            // Подготовка к обеду
            if start > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Підготовка до обіду"
                content.body = "Скоро обід, заверши поточні справи."
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start), repeats: false)
                let request = UNNotificationRequest(identifier: "\(shiftID)_\(prefix)_prep", content: content, trigger: trigger)
                center.add(request)
            }
            
            // Обед начался (через 15 минут)
            if let lunchStart = calendar.date(byAdding: .minute, value: 15, to: start), lunchStart > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Обід розпочався"
                content.body = "Смачного 🍽️"
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: lunchStart), repeats: false)
                let request = UNNotificationRequest(identifier: "\(shiftID)_\(prefix)_start", content: content, trigger: trigger)
                center.add(request)
            }
            
            // Обед заканчивается
            if let beforeEnd = calendar.date(byAdding: .minute, value: -1, to: end), beforeEnd > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Обід закінчується"
                content.body = "Через хвилину повернення до роботи."
                content.sound = .default
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: beforeEnd), repeats: false)
                let request = UNNotificationRequest(identifier: "\(shiftID)_\(prefix)_end", content: content, trigger: trigger)
                center.add(request)
            }
        }
        
        // создаем уведомления для обоих обедов
        createLunchNotifications(prefix: "lunch1", start: shift.breakStart, end: shift.breakEnd)
        createLunchNotifications(prefix: "lunch2", start: shift.secondBreakStart, end: shift.secondBreakEnd)
    }
    
    private func cancelLunchNotifications(for shift: Shift) {
        let center = UNUserNotificationCenter.current()
        let shiftID = shift.id.uuidString
        center.removePendingNotificationRequests(withIdentifiers: [
            "\(shiftID)_lunch1_prep",
            "\(shiftID)_lunch1_start",
            "\(shiftID)_lunch1_end",
            "\(shiftID)_lunch2_prep",
            "\(shiftID)_lunch2_start",
            "\(shiftID)_lunch2_end"
        ])
    }
    
    // MARK: - Уведомление для планёрки
    private func scheduleMeetingNotification(for shift: Shift) {
        guard let meeting = shift.meetingTime, meeting > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Планьорка"
        content.body = "Не забудь про сьогоднішню планьорку 🗓️"
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: meeting),
            repeats: false
        )
        
        let request = UNNotificationRequest(identifier: "\(shift.id.uuidString)_meeting", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - ShiftRowView
struct ShiftRowView: View {
    let row: ShiftRowData
    var body: some View {
        HStack {
            Text(row.label)
                .font(.subheadline)
            Spacer()
            Text(row.time.map { $0.formatted(date: .omitted, time: .shortened) } ?? "—")
                .bold()
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}
