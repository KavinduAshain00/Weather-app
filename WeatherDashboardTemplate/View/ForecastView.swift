//
//  ForecastView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import Charts
import SwiftData


import SwiftUI
import Charts   // Include if you plan to show a chart later

// MARK: - Temperature Category
/// Example of how to categorize temperatures for display.
/// Add more cases or adjust logic as needed.
enum TempCategory: String, CaseIterable {
    case cold = "Cold"   // Example category

    /// Choose a color to represent this category.
    var color: Color {
        switch self {
        case .cold:
            return .blue
            // TODO: add more cases (e.g., .cool, .warm, .hot) with colors as needed
        }
    }

    /// Convert a Celsius temperature into a category.
    static func from(tempC: Double) -> TempCategory {
        if tempC <= 0 {
            return .cold
        }
        // TODO: add more logic for other ranges (cool, warm, hot)
        return .cold
    }
}

// MARK: - Temperature Data Model
/// A single temperature reading for the chart or list.
private struct TempData: Identifiable {
    let id = UUID()
    let time: Date          // e.g., forecast date
    let type: String        // e.g., "High" or "Low"
    let value: Double       // numeric value
    let category: TempCategory
}

// MARK: - Forecast View
/// Stubbed Forecast View that includes an image placeholder to show
/// what the final view will look like. Replace the image once real data and charts are added.
/// Displays an 8-day forecast chart (high/low bars) and a textual list of daily summaries.
struct ForecastView: View {
    @EnvironmentObject var vm: MainAppViewModel

    private var days: [Daily] {
        Array(vm.forecast.prefix(8))
    }

    private func dateFor(_ dt: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }

    var body: some View {
        VStack(spacing: 12) {
            // Chart: high/low for next 8 days
            Chart {
                ForEach(days.indices, id: \.self) { idx in
                    let day = days[idx]
                    let date = dateFor(day.dt)

                    // High
                    BarMark(
                        x: .value("Day", date, unit: .day),
                        y: .value("High", day.temp.max)
                    )
                    .foregroundStyle(Color.orange.gradient)
                    .annotation(position: .top) {
                        Text(String(format: "%.0f°", day.temp.max))
                            .font(.caption2)
                    }

                    // Low
                    BarMark(
                        x: .value("Day", date, unit: .day),
                        y: .value("Low", day.temp.min)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .annotation(position: .bottom) {
                        Text(String(format: "%.0f°", day.temp.min))
                            .font(.caption2)
                    }
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 1)) { value in
                    AxisValueLabel() {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding(.horizontal)

            // List of days with textual forecast
            List(days, id: \ .dt) { day in
                HStack {
                    Text(dateFor(day.dt), format: .dateTime.weekday(.wide))
                        .font(.subheadline)
                        .frame(width: 110, alignment: .leading)
                    Spacer()
                    Text(day.weather.first?.main ?? "--")
                        .font(.subheadline)
                    Spacer()
                    Text(String(format: "H: %.0f°", day.temp.max))
                        .font(.subheadline)
                    Text(String(format: "L: %.0f°", day.temp.min))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .listStyle(.plain)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [.indigo.opacity(0.1), .blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .padding()
        .navigationTitle("Forecast")
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    ForecastView()
        .environmentObject(vm)
}
