//
//  MainAppViewModel.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData
import MapKit

@MainActor
/// Central application view model.
/// Responsible for coordinating user searches, geocoding, weather fetches, POI discovery and persistence.
/// Exposes published state used by the app's SwiftUI views (current weather, forecast, POIs, visited places, errors).
final class MainAppViewModel: ObservableObject {
    @Published var query = ""
    @Published var current: Current?
    @Published var forecast: [Daily] = []
    @Published var pois: [AnnotationModel] = []
    @Published var mapRegion = MKCoordinateRegion()
    @Published var visited: [Place] = []
    @Published var isLoading = false
    @Published var appError: WeatherMapError?
    @Published var activePlaceName: String = ""
    private let defaultPlaceName = "London"
    @Published var selectedTab: Int = 0

    // Persist a lightweight copy of saved places in UserDefaults for quick retrieval and demo purposes
    @AppStorage("saved_places") private var savedPlacesJSON: String = "[]"

    /// Create and use a WeatherService model (class) to manage fetching and decoding weather data
    private let weatherService = WeatherService()

    /// Create and use a LocationManager model (class) to manage address conversion and tourist places
    private let locationManager = LocationManager()

    /// Use a context to manage database operations
    private let context: ModelContext

    init(context: ModelContext) {
        // Initialize the ModelContext and attempt to fetch previously visited places from SwiftData, sorted by most recent use.
        // If no visited places exist (first launch), attempt to restore them from AppStorage; otherwise load the default location.
        self.context = context

        // Corrected FetchDescriptor to include sorting by 'lastUsedAt' in reverse order.
        if let results = try? context.fetch(
            FetchDescriptor<Place>(sortBy: [SortDescriptor(\Place.lastUsedAt, order: .reverse)])
        ) {
            self.visited = results
        }

        // If SwiftData has no saved places, try to restore from AppStorage (compatibility with older sessions)
        if visited.isEmpty {
            restorePlacesFromAppStorage()
        }

        // First launch: still empty → perform full London setup
        if visited.isEmpty {
            Task {
                await loadDefaultLocation()
            }
        } else if let mostRecent = visited.first {
            // Otherwise, load most recently used place
            Task {
                await loadLocation(fromPlace: mostRecent)
            }
        }
    }

    /// Triggered when the user submits a search.
    /// If `query` is empty the device current location is used; otherwise performs a named lookup.
    func submitQuery() {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // If user did not enter a location, fall back to the default place (no device location used)
        if city.isEmpty {
            Task {
                // Keep it simple: notify the user and load the default location (e.g., London)
                appError = .info("No location entered — loading default location")
                await loadDefaultLocation()
                query = ""
            }
            return
        }

        Task {
            do {
                try await loadLocation(byName: city)
                query = ""
            } catch {
                appError = .networkError(error)
            }
        }
    }
    /// Loads the canonical default location (London) and fetches its weather and POIs.
    /// Uses hardcoded coordinates to avoid relying on network geocoding for the fallback.
    func loadDefaultLocation() async {
        // Ensure UI is on the Now tab when loading default
        selectedTab = 0

        // Use canonical London coordinates to reliably fetch weather (avoid depending on geocoding for the fallback)
        let londonLat = 51.5073509
        let londonLon = -0.1277583

        // If we already saved London, load that stored place; otherwise create/load using coordinates
        if let existing = visited.first(where: { $0.name.lowercased() == defaultPlaceName.lowercased() }) {
            await loadLocation(fromPlace: existing)
            return
        }

        do {
            try await loadLocation(lat: londonLat, lon: londonLon, name: defaultPlaceName)
        } catch {
            appError = .networkError(error)
        }
    }

    func search() async throws {
        let city = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else { return }
        try await loadLocation(byName: city)
    }

    /// Validate weather before saving a new place; create POI children once.
    /// Attempts to load a location by name.
    /// - If the name already exists in SwiftData, loads cached POIs and refreshes weather.
    /// - Otherwise geocodes the name and performs a full fetch + persistence.
    /// - Throws: Propagates any `WeatherMapError` from geocoding or networking.
    func loadLocation(byName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let cleaned = byName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. If the place already exists in visited, load from storage
        if let existing = visited.first(where: { $0.name.lowercased() == cleaned.lowercased() }) {
            await loadLocation(fromPlace: existing)
            return
        }

        do {
            // 2. Geocode
            let (name, lat, lon) = try await locationManager.geocodeAddress(cleaned)

            try await loadLocation(lat: lat, lon: lon, name: name)
        } catch {
            if let wm = error as? WeatherMapError {
                switch wm {
                case .geocodingFailed(let location):
                    // Show a clear geocoding error to the user
                    appError = .geocodingFailed(location)
                default:
                    appError = wm
                }
            } else {
                appError = .networkError(error)
            }

            // Ensure UI switches back to 'Now' and then load London
            selectedTab = 0
            await loadDefaultLocation()
        }
    }

