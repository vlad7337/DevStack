import SwiftUI
import SwiftData
import UserNotifications

// MARK: - 1. Среда для выхода из приложений
struct PortfolioExitKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var exitPortfolioApp: () -> Void {
        get { self[PortfolioExitKey.self] }
        set { self[PortfolioExitKey.self] = newValue }
    }
}

// MARK: - 2. Модели и SwiftData

// Перечисление всех твоих модулей
enum AppModule: String, Codable, CaseIterable {
    case work, study, finance, ships, esp, assistant
    
    var name: String {
        switch self {
        case .work: return "Sheduler (Work)"
        case .study: return "Sheduler (Study)"
        case .finance: return "FinLit"
        case .ships: return "ShipsTraker"
        case .esp: return "EspHome"
        case .assistant: return "Assistant"
        }
    }
    
    var color: Color {
        switch self {
        case .work: return .blue
        case .study: return .green
        case .finance: return .orange
        case .ships: return .red
        case .esp: return .purple
        case .assistant: return .cyan
        }
    }
    
    // Возвращаем нужный экран в зависимости от модуля
    @ViewBuilder
    func destination() -> some View {
        switch self {
        case .work: WorkSchedulerView()
        case .study: Text("Study View")
        case .finance: Text("Finance View")
        case .ships: Text("Ships View")
        case .esp: Text("ESP32 Управление умным домом") // Твой проект на ESP32!
        case .assistant: Text("AI View")
        }
    }
}

// MARK: - 4. Главное Меню
struct ContentView: View {
    @Environment(\.modelContext) private var context
    // Запрашиваем карточки из базы, отсортированные по параметру order
    @Query(sort: \AppCardModel.order) private var apps: [AppCardModel]
    
    @State private var scrollSelection: UUID?
    @State private var showingReorderSheet = false
    @State private var showingNotReadyAlert = false
    @State private var showingTimerAlert = false
    
    @Namespace private var animation
    @State private var openedApp: AppCardModel? = nil
    @State private var showAppContent = false
    
    var currentIndex: Int { apps.firstIndex(where: { $0.id == scrollSelection }) ?? 0 }
    var currentColor: Color { apps.isEmpty ? .gray : apps[currentIndex].type.color }
    
