//
//  NavBarView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 19/10/2025.
//

import SwiftUI
import SwiftData

struct NavBarView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // 🔍 Search Bar (liquid-glass style)
            HStack(spacing: 10) {
                HStack(spacing: 10) {

                    TextField("Change Location", text: $vm.query)
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { vm.submitQuery() }
                        .accessibilityLabel("Search or change location")

                    if !vm.query.isEmpty {
                        Button(action: { vm.query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)

                Button {
                    vm.submitQuery()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .padding(.horizontal)

            // 🌤 Tabs
            TabView(selection: $vm.selectedTab) {
                CurrentWeatherView()
                    .tabItem { Label("Now", systemImage: "sun.max.fill") }
                    .tag(0)

                ForecastView()
                    .tabItem { Label("Forecast", systemImage: "calendar") }
                    .tag(1)

                MapView()
                    .tabItem { Label("Map", systemImage: "map") }
                    .tag(2)

                VisitedPlacesView()
                    .tabItem { Label("Saved", systemImage: "globe") }
                    .tag(3)
            }
            .accentColor(.blue)
        }
        .frame(maxWidth: .infinity,maxHeight: .infinity, alignment: .top)

        .overlay {
            if vm.isLoading {
                ProgressView("Loading…")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .alert(item: $vm.appError) { error in
            let titleText: String
            if case .info = error {
                titleText = "Info"
            } else if case .geocodingFailed = error {
                titleText = "Location Error"
            } else {
                titleText = "Error"
            }

            return Alert(
                title: Text(titleText),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}



#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    NavBarView()
        .environmentObject(vm)
}

