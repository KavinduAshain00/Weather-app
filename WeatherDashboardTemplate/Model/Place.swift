//
//  Place.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//
// MARK:  Basic data models - edit them to create a relationship

import SwiftData
import CoreLocation

/// Persisted Place model representing a searched or saved location.
/// - Stores coordinates, a last-used timestamp and a relationship to nearby POIs (`AnnotationModel`).
@Model
final class Place {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var lastUsedAt: Date

    // Relationship to AnnotationModel (POIs)
    @Relationship var annotations: [AnnotationModel] = []

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.lastUsedAt = .now
    }
}

@Model
final class AnnotationModel: Identifiable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double

    // Inverse relationship back to Place
    @Relationship(inverse: \Place.annotations) var place: Place?

    init(name: String, latitude: Double, longitude: Double) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude

    }

}
