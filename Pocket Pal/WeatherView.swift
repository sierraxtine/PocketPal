//
//  WeatherView.swift
//  Pocket Pal
//

import SwiftUI
import CoreLocation
import Combine

//////////////////////////////////////////////////////////
// MARK: Weather View
//////////////////////////////////////////////////////////

struct WeatherView: View {

    @StateObject private var weather = WeatherManager()
    @State private var selectedCity = "My Location"
    @State private var isRefreshing = false

    let cities:[String:(Double,Double)] = [
        "My Location":(0,0),
        "New York":(40.7128,-74.0060),
        "London":(51.5072,-0.1276),
        "Paris":(48.8566,2.3522),
        "Tokyo":(35.6895,139.6917),
        "Sydney":(-33.8688,151.2093),
        "Dubai":(25.2048,55.2708),
        "Singapore":(1.3521,103.8198)
    ]

    let cityOrder = [
        "My Location",
        "New York",
        "London",
        "Paris",
        "Tokyo",
        "Sydney",
        "Dubai",
        "Singapore"
    ]

    var body: some View {

        ZStack {

            AnimatedWeatherBackground(condition: weather.currentWeather?.condition ?? .clear)

            ScrollView {

                VStack(spacing:28) {

                    //////////////////////////////////////////////////////
                    // City Dropdown
                    //////////////////////////////////////////////////////

                    Menu {

                        ForEach(cityOrder, id:\.self) { city in

                            Button {

                                selectedCity = city
                                loadWeatherForCity(city)

                            } label: {
                                HStack {
                                    Text(city)
                                    if city == selectedCity {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }

                    } label: {

                        HStack(spacing: 8) {

                            Image(systemName: selectedCity == "My Location" ? "location.fill" : "mappin.circle.fill")
                                .foregroundColor(.white)
                                .font(.title3)

                            Text(selectedCity)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Image(systemName: "chevron.down")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.2))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                    }

                    //////////////////////////////////////////////////////
                    // Error Message
                    //////////////////////////////////////////////////////

                    if let error = weather.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(error)
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.3))
                        )
                        .padding(.horizontal)
                    }

                    //////////////////////////////////////////////////////
                    // Current Weather
                    //////////////////////////////////////////////////////

                    if let current = weather.currentWeather {

                        VStack(spacing: 12) {

                            // Weather Icon
                            Image(systemName: current.condition.icon)
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .symbolEffect(.bounce, value: current.temp)

                            // Temperature
                            Text("\(Int(current.temp))°")
                                .font(.system(size: 90, weight: .thin))
                                .foregroundColor(.white)

                            // Condition
                            Text(current.condition.description)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))

                            // Feels Like
                            Text("Feels Like \(Int(current.feelsLike))°")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))

                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 8)

                            // Weather Details Grid
                            HStack(spacing: 30) {

                                WeatherDetailView(
                                    icon: "wind",
                                    title: "Wind",
                                    value: "\(Int(current.wind)) mph"
                                )

                                WeatherDetailView(
                                    icon: "humidity.fill",
                                    title: "Humidity",
                                    value: "\(current.humidity)%"
                                )

                                WeatherDetailView(
                                    icon: "gauge.with.dots.needle.67percent",
                                    title: "Pressure",
                                    value: "\(current.pressure) mb"
                                )
                            }
                        }
                        .padding(.vertical, 20)

                        //////////////////////////////////////////////////////
                        // Hourly Forecast
                        //////////////////////////////////////////////////////

                        VStack(alignment: .leading, spacing: 16) {

                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white.opacity(0.9))
                                Text("Hourly Forecast")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {

                                HStack(spacing: 16) {

                                    ForEach(weather.hourly, id: \.time) { hour in

                                        VStack(spacing: 10) {

                                            Text(hour.time)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))

                                            Image(systemName: weatherIcon(for: hour.temp))
                                                .font(.title2)
                                                .foregroundColor(.white)

                                            Text("\(Int(hour.temp))°")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 70)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.white.opacity(0.15))
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)

                        //////////////////////////////////////////////////////
                        // Daily Forecast
                        //////////////////////////////////////////////////////

                        VStack(alignment: .leading, spacing: 16) {

                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white.opacity(0.9))
                                Text("7-Day Forecast")
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.horizontal)

                            VStack(spacing: 8) {

                                ForEach(weather.daily, id: \.day) { day in

                                    HStack(spacing: 16) {

                                        Text(day.day)
                                            .font(.body)
                                            .foregroundColor(.white)
                                            .frame(width: 60, alignment: .leading)

                                        Image(systemName: weatherIcon(for: day.max))
                                            .font(.title3)
                                            .foregroundColor(.white)
                                            .frame(width: 30)

                                        Spacer()

                                        // Temperature bar
                                        HStack(spacing: 8) {
                                            Text("\(Int(day.min))°")
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.6))
                                                .frame(width: 35, alignment: .trailing)

                                            // Temperature range indicator
                                            GeometryReader { geo in
                                                ZStack(alignment: .leading) {
                                                    Capsule()
                                                        .fill(Color.white.opacity(0.2))

                                                    Capsule()
                                                        .fill(
                                                            LinearGradient(
                                                                colors: [.blue, .orange, .red],
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        )
                                                        .frame(width: geo.size.width * tempRangeRatio(min: day.min, max: day.max))
                                                }
                                            }
                                            .frame(height: 4)
                                            .frame(width: 80)

                                            Text("\(Int(day.max))°")
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                                .frame(width: 35, alignment: .leading)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.1))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal)

                        //////////////////////////////////////////////////////
                        // Refresh Button
                        //////////////////////////////////////////////////////

                        Button {
                            refreshWeather()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                Text("Refresh")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        .disabled(isRefreshing)
                        .padding(.horizontal)

                    } else if weather.isLoading {

                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)

                            Text("Loading Weather")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                        .frame(height: 300)

                    } else {

                        VStack(spacing: 20) {
                            Image(systemName: "cloud.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))

                            Text("No Weather Data")
                                .foregroundColor(.white)
                                .font(.headline)

                            Button("Retry") {
                                loadWeatherForCity(selectedCity)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        .frame(height: 300)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 60)
            }
        }
        .navigationTitle("Weather")
        .onAppear {
            weather.requestLocationWeather()
        }
    }

    //////////////////////////////////////////////////////
    // Helper Functions
    //////////////////////////////////////////////////////

    func loadWeatherForCity(_ city: String) {
        if city == "My Location" {
            weather.requestLocationWeather()
        } else if let coords = cities[city] {
            Task {
                await weather.fetchWeather(lat: coords.0, lon: coords.1)
            }
        }
    }

    func refreshWeather() {
        isRefreshing = true

        withAnimation(.linear(duration: 0.5)) {
            // Animation handled by rotationEffect
        }

        loadWeatherForCity(selectedCity)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isRefreshing = false
        }
    }

    func weatherIcon(for temp: Double) -> String {
        switch temp {
        case ..<32:
            return "snowflake"
        case 32..<50:
            return "cloud.fill"
        case 50..<70:
            return "cloud.sun.fill"
        case 70..<85:
            return "sun.max.fill"
        default:
            return "sun.max.fill"
        }
    }

    func tempRangeRatio(min: Double, max: Double) -> CGFloat {
        let range = max - min
        return CGFloat(Swift.min(range / 40.0, 1.0)) // Normalize to a reasonable range
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Detail View Component
//////////////////////////////////////////////////////////

struct WeatherDetailView: View {

    let icon: String
    let title: String
    let value: String

    var body: some View {

        VStack(spacing: 8) {

            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))

            Text(value)
                .font(.headline)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Animated Weather Background
//////////////////////////////////////////////////////////

struct AnimatedWeatherBackground: View {

    let condition: WeatherCondition

    var body: some View {

        // Dynamic gradient based on weather condition
        LinearGradient(
            colors: condition.gradientColors,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Condition Enum
//////////////////////////////////////////////////////////

enum WeatherCondition {
    case clear
    case partlyCloudy
    case cloudy
    case rainy
    case snowy
    case stormy

    var description: String {
        switch self {
        case .clear: return "Clear Sky"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rainy: return "Rainy"
        case .snowy: return "Snowy"
        case .stormy: return "Stormy"
        }
    }

    var icon: String {
        switch self {
        case .clear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .snowy: return "snowflake"
        case .stormy: return "cloud.bolt.fill"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .clear:
            return [Color.blue.opacity(0.8), Color.cyan.opacity(0.6), Color.orange.opacity(0.3)]
        case .partlyCloudy:
            return [Color.blue.opacity(0.7), Color.gray.opacity(0.4), Color.blue.opacity(0.3)]
        case .cloudy:
            return [Color.gray.opacity(0.8), Color.gray.opacity(0.5), Color.black.opacity(0.6)]
        case .rainy:
            return [Color.gray.opacity(0.9), Color.blue.opacity(0.4), Color.black.opacity(0.7)]
        case .snowy:
            return [Color.gray.opacity(0.6), Color.white.opacity(0.3), Color.blue.opacity(0.5)]
        case .stormy:
            return [Color.black.opacity(0.8), Color.purple.opacity(0.5), Color.black.opacity(0.9)]
        }
    }

    var particleColor: Color {
        switch self {
        case .clear, .partlyCloudy:
            return .white.opacity(0.15)
        case .cloudy:
            return .white.opacity(0.2)
        case .rainy:
            return .white.opacity(0.4)
        case .snowy:
            return .white.opacity(0.8)
        case .stormy:
            return .white.opacity(0.5)
        }
    }

    var particleSize: CGFloat {
        switch self {
        case .snowy: return 6
        case .rainy: return 3
        default: return 4
        }
    }

    var animationDuration: Double {
        switch self {
        case .rainy: return 2
        case .snowy: return 5
        case .stormy: return 1.5
        default: return 8
        }
    }

    static func from(temp: Double, wind: Double) -> WeatherCondition {
        if wind > 25 {
            return .stormy
        } else if temp < 32 {
            return .snowy
        } else if temp < 50 {
            return .cloudy
        } else if temp < 70 {
            return .partlyCloudy
        } else {
            return .clear
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Manager
//////////////////////////////////////////////////////////

@MainActor
class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let locationManager = CLLocationManager()

    @Published var currentWeather: CurrentWeather?
    @Published var hourly: [HourlyForecast] = []
    @Published var daily: [DailyForecast] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    //////////////////////////////////////////////////////
    // Location Request
    //////////////////////////////////////////////////////

    func requestLocationWeather() {
        isLoading = true
        errorMessage = nil
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else { return }

        Task {
            await fetchWeather(
                lat: location.coordinate.latitude,
                lon: location.coordinate.longitude
            )
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("Location error:", error)
        errorMessage = "Unable to get location. Please check permissions."
        isLoading = false
    }

    //////////////////////////////////////////////////////
    // Fetch Weather
    //////////////////////////////////////////////////////

    func fetchWeather(lat: Double, lon: Double) async {
        isLoading = true
        errorMessage = nil

        let urlString =
        "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true&hourly=temperature_2m,apparent_temperature,relativehumidity_2m&daily=temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&windspeed_unit=mph&timezone=auto"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            // Perform network request
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check response
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                errorMessage = "Server error. Please try again."
                isLoading = false
                return
            }

            // Decode
            let decoded = try JSONDecoder().decode(WeatherResponse.self, from: data)

            // Update UI on main actor
            await MainActor.run {
                let humidity = decoded.hourly.relativehumidity_2m.first ?? 50
                let pressure = 1013 // Simulated pressure

                let condition = WeatherCondition.from(
                    temp: decoded.current_weather.temperature,
                    wind: decoded.current_weather.windspeed
                )

                self.currentWeather = CurrentWeather(
                    temp: decoded.current_weather.temperature,
                    wind: decoded.current_weather.windspeed,
                    feelsLike: decoded.hourly.apparent_temperature.first ?? decoded.current_weather.temperature,
                    humidity: Int(humidity),
                    pressure: pressure,
                    condition: condition
                )

                self.hourly = zip(
                    decoded.hourly.time.prefix(24),
                    decoded.hourly.temperature_2m.prefix(24)
                )
                .map {
                    HourlyForecast(
                        time: self.formatHour($0.0),
                        temp: $0.1
                    )
                }

                self.daily = zip(
                    decoded.daily.time,
                    zip(decoded.daily.temperature_2m_max,
                        decoded.daily.temperature_2m_min)
                )
                .map {
                    DailyForecast(
                        day: self.formatDay($0.0),
                        max: $0.1.0,
                        min: $0.1.1
                    )
                }

                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            print("Weather fetch/decode error:", error)
            errorMessage = "Failed to load weather data"
            isLoading = false
        }
    }

    //////////////////////////////////////////////////////
    // Formatters
    //////////////////////////////////////////////////////

    func formatDay(_ string: String) -> String {

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"

        if let d = f.date(from: string) {
            f.dateFormat = "EEE"
            return f.string(from: d)
        }

        return string
    }

    func formatHour(_ string: String) -> String {

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"

        if let d = f.date(from: string) {
            f.dateFormat = "ha"
            return f.string(from: d)
        }

        return "--"
    }
}

//////////////////////////////////////////////////////////
// MARK: Models
//////////////////////////////////////////////////////////

struct CurrentWeather {
    let temp: Double
    let wind: Double
    let feelsLike: Double
    let humidity: Int
    let pressure: Int
    let condition: WeatherCondition
}

struct HourlyForecast {
    let time: String
    let temp: Double
}

struct DailyForecast {
    let day: String
    let max: Double
    let min: Double
}

struct WeatherResponse: Decodable {

    struct Current: Decodable {
        let temperature: Double
        let windspeed: Double
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature_2m: [Double]
        let apparent_temperature: [Double]
        let relativehumidity_2m: [Double]
    }

    struct Daily: Decodable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }

    let current_weather: Current
    let hourly: Hourly
    let daily: Daily
}

//////////////////////////////////////////////////////////
// MARK: Preview
//////////////////////////////////////////////////////////

#Preview {
    NavigationStack{
        WeatherView()
    }
}