    /// Loads (and persists) a location given coordinates and a friendly name.
    /// Loads and persists a location given coordinates and a friendly name.
    /// This method validates weather, fetches POIs and inserts a new `Place` into SwiftData (unless a matching name exists).
    func loadLocation(lat: Double, lon: Double, name: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // If we already have a saved place with this name, prefer loading and refreshing it instead of creating a duplicate
        if let existing = visited.first(where: { $0.name.lowercased() == name.lowercased() }) {
            await loadLocation(fromPlace: existing)
            return
        }

        do {
            // Validate weather
            _ = try await weatherService.fetchWeather(lat: lat, lon: lon)

            // Get POIs
            let found = try await locationManager.findPOIs(lat: lat, lon: lon)

            // Persist place and its annotations
            let place = Place(name: name, latitude: lat, longitude: lon)
            for poi in found {
                let persisted = AnnotationModel(name: poi.name, latitude: poi.latitude, longitude: poi.longitude)
                persisted.place = place
                place.annotations.append(persisted)
                context.insert(persisted)
            }
            context.insert(place)

            // Keep the most recent at the front
            visited.removeAll(where: { $0.id == place.id })
            visited.insert(place, at: 0)

            // Update UI
            self.pois = place.annotations
            self.activePlaceName = place.name
            focus(on: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))

            // Persist a lightweight copy to AppStorage
            savePlacesToAppStorage()

            appError = .info("Saved location: \(place.name)")
            selectedTab = 0
        } catch {
            throw error
        }
    }

    /// Loads an already persisted `Place`, refreshes its weather and updates usage metadata.
    /// Updates AppStorage so lightweight place records remain in sync.
    func loadLocation(fromPlace place: Place) async{
        isLoading = true
        defer { isLoading = false }

        do {
            try await loadAll(for: place)
            // Update lastUsedAt
            place.lastUsedAt = .now
            // ensure place is at top
            visited.removeAll(where: { $0.id == place.id })
            visited.insert(place, at: 0)

            // Persist lightweight AppStorage copy (keeps AppStorage in sync with SwiftData)
            savePlacesToAppStorage()
            selectedTab = 0
        } catch {
            appError = .networkError(error)
        }
    }

    private func revertToDefaultWithAlert(message: String) async {
        // Do not overwrite an existing, more specific error alert
        if appError == nil {
            appError = .missingData(message: message)
        }
        // Switch back to the Now tab
        selectedTab = 0
        await loadDefaultLocation()
    }

    func focus(on coordinate: CLLocationCoordinate2D, zoom: Double = 0.02) {
        withAnimation {
            self.mapRegion = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))
        }
    }

    // MARK: - AppStorage helpers
    /// Lightweight serializable representation of a saved place used with `AppStorage`.
    private struct SimplePlace: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
    }

    /// Persists a compact JSON representation of saved places to `@AppStorage`.
    /// This is used for quick restore on first launch and demonstration environments.
    private func savePlacesToAppStorage() {
        let simple = visited.map { SimplePlace(name: $0.name, latitude: $0.latitude, longitude: $0.longitude) }
        if let data = try? JSONEncoder().encode(simple), let str = String(data: data, encoding: .utf8) {
            savedPlacesJSON = str
        }
    }

    /// Restores compact saved places from `AppStorage` into SwiftData so the app has a single source of truth.
    /// This method is intentionally conservative and used only when SwiftData has no records.
    private func restorePlacesFromAppStorage() {
        guard let data = savedPlacesJSON.data(using: .utf8) else { return }
        if let simple = try? JSONDecoder().decode([SimplePlace].self, from: data) {
            // Persist these into SwiftData so the app uses a single source of truth
            for sp in simple {
                let place = Place(name: sp.name, latitude: sp.latitude, longitude: sp.longitude)
                context.insert(place)
                visited.append(place)
            }
        }
    }

    /// Internal helper that refreshes weather and POIs for a `Place` and updates UI state.
    /// - Note: Always fetches fresh weather data from the API.
    private func loadAll(for place: Place) async throws {
        self.activePlaceName = place.name
        print("Loading data for: \(place.name)")

        // Refresh weather
        let weatherResp = try await weatherService.fetchWeather(lat: place.latitude, lon: place.longitude)
        // Store structured weather data
        self.current = weatherResp.current
        self.forecast = weatherResp.daily

        // Use cached POIs if present, otherwise fetch and persist
        if place.annotations.isEmpty {
            let found = try await locationManager.findPOIs(lat: place.latitude, lon: place.longitude)
            for poi in found {
                let persisted = AnnotationModel(name: poi.name, latitude: poi.latitude, longitude: poi.longitude)
                persisted.place = place
                place.annotations.append(persisted)
                context.insert(persisted)
            }
        }

        self.pois = place.annotations
        focus(on: CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude))

        // Ensure place is at top of visited
        visited.removeAll(where: { $0.id == place.id })
        visited.insert(place, at: 0)
    }

    /// Permanently deletes a stored `Place` from SwiftData and updates AppStorage.
    func delete(place: Place) {
        context.delete(place)
        visited.removeAll(where: { $0.id == place.id })
        // keep AppStorage in sync
        savePlacesToAppStorage()
    }

}
