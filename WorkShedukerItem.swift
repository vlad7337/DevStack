import Foundation
import SwiftData

@Model
final class Shift: Identifiable {
    @Attribute(.unique) var id: UUID
    
    // Дата "начала смены" (ключевая дата)
    var date: Date
    
    // Полные интервалы
    var startTime: Date?
    var endTime: Date?
    
    // Первый обед
    var breakStart: Date?
    var breakEnd: Date?
    
    // Второй обед
    var secondBreakStart: Date?
    var secondBreakEnd: Date?
    
    // Собрание / планёрка
    var meetingTime: Date?
    
    // Дата конца смены (новое поле, для ночных смен)
    var endDate: Date?
    
    init(
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        breakStart: Date? = nil,
        breakEnd: Date? = nil,
        secondBreakStart: Date? = nil,
        secondBreakEnd: Date? = nil,
        meetingTime: Date? = nil,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakStart = breakStart
        self.breakEnd = breakEnd
        self.secondBreakStart = secondBreakStart
        self.secondBreakEnd = secondBreakEnd
        self.meetingTime = meetingTime
        self.endDate = endDate
    }
}


@Model
final class Reminder {
    var clientId: String
    var title: String
    var link: String
    var date: Date
    
    init(clientId: String ,title: String, date: Date, link: String) {
        self.clientId = clientId
        self.title = title
        self.date = date
        self.link = link
    }
}

@Model
final class PartnerShift: Identifiable {
    @Attribute(.unique) var id: UUID
    
    var date: Date
    var endDate: Date? // 🔹 поддержка ночных смен
    
    var startTime: Date?
    var endTime: Date?
    
    // Один обед
    var breakStart: Date?
    var breakEnd: Date?
    
    init(
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        breakStart: Date? = nil,
        breakEnd: Date? = nil,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.breakStart = breakStart
        self.breakEnd = breakEnd
        self.endDate = endDate
    }
}


@Model
final class ShiftTemplate: Identifiable {
    enum Owner: String, Codable, CaseIterable {
        case me = "Мои"
        case partner = "Дарʼї"
    }

    @Attribute(.unique) var id: UUID = UUID()
    
    var name: String
    var startTime: Date
    var endTime: Date
    var ownerRaw: String
    
    // Новый атрибут для ночных смен (может пересекать даты)
    var isCrossDay: Bool = false
    
    var owner: Owner {
        get { Owner(rawValue: ownerRaw) ?? .me }
        set { ownerRaw = newValue.rawValue }
    }

    init(
        name: String,
        startTime: Date,
        endTime: Date,
        owner: Owner,
        isCrossDay: Bool = false
    ) {
        self.name = name
        self.startTime = startTime
        self.endTime = endTime
        self.ownerRaw = owner.rawValue
        self.isCrossDay = isCrossDay
    }
}

@Model
final class DailyNotificationRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var body: String
    var triggerTime: Date
    var category: String     // "shift", "lesson", "system"
    var relatedId: String?   // ID смены или пары

    init(date: Date, title: String, body: String, triggerTime: Date, category: String, relatedId: String? = nil) {
        self.id = UUID()
        self.date = date
        self.title = title
        self.body = body
        self.triggerTime = triggerTime
        self.category = category
        self.relatedId = relatedId
    }
}
