//  WeatherMapError.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 19/10/2025.
//
import Foundation

/// Application-specific errors surfaced to the UI. Each case provides a user-friendly `errorDescription` used for alerts.
enum WeatherMapError: Error, LocalizedError, Identifiable {
    case invalidURL(String)
    case networkError(Error)
    case decodingError(Error)
    case geocodingFailed(String)
    case invalidResponse(statusCode: Int)
    case missingData(message: String)
    case info(String)
    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .invalidURL(let urlString):
            return "Configuration Error: The URL is invalid or malformed: \(urlString)"
        case .networkError(let error):
            return "A network connection error occurred: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to parse data from the server: \(error.localizedDescription)"
        case .geocodingFailed(let location):
            return "Could not find coordinates for the location: \(location). Please try another name."
        case .invalidResponse(let code):
            return "The server returned an error code: \(code). Data is unavailable."
        case .missingData(let message):
            return "Missing or invalid data: \(message)"
        case .info(let message):
            return message
        }
    }
}
