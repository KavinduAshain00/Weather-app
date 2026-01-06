//
//  WeatherDashboardTemplateApp.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData

@main
struct WeatherDashboardTemplateApp: App {

    // code to set configure ViewModel and ModelContainer
    @StateObject private var vm: MainAppViewModel
    private let container: ModelContainer
    init() {

        //  Define schema for all models
        let schema = Schema([Place.self, AnnotationModel.self])

        //  Persistent (on-disk) configuration
        let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
        self.container = try! ModelContainer(for: schema, configurations: [configuration])

        //  Create main model context
        let context = ModelContext(container)
        _vm = StateObject(wrappedValue: MainAppViewModel(context: context))


    }

    var body: some Scene {
        WindowGroup {
            NavBarView()
                .environmentObject(vm)
            //  Attach the same persistent container (not a new one!)
                .modelContainer(container)
        }
    }

}
