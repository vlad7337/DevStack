import SwiftUI

// MARK: - 3. Пример модуля (Sheduler Work)
struct WorkSchedulerView: View {
    @Environment(\.exitPortfolioApp) var exitApp
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Основной интерфейс графика работы")
                    .font(.title3).foregroundColor(.secondary)
            }
            .navigationTitle("Sheduler (Work)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill").foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    List {
                        Section("Система") {
                            Button(role: .destructive, action: { exitApp() }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Выйти на главный экран")
                                }
                            }
                        }
                    }
                    .navigationTitle("Настройки").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Закрыть") { showSettings = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
