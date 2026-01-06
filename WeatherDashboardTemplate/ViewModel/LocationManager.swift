//
//  LocationManager.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation
import CoreLocation
@preconcurrency import MapKit


@MainActor
/// Utility that wraps CoreLocation and MapKit functionality for the app.
/// Provides async/await-friendly methods for geocoding, reverse-geocoding and POI discovery.
final class LocationManager {

    /// Geocodes a human-readable address into coordinates and a friendly locality name.
    /// - Parameter address: User input location string (e.g., "Paris").
    /// - Returns: A tuple `(name, lat, lon)` where `name` is the best-effort friendly placemark name.
    /// - Throws: `WeatherMapError.geocodingFailed` if the address cannot be resolved.
    func geocodeAddress(_ address: String) async throws -> (name: String, lat: Double, lon: Double) {
        let geocoder = CLGeocoder()

        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: WeatherMapError.geocodingFailed(error.localizedDescription))
                    return
                }

                guard let placemark = placemarks?.first, let location = placemark.location else {
                    continuation.resume(throwing: WeatherMapError.geocodingFailed(address))
                    return
                }

                let name = placemark.locality ?? placemark.name ?? address
                continuation.resume(returning: (name: name, lat: location.coordinate.latitude, lon: location.coordinate.longitude))
            }
        }
    }

    func findPOIs(lat: Double, lon: Double, limit: Int = 5) async throws -> [AnnotationModel] {
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = MKCoordinateRegion(center: center, latitudinalMeters: 2000, longitudinalMeters: 2000)

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tourist attraction"
        request.region = region

        return try await withCheckedThrowingContinuation { continuation in
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let error = error {
                    continuation.resume(throwing: WeatherMapError.networkError(error))
                    return
                }

                let items = response?.mapItems ?? []
                var seen = Set<String>()
                var annotations: [AnnotationModel] = []

                for item in items {
                    guard let name = item.name else { continue }
                    let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    if !seen.insert(key).inserted { continue }

                    let coord = item.placemark.coordinate
                    annotations.append(AnnotationModel(name: name, latitude: coord.latitude, longitude: coord.longitude))
                    if annotations.count >= limit { break }
                }

                continuation.resume(returning: annotations)
            }
        }
    }


}
