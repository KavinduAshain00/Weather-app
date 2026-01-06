//
//  VisitedPLacesView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData


/// Shows the list of stored places. Supports tap to load, long-press to open a Google search and swipe-to-delete.
struct VisitedPlacesView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @Environment(\.modelContext) private var context // Not used directly here
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                if vm.visited.isEmpty {
                    Text("No saved places yet. Search for a city and save it to get started.")
                        .foregroundStyle(.secondary)
                }

                ForEach(vm.visited) { place in
                    VStack(alignment: .leading) {
                        Text(place.name)
                            .font(.headline)
                        Text(String(format: "%.4f, %.4f", place.latitude, place.longitude))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await vm.loadLocation(fromPlace: place)
                        }
                    }
                    .onLongPressGesture {
                        if let encoded = place.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                            openURL(url)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet.sorted(by: >) {
                        let place = vm.visited[index]
                        vm.delete(place: place)
                    }
                }
            }
            .navigationTitle("Saved Places")
            .listStyle(.insetGrouped)
        }
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    VisitedPlacesView()
        .environmentObject(vm)
}