    var body: some View {
        ZStack {
            // ФОНОВЫЙ СЛОЙ (Карусель)
            NavigationStack {
                ZStack {
                    LinearGradient(colors: [currentColor.opacity(0.6), currentColor.opacity(0.2), Color(UIColor.systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .ignoresSafeArea()
                        .animation(.easeInOut(duration: 0.6), value: scrollSelection)
                    
                    VStack(spacing: 30) {
                        if !apps.isEmpty {
                            Text(apps[currentIndex].type.name)
                                .font(.headline)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial))
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(currentColor, lineWidth: 2))
                                .animation(.spring(), value: scrollSelection)
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 15) {
                                ForEach(apps) { app in
                                    if openedApp?.id == app.id {
                                        Color.clear.frame(width: 280, height: 420)
                                    } else {
                                        Button(action: {
                                            if app.isReady {
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) { openedApp = app }
                                                withAnimation(.easeIn(duration: 0.3).delay(0.2)) { showAppContent = true }
                                            } else {
                                                showingNotReadyAlert = true
                                            }
                                        }) {
                                            PreviewCard(app: app)
                                                .matchedGeometryEffect(id: app.id, in: animation)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .scrollTransition(topLeading: .interactive, bottomTrailing: .interactive, axis: .horizontal) { content, phase in
                                            content
                                                .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                                .rotation3DEffect(.degrees(phase.value * -20), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                                                .opacity(phase.isIdentity ? 1.0 : 0.6)
                                                .offset(y: phase.isIdentity ? 0 : 20)
                                        }
                                    }
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .contentMargins(.horizontal, 40, for: .scrollContent)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $scrollSelection)
                        
                        HStack(spacing: 8) {
                            ForEach(apps.indices, id: \.self) { index in
                                Circle()
                                    .fill(scrollSelection == apps[index].id ? apps[index].type.color : Color.gray.opacity(0.4))
                                    .frame(width: scrollSelection == apps[index].id ? 12 : 8, height: 8)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: scrollSelection)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { resetNotificationTimer(); showingTimerAlert = true }) {
                            Image(systemName: "bell.badge.fill").foregroundColor(.primary)
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingReorderSheet = true }) {
                            Image(systemName: "list.bullet").foregroundColor(.primary)
                        }
                    }
                }
                .sheet(isPresented: $showingReorderSheet) {
                    // Передаем текущий массив в редактор сортировки
                    ReorderView(localApps: apps)
                }
                .alert("Таймер сброшен", isPresented: $showingTimerAlert) { Button("ОК", role: .cancel) { } } message: { Text("Уведомление придет через 5 дней.") }
                .alert("Приложение в разработке", isPresented: $showingNotReadyAlert) { Button("Понятно", role: .cancel) { } } message: { Text("Этот модуль еще не готов.") }
                .onAppear {
                    setupInitialDataIfNeeded()
                    if scrollSelection == nil { scrollSelection = apps.first?.id }
                    requestNotificationPermission()
                }
            }
            .tint(.primary)
            
            // ВЕРХНИЙ СЛОЙ (Открытое приложение "Mortal Kombat" style)
            if let app = openedApp {
                ZStack {
                    app.type.color
                        .matchedGeometryEffect(id: app.id, in: animation)
                        .ignoresSafeArea()
                    
                    if showAppContent {
                        app.type.destination()
                            .transition(.opacity)
                            .environment(\.exitPortfolioApp) {
                                withAnimation(.easeOut(duration: 0.1)) { showAppContent = false }
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.1)) { openedApp = nil }
                            }
                    }
                }
                .zIndex(2)
            }
        }
    }
    
    // MARK: - Логика первого запуска (Заполнение базы данных)
    private func setupInitialDataIfNeeded() {
        if apps.isEmpty {
            let initialApps = [
                AppCardModel(type: .work, order: 0, isReady: true),
                AppCardModel(type: .study, order: 1, isReady: false),
                AppCardModel(type: .finance, order: 2, isReady: false),
                AppCardModel(type: .ships, order: 3, isReady: false),
                AppCardModel(type: .esp, order: 4, isReady: false),
                AppCardModel(type: .assistant, order: 5, isReady: false)
            ]
            for app in initialApps {
                context.insert(app)
            }
        }
    }
    
    // Уведомления
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    func resetNotificationTimer() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Пора обновить приложение!"
        content.body = "Прошло 5 дней. Пересобери проект в Xcode."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 432_000, repeats: false)
        center.add(UNNotificationRequest(identifier: "UpdateReminder", content: content, trigger: trigger))
    }
}

// MARK: - 5. Экран сортировки (С сохранением в SwiftData)
struct ReorderView: View {
    @Environment(\.modelContext) private var context
    @State var localApps: [AppCardModel] // Локальная копия для сортировки
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(localApps) { app in
                    HStack {
                        Circle().fill(app.type.color).frame(width: 15, height: 15)
                        Text(app.type.name)
                        Spacer()
                        if !app.isReady { Text("В разработке").font(.caption).foregroundColor(.gray) }
                    }
                }
                .onMove { indices, newOffset in
                    // Двигаем элементы в локальном массиве
                    localApps.move(fromOffsets: indices, toOffset: newOffset)
                    // Обновляем параметр order для каждого элемента
                    for (index, app) in localApps.enumerated() {
                        app.order = index
                    }
                    // SwiftData автоматически сохранит эти изменения!
                }
            }
            .navigationTitle("Порядок").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } }
                ToolbarItem(placement: .topBarLeading) { EditButton() }
            }
        }
    }
}

// Компонент карточки превью
struct PreviewCard: View {
    let app: AppCardModel
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(LinearGradient(colors: [app.type.color.opacity(0.8), app.type.color], startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: 280, height: 420)
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                    Text(app.isReady ? "Открыть" : "В разработке")
                        .font(.subheadline).bold()
                        .foregroundColor(app.isReady ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            )
            .opacity(app.isReady ? 1.0 : 0.85)
            .shadow(color: app.type.color.opacity(0.4), radius: 15, x: 0, y: 10)
    }
}
