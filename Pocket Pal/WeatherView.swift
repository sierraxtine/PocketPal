//
//  WeatherView.swift
//  Pocket Pal
//

import SwiftUI
import CoreLocation
import Combine
import MapKit

//////////////////////////////////////////////////////////
// MARK: Weather View
//////////////////////////////////////////////////////////

struct WeatherView: View {

    @StateObject private var weather = WeatherManager()
    @State private var selectedCity = "My Location"
    @State private var isRefreshing = false
    @State private var useCelsius = false
    @State private var showingCitySearch = false
    @State private var searchText = ""
    @State private var showingWeatherMap = false

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
            
            // Animated weather particles
            WeatherParticlesView(condition: weather.currentWeather?.condition ?? .clear)

            ScrollView {

                VStack(spacing:28) {

                    //////////////////////////////////////////////////////
                    // City Dropdown
                    //////////////////////////////////////////////////////

                    HStack {
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
                                    .fill(.ultraThinMaterial.opacity(0.8))
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                            )
                        }
                        
                        Spacer()
                        
                        // Unit Toggle
                        Button {
                            withAnimation(.spring()) {
                                useCelsius.toggle()
                            }
                        } label: {
                            Text(useCelsius ? "°C" : "°F")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.8))
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                        }
                    }
                    .padding(.horizontal)

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
                            Text("\(formatTemp(current.temp))°")
                                .font(.system(size: 90, weight: .thin))
                                .foregroundColor(.white)
                                .contentTransition(.numericText())

                            // Condition
                            Text(current.condition.description)
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))

                            // Feels Like
                            Text("Feels Like \(formatTemp(current.feelsLike))°")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // High/Low for the day
                            if let todayForecast = weather.daily.first {
                                Text("H:\(formatTemp(todayForecast.max))° L:\(formatTemp(todayForecast.min))°")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Divider()
                                .background(Color.white.opacity(0.3))
                                .padding(.horizontal, 40)
                                .padding(.vertical, 8)

                            // Weather Details Grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {

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
                                
                                WeatherDetailView(
                                    icon: "sun.max.fill",
                                    title: "UV Index",
                                    value: "\(current.uvIndex)"
                                )
                                
                                WeatherDetailView(
                                    icon: "eye.fill",
                                    title: "Visibility",
                                    value: "\(current.visibility) mi"
                                )
                                
                                WeatherDetailView(
                                    icon: "cloud.rain.fill",
                                    title: "Precipitation",
                                    value: "\(current.precipitation)%"
                                )
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 20)
                        
                        //////////////////////////////////////////////////////
                        // Sunrise/Sunset Card
                        //////////////////////////////////////////////////////
                        
                        if let sunrise = weather.currentWeather?.sunrise,
                           let sunset = weather.currentWeather?.sunset {
                            SunTimesCard(sunrise: sunrise, sunset: sunset)
                                .padding(.horizontal)
                        }
                        
                        //////////////////////////////////////////////////////
                        // Weather Alerts
                        //////////////////////////////////////////////////////
                        
                        if !weather.alerts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(weather.alerts, id: \.title) { alert in
                                    WeatherAlertCard(alert: alert)
                                }
                            }
                            .padding(.horizontal)
                        }

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
                                            
                                            // Precipitation probability
                                            if hour.precipitation > 0 {
                                                HStack(spacing: 2) {
                                                    Image(systemName: "drop.fill")
                                                        .font(.caption2)
                                                        .foregroundColor(.blue)
                                                    Text("\(hour.precipitation)%")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.8))
                                                }
                                            }

                                            Text("\(formatTemp(hour.temp))°")
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
                                            Text("\(formatTemp(day.min))°")
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

                                            Text("\(formatTemp(day.max))°")
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

                        HStack(spacing: 12) {
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
                                        .fill(.ultraThinMaterial.opacity(0.6))
                                )
                            }
                            .disabled(isRefreshing)
                            
                            Button {
                                showingWeatherMap = true
                            } label: {
                                HStack {
                                    Image(systemName: "map.fill")
                                    Text("Map")
                                }
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial.opacity(0.6))
                                )
                            }
                        }
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
        .sheet(isPresented: $showingWeatherMap) {
            WeatherMapView(
                latitude: weather.currentLocation?.coordinate.latitude ?? 0,
                longitude: weather.currentLocation?.coordinate.longitude ?? 0
            )
        }
        .onAppear {
            weather.requestLocationWeather()
        }
    }

    //////////////////////////////////////////////////////
    // Helper Functions
    //////////////////////////////////////////////////////
    
    func formatTemp(_ temp: Double) -> String {
        let convertedTemp = useCelsius ? (temp - 32) * 5/9 : temp
        return "\(Int(convertedTemp.rounded()))"
    }

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
// MARK: Weather Particles View
//////////////////////////////////////////////////////////

