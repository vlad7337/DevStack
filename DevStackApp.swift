//
//  DevStackApp.swift
//  DevStack
//
//  Created by Vladislav on 09.03.2026.
//

import SwiftUI
import SwiftData

@main
struct DevStackApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            AppCardModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
