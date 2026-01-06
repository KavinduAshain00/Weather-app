//
//  CurrentWeatherView.swift
//  WeatherDashboardTemplate
//
//  Created by girish lukka on 18/10/2025.
//

import SwiftUI
import SwiftData


/// Displays the current weather summary and friendly advice for the active place.
/// Shows temperature, condition, high/low, pressure and sunrise/sunset details.
struct CurrentWeatherView: View {
    @EnvironmentObject var vm: MainAppViewModel
    @State private var tempScale: CGFloat = 1.0
    @State private var adviceOpacity: Double = 0.0

    private var tempText: String {
        if let t = vm.current?.temp {
            return String(format: "%.0f°", t)
        }
        return "--"
    }

    private var conditionText: String {
        vm.current?.weather.first?.main ?? "Unknown"
    }

    private var advice: WeatherAdviceCategory {
        guard let t = vm.current?.temp, let desc = vm.current?.weather.first?.description else { return .unknown }
        return WeatherAdviceCategory.from(temp: t, description: desc)
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [advice.color.opacity(0.35), Color(.systemPink).opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Header: Location + Date
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(vm.activePlaceName.isEmpty ? "Unknown" : vm.activePlaceName)
                            .font(.largeTitle)
                            .bold()
                            .accessibilityLabel("Location")
                            .accessibilityValue(vm.activePlaceName)
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }

                // Main temperature and condition
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tempText)
                            .font(.system(size: 72))
                            .bold()
                            .scaleEffect(tempScale)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: tempScale)
                            .accessibilityLabel("Current temperature")
                            .accessibilityValue(tempText)

                        HStack(spacing: 12) {
                            if let high = vm.forecast.first?.temp.max {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up")
                                    Text(String(format: "%.0f°", high))
                                }
                                .font(.subheadline)
                                .accessibilityLabel("High")
                                .accessibilityValue(String(format: "%.0f°", high))
                            }

                            if let low = vm.forecast.first?.temp.min {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down")
                                    Text(String(format: "%.0f°", low))
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .accessibilityLabel("Low")
                                .accessibilityValue(String(format: "%.0f°", low))
                            }
                        }

                        Text(conditionText)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Condition")
                            .accessibilityValue(conditionText)
                    }

                    Spacer()

                    VStack {
                        Image(systemName: advice.icon)
                            .font(.system(size: 56))
                            .accessibilityHidden(true)
                        Text(vm.current?.weather.first?.main ?? "--")
                            .font(.subheadline)
                    }
                }

                // Details section — redesigned as a responsive two-column grid
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details")
                        .font(.headline)

                    let columns = [GridItem(.flexible()), GridItem(.flexible())]

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        // Pressure
                        HStack(spacing: 10) {
                            Image(systemName: "gauge")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pressure")
                                    .font(.subheadline)
                                Text(vm.current != nil ? "\(vm.current!.pressure) hPa" : "--")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Humidity
                        HStack(spacing: 10) {
                            Image(systemName: "humidity")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Humidity")
                                    .font(.subheadline)
                                Text(vm.current != nil ? "\(vm.current!.humidity)%" : "--")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Wind
                        HStack(spacing: 10) {
                            Image(systemName: "wind")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Wind")
                                    .font(.subheadline)
                                Text(vm.current != nil ? String(format: "%.1f m/s", vm.current!.windSpeed) : "--")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Sunrise
                        HStack(spacing: 10) {
                            Image(systemName: "sunrise.fill")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunrise")
                                    .font(.subheadline)
                                Text(vm.current != nil ? formatTime(vm.current!.sunrise) : "--")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        // Sunset
                        HStack(spacing: 10) {
                            Image(systemName: "sunset.fill")
                                .font(.title3)
                                .frame(width: 36, height: 36)
                                .foregroundStyle(.primary)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sunset")
                                    .font(.subheadline)
                                Text(vm.current != nil ? formatTime(vm.current!.sunset) : "--")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .animation(.default, value: vm.current?.temp)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Advice box — expanded to show full, multi-line advice text
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.title2)
                        .foregroundStyle(advice.color)
                        .frame(width: 44, height: 44)
                        .background(advice.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityHidden(true)

                    // Use a VStack so the text can wrap and occupy available width
                    VStack(alignment: .leading, spacing: 6) {
                        Text(advice.adviceText)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(nil)
                            .accessibilityLabel("Advice")
                            .accessibilityValue(advice.adviceText)

                        // Optional: show a small hint or source
                        Text("Weather advice")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 0)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .opacity(adviceOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.6)) {
                        adviceOpacity = 1.0
                    }
                }

                Spacer()
            }
            .padding()
            .blur(radius: vm.isLoading ? 3 : 0)
            .overlay {
                if vm.isLoading {
                    ProgressView()
                }
            }
        }
        .frame(height: 600)
        .cornerRadius(12)
        .padding()
        .onChange(of: vm.current?.temp) { _ in
            // subtle pulse when temperature updates
            tempScale = 1.08
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring()) { tempScale = 1.0 }
            }
        }
    }

    // MARK: - Helpers
    private func formatTime(_ unix: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(unix))
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }
}

#Preview {
    let vm = MainAppViewModel(context: ModelContext(ModelContainer.preview))
    CurrentWeatherView()
        .environmentObject(vm)
}
