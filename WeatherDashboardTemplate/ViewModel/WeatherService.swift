//
//  WeatherService.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import Foundation
@MainActor
/// Service responsible for communicating with the OpenWeather One Call 3.0 API.
/// Encapsulates request construction, retry/backoff logic and maps errors into `WeatherMapError`.
final class WeatherService {
    /// Your OpenWeather API key. For production, inject this from a secure configuration source.
    private let apiKey = "a555f1bc49285b91e532bc56614b1954"

    /// Fetches weather for the provided coordinates using the OpenWeather One Call 3.0 API.
    func fetchWeather(lat: Double, lon: Double, exclude: String = "minutely,hourly,alerts", units: String = "metric", retries: Int = 2) async throws -> WeatherResponse {
        // Build URL using a concise URL string (safe for these simple query values)
        let urlString = "https://api.openweathermap.org/data/3.0/onecall?lat=\(lat)&lon=\(lon)&exclude=\(exclude)&units=\(units)&appid=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw WeatherMapError.invalidURL(urlString)
        }

        // Simple retry/backoff strategy for transient network errors and 5xx responses
        var attempt = 0
        let maxAttempts = max(1, retries + 1)
        var lastError: Error?

        while attempt < maxAttempts {
            do {
                var request = URLRequest(url: url)
                request.timeoutInterval = 15

                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw WeatherMapError.invalidResponse(statusCode: -1)
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    throw WeatherMapError.invalidResponse(statusCode: httpResponse.statusCode)
                }

                let decoder = JSONDecoder()
                // The model uses unix timestamps as Ints, so default decoding is fine
                let weather = try decoder.decode(WeatherResponse.self, from: data)

                return weather
            } catch let wmError as WeatherMapError {
                // Retry on 5xx server errors
                if case .invalidResponse(let code) = wmError, (500...599).contains(code), attempt < maxAttempts - 1 {
                    let delay = UInt64(0.5 * pow(2.0, Double(attempt)) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    attempt += 1
                    lastError = wmError
                    continue
                }
                throw wmError
            } catch let decodingError as DecodingError {
                throw WeatherMapError.decodingError(decodingError)
            } catch {
                // Network or other errors - retry a couple of times
                lastError = error
                if attempt < maxAttempts - 1 {
                    let delay = UInt64(0.5 * pow(2.0, Double(attempt)) * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delay)
                    attempt += 1
                    continue
                }
                throw WeatherMapError.networkError(error)
            }
        }

        throw WeatherMapError.missingData(message: "Unable to fetch weather data: \(lastError?.localizedDescription ?? "unknown error")")
    }
}