struct WeatherParticlesView: View {
    let condition: WeatherCondition
    @State private var particlePhase = 0.0
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                switch condition {
                case .rainy, .stormy:
                    drawRain(context: context, size: size, time: now)
                case .snowy:
                    drawSnow(context: context, size: size, time: now)
                case .cloudy, .partlyCloudy:
                    drawClouds(context: context, size: size, time: now)
                default:
                    break
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    func drawRain(context: GraphicsContext, size: CGSize, time: Double) {
        let dropCount = condition == .stormy ? 150 : 80
        
        for i in 0..<dropCount {
            let seed = Double(i) * 0.123
            let x = (seed * size.width).truncatingRemainder(dividingBy: size.width)
            let speed = condition == .stormy ? 800.0 : 500.0
            let y = (time * speed + seed * 1000).truncatingRemainder(dividingBy: size.height + 100) - 100
            
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x, y: y + 20))
            
            context.stroke(
                path,
                with: .color(.white.opacity(0.4)),
                lineWidth: 1.5
            )
        }
    }
    
    func drawSnow(context: GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<60 {
            let seed = Double(i) * 0.456
            let x = (seed * size.width + sin(time + seed * 10) * 30).truncatingRemainder(dividingBy: size.width)
            let y = (time * 100 + seed * 1000).truncatingRemainder(dividingBy: size.height + 100) - 100
            
            let snowflake = Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
            
            context.fill(
                snowflake,
                with: .color(.white.opacity(0.8))
            )
        }
    }
    
    func drawClouds(context: GraphicsContext, size: CGSize, time: Double) {
        for i in 0..<5 {
            let seed = Double(i) * 0.789
            let x = (time * 20 + seed * size.width).truncatingRemainder(dividingBy: size.width + 200) - 100
            let y = seed * size.height * 0.3 + 50
            
            let cloud = Path(ellipseIn: CGRect(x: x, y: y, width: 100, height: 40))
            
            context.fill(
                cloud,
                with: .color(.white.opacity(0.15))
            )
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Sun Times Card
//////////////////////////////////////////////////////////

struct SunTimesCard: View {
    let sunrise: Date
    let sunset: Date
    
    @State private var currentProgress: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sun.horizon.fill")
                    .foregroundColor(.white.opacity(0.9))
                Text("Sun Schedule")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.headline)
                Spacer()
            }
            
            ZStack {
                // Arc background
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(height: 120)
                    .rotationEffect(.degrees(180))
                
                // Sun progress arc
                Circle()
                    .trim(from: 0, to: currentProgress * 0.5)
                    .stroke(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(height: 120)
                    .rotationEffect(.degrees(180))
                
                // Sun indicator
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 16, height: 16)
                    .offset(x: cos(.pi - currentProgress * .pi) * 60,
                           y: sin(.pi - currentProgress * .pi) * 60)
                    .shadow(color: .yellow.opacity(0.5), radius: 8)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "sunrise.fill")
                            .foregroundColor(.orange)
                        Text(sunrise, style: .time)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "sunset.fill")
                            .foregroundColor(.orange)
                        Text(sunset, style: .time)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
                .offset(y: 45)
            }
            .frame(height: 100)
            .padding(.horizontal)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            calculateSunProgress()
        }
    }
    
    func calculateSunProgress() {
        let now = Date()
        let totalDaylight = sunset.timeIntervalSince(sunrise)
        
        if now < sunrise {
            currentProgress = 0
        } else if now > sunset {
            currentProgress = 1
        } else {
            let elapsed = now.timeIntervalSince(sunrise)
            currentProgress = elapsed / totalDaylight
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Alert Card
//////////////////////////////////////////////////////////

struct WeatherAlertCard: View {
    let alert: WeatherAlert
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.severity == .severe ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
                .font(.title2)
                .foregroundColor(alert.severity == .severe ? .red : .orange)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(alert.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(alert.description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(alert.severity == .severe ? Color.red.opacity(0.3) : Color.orange.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Map View
//////////////////////////////////////////////////////////

struct WeatherMapView: View {
    @Environment(\.dismiss) private var dismiss
    let latitude: Double
    let longitude: Double
    
    @State private var isStandardMapStyle = true
    @State private var cameraPosition: MapCameraPosition
    @State private var selectedOverlay: WeatherOverlay = .temperature
    @State private var showingOverlayOptions = false
    @State private var showingNavigationOptions = false
    @State private var route: MKRoute?
    @State private var isCalculatingRoute = false
    
    private var mapStyle: MapStyle {
        isStandardMapStyle ? .standard : .hybrid
    }
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
            )
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map with weather location
                Map(position: $cameraPosition) {
                    // Current location marker
                    Annotation("Current Weather", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.3))
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Image(systemName: "cloud.sun.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 8)
                        }
                    }
                    
                    // Show route if available
                    if let route = route {
                        MapPolyline(route.polyline)
                            .stroke(.blue, lineWidth: 5)
                    }
                }
                .mapStyle(mapStyle)
                .ignoresSafeArea()
                
                // Overlay controls
                VStack {
                    // Info banner
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedOverlay.icon)
                                .font(.title3)
                                .foregroundColor(.cyan)
                            
                            Text(selectedOverlay.title)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button {
                                showingOverlayOptions.toggle()
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        
                        Text(selectedOverlay.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Color legend
                        if selectedOverlay.showsLegend {
                            HStack(spacing: 4) {
                                ForEach(selectedOverlay.legendColors, id: \.self) { color in
                                    Rectangle()
                                        .fill(color)
                                        .frame(height: 6)
                                }
                            }
                            .cornerRadius(3)
                            
                            HStack {
                                Text(selectedOverlay.legendMin)
                                    .font(.caption2)
                                Spacer()
                                Text(selectedOverlay.legendMax)
                                    .font(.caption2)
                            }
                            .foregroundColor(.white.opacity(0.6))
                        }
                        
                        // Route info if available
                        if let route = route {
                            Divider()
                                .background(Color.white.opacity(0.3))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.cyan)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(formatDistance(route.distance))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(formatDuration(route.expectedTravelTime))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial.opacity(0.8))
                            .shadow(color: .black.opacity(0.2), radius: 10)
                    )
                    .padding()
                    
                    Spacer()
                    
                    // Bottom controls
                    HStack(spacing: 12) {
                        // Map style toggle
                        Button {
                            withAnimation {
                                isStandardMapStyle.toggle()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: isStandardMapStyle ? "map" : "globe.americas.fill")
                                    .font(.system(size: 16))
                                Text(isStandardMapStyle ? "Standard" : "Satellite")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.ultraThinMaterial.opacity(0.8))
                            )
                        }
                        
                        Spacer()
                        
                        // Navigate button
                        Button {
                            showingNavigationOptions = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "location.north.fill")
                                    .font(.system(size: 16))
                                Text("Navigate")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(.cyan)
                                    .shadow(color: .cyan.opacity(0.5), radius: 8)
                            )
                        }
                        
                        // Recenter button
                        Button {
                            withAnimation {
                                cameraPosition = .region(
                                    MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
                                    )
                                )
                            }
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.8))
                                )
                        }
                    }
                    .padding()
                }
                
                // Loading indicator for route calculation
                if isCalculatingRoute {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.cyan)
                        Text("Calculating route...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial.opacity(0.9))
                    )
                }
            }
            .navigationTitle("Weather Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showingOverlayOptions) {
                WeatherOverlayPicker(selectedOverlay: $selectedOverlay)
                    .presentationDetents([.medium])
            }
            .confirmationDialog("Choose Navigation App", isPresented: $showingNavigationOptions) {
                Button("Apple Maps") {
                    openInAppleMaps()
                }
                
                Button("Show Route Preview") {
                    calculateRoute()
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get directions to this weather location")
            }
        }
    }
    
    // MARK: - Navigation Functions
    
    private func openInAppleMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Weather Location"
        
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    private func calculateRoute() {
        isCalculatingRoute = true
        
        Task {
            let destinationCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            // Create request for directions
            let request = MKDirections.Request()
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
            request.source = MKMapItem.forCurrentLocation()
            request.transportType = .automobile
            request.requestsAlternateRoutes = false
            
            let directions = MKDirections(request: request)
            
            do {
                let response = try await directions.calculate()
                
                await MainActor.run {
                    if let route = response.routes.first {
                        self.route = route
                        
                        // Adjust camera to show the route
                        let rect = route.polyline.boundingMapRect
                        let region = MKCoordinateRegion(rect)
                        
                        withAnimation {
                            cameraPosition = .region(region)
                        }
                    }
                    isCalculatingRoute = false
                }
            } catch {
                await MainActor.run {
                    print("Error calculating route: \(error)")
                    isCalculatingRoute = false
                }
            }
        }
    }
    
    private func formatDistance(_ meters: CLLocationDistance) -> String {
        let miles = meters / 1609.34
        if miles < 0.1 {
            return String(format: "%.0f ft", meters * 3.28084)
        } else {
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Overlay Enum
//////////////////////////////////////////////////////////

enum WeatherOverlay: String, CaseIterable, Identifiable {
    case temperature = "Temperature"
    case precipitation = "Precipitation"
    case wind = "Wind Speed"
    case clouds = "Cloud Cover"
    case pressure = "Pressure"
    case humidity = "Humidity"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .temperature: return "thermometer.medium"
        case .precipitation: return "cloud.rain.fill"
        case .wind: return "wind"
        case .clouds: return "cloud.fill"
        case .pressure: return "gauge.with.dots.needle.50percent"
        case .humidity: return "humidity.fill"
        }
    }
    
    var description: String {
        switch self {
        case .temperature: return "Current temperature across the region"
        case .precipitation: return "Rainfall and snow accumulation"
        case .wind: return "Wind speed and direction patterns"
        case .clouds: return "Cloud coverage percentage"
        case .pressure: return "Atmospheric pressure systems"
        case .humidity: return "Relative humidity levels"
        }
    }
    
    var showsLegend: Bool { true }
    
    var legendColors: [Color] {
        switch self {
        case .temperature:
            return [.blue, .cyan, .green, .yellow, .orange, .red]
        case .precipitation:
            return [.clear, .blue.opacity(0.3), .blue.opacity(0.6), .blue, .purple]
        case .wind:
            return [.white.opacity(0.2), .cyan.opacity(0.4), .cyan, .blue, .purple]
        case .clouds:
            return [.clear, .white.opacity(0.3), .white.opacity(0.6), .white, .gray]
        case .pressure:
            return [.purple, .blue, .cyan, .green, .yellow, .orange]
        case .humidity:
            return [.yellow.opacity(0.3), .green.opacity(0.5), .cyan, .blue]
        }
    }
    
    var legendMin: String {
        switch self {
        case .temperature: return "Cold"
        case .precipitation: return "None"
        case .wind: return "Calm"
        case .clouds: return "Clear"
        case .pressure: return "Low"
        case .humidity: return "Dry"
        }
    }
    
    var legendMax: String {
        switch self {
        case .temperature: return "Hot"
        case .precipitation: return "Heavy"
        case .wind: return "Strong"
        case .clouds: return "Overcast"
        case .pressure: return "High"
        case .humidity: return "Humid"
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Weather Overlay Picker
//////////////////////////////////////////////////////////

struct WeatherOverlayPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOverlay: WeatherOverlay
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(WeatherOverlay.allCases) { overlay in
                            OverlayOptionButton(
                                overlay: overlay,
                                isSelected: selectedOverlay == overlay
                            ) {
                                selectedOverlay = overlay
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Weather Layers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Overlay Option Button
//////////////////////////////////////////////////////////

struct OverlayOptionButton: View {
    let overlay: WeatherOverlay
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                overlayIcon
                
                // Info
                overlayInfo
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
            }
            .padding()
            .background(backgroundView)
        }
    }
    
    private var overlayIcon: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1))
                .frame(width: 50, height: 50)
            
            Image(systemName: overlay.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .cyan : .white.opacity(0.7))
        }
    }
    
    private var overlayInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(overlay.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(overlay.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
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
    @Published var alerts: [WeatherAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentLocation: CLLocation?

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
        
        currentLocation = location

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
                
                // Calculate sunrise/sunset (simplified - using fixed times for demo)
                let calendar = Calendar.current
                let now = Date()
                let sunrise = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now)
                let sunset = calendar.date(bySettingHour: 19, minute: 45, second: 0, of: now)

                self.currentWeather = CurrentWeather(
                    temp: decoded.current_weather.temperature,
                    wind: decoded.current_weather.windspeed,
                    feelsLike: decoded.hourly.apparent_temperature.first ?? decoded.current_weather.temperature,
                    humidity: Int(humidity),
                    pressure: pressure,
                    condition: condition,
                    uvIndex: Int.random(in: 1...11), // Simulated UV index
                    visibility: Int.random(in: 5...10), // Simulated visibility in miles
                    precipitation: Int(humidity > 70 ? 60 : 20), // Simplified precipitation chance
                    sunrise: sunrise,
                    sunset: sunset
                )

                self.hourly = zip(
                    decoded.hourly.time.prefix(24),
                    zip(decoded.hourly.temperature_2m.prefix(24),
                        decoded.hourly.relativehumidity_2m.prefix(24))
                )
                .map {
                    HourlyForecast(
                        time: self.formatHour($0.0),
                        temp: $0.1.0,
                        precipitation: Int($0.1.1 > 70 ? 60 : $0.1.1 > 50 ? 30 : 0)
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
                
                // Generate sample alerts based on conditions
                self.alerts = []
                if condition == .stormy {
                    self.alerts.append(WeatherAlert(
                        title: "Severe Thunderstorm Warning",
                        description: "Strong storms expected with heavy rain and lightning. Seek shelter.",
                        severity: .severe
                    ))
                } else if decoded.current_weather.temperature > 95 {
                    self.alerts.append(WeatherAlert(
                        title: "Heat Advisory",
                        description: "Excessive heat expected. Stay hydrated and limit outdoor activities.",
                        severity: .moderate
                    ))
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
    let uvIndex: Int
    let visibility: Int
    let precipitation: Int
    let sunrise: Date?
    let sunset: Date?
}

struct HourlyForecast {
    let time: String
    let temp: Double
    let precipitation: Int
}

struct DailyForecast {
    let day: String
    let max: Double
    let min: Double
}

struct WeatherAlert {
    let title: String
    let description: String
    let severity: AlertSeverity
    
    enum AlertSeverity {
        case moderate
        case severe
    }
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

