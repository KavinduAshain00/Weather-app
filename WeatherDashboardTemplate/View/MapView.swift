//
//  MapView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData
import MapKit

/// Interactive place map showing POIs as pins and a list of the corresponding places.
/// Tapping a pin centers/zooms the map; long-press opens a Google search for that POI.
struct MapView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 0) {
            // Map with annotations
            Map(coordinateRegion: $vm.mapRegion, annotationItems: vm.pois) { poi in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude)) {
                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title)
                            .foregroundColor(.red)
                            .shadow(radius: 2)
                            .onTapGesture {
                                // Zoom to ~500m region around pin
                                vm.focus(on: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude), zoom: 0.005)
                            }
                            .onLongPressGesture {
                                if let encoded = poi.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                                    openURL(url)
                                }
                            }

                        Text(poi.name)
                            .font(.caption2)
                            .fixedSize()
                    }
                }
            }
            .frame(height: 360)

            // List of POIs
            List(vm.pois, id: \ .id) { poi in
                HStack {
                    VStack(alignment: .leading) {
                        Text(poi.name)
                            .font(.body)
                        Text(String(format: "%.0f m away", 0))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    vm.focus(on: CLLocationCoordinate2D(latitude: poi.latitude, longitude: poi.longitude), zoom: 0.01)
                }
                .onLongPressGesture {
                    if let encoded = poi.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
                        openURL(url)
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}
#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    MapView()
        .environmentObject(vm)
}
