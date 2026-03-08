import Foundation
import SwiftData

// Сама модель для базы данных SwiftData
@Model
final class AppCardModel {
    var id: UUID
    var type: AppModule // Сохраняем только тип (остальное генерируется автоматически)
    var order: Int      // Порядок сортировки
    var isReady: Bool   // Готово ли приложение

    init(type: AppModule, order: Int, isReady: Bool) {
        self.id = UUID()
        self.type = type
        self.order = order
        self.isReady = isReady
    }
}
