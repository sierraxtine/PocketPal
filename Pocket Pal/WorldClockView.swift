import SwiftUI
import SceneKit

//////////////////////////////////////////////////////////////
// MARK: WORLD CLOCK VIEW
//////////////////////////////////////////////////////////////

struct WorldClockView: View {

    @State private var selectedCity = "All"
    @State private var searchText = ""
    
    @State private var cities:[(name:String,zone:String,lat:Double,lon:Double)] = [
        ("My Location 📍","LOCAL", 0, 0),
        ("New York 🗽","America/New_York", 40.7128, -74.0060),
        ("London 🎡","Europe/London", 51.5072, -0.1276),
        ("Paris 🗼","Europe/Paris", 48.8566, 2.3522),
        ("Tokyo 🏯","Asia/Tokyo", 35.6895, 139.6917),
        ("Sydney 🏖️","Australia/Sydney", -33.8688, 151.2093),
        ("Dubai 🏙️","Asia/Dubai", 25.2048, 55.2708),
        ("Singapore 🌆","Asia/Singapore", 1.3521, 103.8198)
    ]

    @State private var showAdd = false

    var filteredCities: [(name:String,zone:String,lat:Double,lon:Double)] {
        let filtered = searchText.isEmpty ? cities : cities.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) 
        }
        
        if selectedCity == "All" {
            return filtered
        } else {
            return filtered.filter { $0.name == selectedCity }
        }
    }

    var body: some View {

        ZStack {

            StarfieldBackground()

            VStack(spacing: 20) {

                Spacer().frame(height: 20)

                //////////////////////////////////////////////////////
                // TITLE
                //////////////////////////////////////////////////////

                Text("World Clock")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                //////////////////////////////////////////////////////
                // CONTROLS
                //////////////////////////////////////////////////////

                HStack(spacing: 14) {

                    // SEARCH BAR
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.cyan.opacity(0.7))
                        TextField("Search cities", text: $searchText)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )

                    // FILTER BUTTON
                    Menu {
                        Button("All") { selectedCity = "All" }

                        ForEach(cities, id:\.name) { city in
                            Button(city.name) {
                                selectedCity = city.name
                            }
                        }

                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedCity == "All" ? "Filter" : "")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }

                    // ADD BUTTON
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size:16,weight:.bold))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.cyan)
                                    .shadow(color: .cyan.opacity(0.6), radius: 10)
                            )
                    }
                }
                .padding(.horizontal, 24)

                //////////////////////////////////////////////////////
                // GLOBE (FIXED 🔥)
                //////////////////////////////////////////////////////

                GlobeView()
                    .frame(height: 260)
                    .padding(.vertical, 8)

                //////////////////////////////////////////////////////
                // GRID
                //////////////////////////////////////////////////////

                ScrollView {

                    LazyVGrid(
                        columns: [
                            GridItem(.adaptive(minimum: 340), spacing: 18)
                        ],
                        spacing: 18
                    ) {

                        ForEach(filteredCities, id:\.name) { city in
                            EnhancedClockCard(
                                city: city.name, 
                                zone: city.zone,
                                latitude: city.lat,
                                longitude: city.lon
                            ) {
                                delete(city)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }

                Spacer(minLength: 0)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddCitySheet { name, zone in
                cities.append((name, zone, 0, 0))
            }
        }
    }

    private func delete(_ city:(name:String,zone:String,lat:Double,lon:Double)) {
        cities.removeAll { $0.name == city.name }
    }
}

//////////////////////////////////////////////////////////////
// MARK: ENHANCED CLOCK CARD
//////////////////////////////////////////////////////////////

struct EnhancedClockCard: View {

    var city: String
    var zone: String
    var latitude: Double
    var longitude: Double
    var onDelete: () -> Void

    var body: some View {

        TimelineView(.periodic(from: .now, by: 1)) { context in

            ZStack(alignment: .topTrailing) {

                VStack(spacing: 16) {

                    // City Name & Date
                    VStack(spacing: 4) {
                        Text(city)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(dateString(context.date))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    HStack(spacing: 20) {

                        // Analog Clock
                        ZStack {
                            // Clock face
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.05)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 2)
                                )

                            // Hour markers
                            ForEach(0..<12) { hour in
                                Rectangle()
                                    .fill(Color.white.opacity(0.6))
                                    .frame(width: 2, height: hour % 3 == 0 ? 8 : 5)
                                    .offset(y: -40)
                                    .rotationEffect(.degrees(Double(hour) * 30))
                            }

                            // Hour hand
                            Rectangle()
                                .fill(Color.cyan)
                                .frame(width: 3, height: 25)
                                .offset(y: -12.5)
                                .rotationEffect(hourAngle(context.date))

                            // Minute hand
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 2, height: 35)
                                .offset(y: -17.5)
                                .rotationEffect(minuteAngle(context.date))

                            // Second hand
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 1, height: 38)
                                .offset(y: -19)
                                .rotationEffect(secondAngle(context.date))

                            // Center dot
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 8, height: 8)
                        }

                        // Digital time & info
                        VStack(alignment: .leading, spacing: 8) {
                            
                            // Digital time
                            Text(time(context.date))
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .cyan.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            // Day/Night indicator
                            HStack(spacing: 6) {
                                Image(systemName: isDaytime(context.date) ? "sun.max.fill" : "moon.stars.fill")
                                    .foregroundColor(isDaytime(context.date) ? .yellow : .blue.opacity(0.8))
                                    .font(.system(size: 14))
                                
                                Text(isDaytime(context.date) ? "Daytime" : "Nighttime")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            // Time difference
                            if zone != "LOCAL" {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.arrow.2.circlepath")
                                        .font(.system(size: 12))
                                    Text(timeDifference(context.date))
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.white.opacity(0.6))
                            }

                            // Sunrise/Sunset
                            if latitude != 0 || longitude != 0 {
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "sunrise.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.orange.opacity(0.8))
                                        Text(sunriseTime(context.date))
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "sunset.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(.pink.opacity(0.8))
                                        Text(sunsetTime(context.date))
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.cyan.opacity(0.3),
                                            Color.blue.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: .cyan.opacity(0.15), radius: 15, y: 8)
                )

                // Delete button
                if city != "My Location 📍" {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 24))
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .frame(width: 20, height: 20)
                            )
                    }
                    .offset(x: 8, y: -8)
                }
            }
        }
    }

    // Helper functions
    private func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = zone == "LOCAL" ? .current : TimeZone(identifier: zone)
        return f.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        f.timeZone = zone == "LOCAL" ? .current : TimeZone(identifier: zone)
        return f.string(from: date)
    }

    private func hourAngle(_ date: Date) -> Angle {
        let tz = zone == "LOCAL" ? TimeZone.current : TimeZone(identifier: zone) ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let degrees = Double(hour % 12) * 30 + Double(minute) * 0.5
        return .degrees(degrees)
    }

    private func minuteAngle(_ date: Date) -> Angle {
        let tz = zone == "LOCAL" ? TimeZone.current : TimeZone(identifier: zone) ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        let minute = calendar.component(.minute, from: date)
        return .degrees(Double(minute) * 6)
    }

    private func secondAngle(_ date: Date) -> Angle {
        let tz = zone == "LOCAL" ? TimeZone.current : TimeZone(identifier: zone) ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        let second = calendar.component(.second, from: date)
        return .degrees(Double(second) * 6)
    }

    private func isDaytime(_ date: Date) -> Bool {
        let tz = zone == "LOCAL" ? TimeZone.current : TimeZone(identifier: zone) ?? .current
        var calendar = Calendar.current
        calendar.timeZone = tz
        let hour = calendar.component(.hour, from: date)
        return hour >= 6 && hour < 18
    }

    private func timeDifference(_ date: Date) -> String {
        let localTZ = TimeZone.current
        let targetTZ = TimeZone(identifier: zone) ?? .current
        
        let localOffset = localTZ.secondsFromGMT(for: date) / 3600
        let targetOffset = targetTZ.secondsFromGMT(for: date) / 3600
        let diff = targetOffset - localOffset
        
        if diff == 0 {
            return "Same time"
        } else if diff > 0 {
            return "+\(diff)h ahead"
        } else {
            return "\(diff)h behind"
        }
    }

    private func sunriseTime(_ date: Date) -> String {
        // Simplified calculation - in a real app you'd use a proper solar calculation library
        return "6:30 AM"
    }

    private func sunsetTime(_ date: Date) -> String {
        // Simplified calculation - in a real app you'd use a proper solar calculation library
        return "6:45 PM"
    }
}

//////////////////////////////////////////////////////////////
// MARK: ADD SHEET
//////////////////////////////////////////////////////////////

struct AddCitySheet: View {

    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var zone = TimeZone.current.identifier

    var onSave: (String,String) -> Void

    var body: some View {

        VStack(spacing: 20) {

            Text("Add Location")
                .font(.title.bold())

            TextField("City Name", text: $name)
                .textFieldStyle(.roundedBorder)

            Picker("Time Zone", selection: $zone) {
                ForEach(TimeZone.knownTimeZoneIdentifiers, id:\.self) {
                    Text($0)
                }
            }
            .frame(height: 140)

            Button("Save") {
                onSave(name, zone)
                dismiss()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .padding(30)
        .frame(minWidth: 320)
    }
}

//////////////////////////////////////////////////////////////
// MARK: GLOBE VIEW (REAL FIX)
//////////////////////////////////////////////////////////////

#if os(iOS)
import UIKit
struct GlobeView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView { makeSceneView() }
    func updateUIView(_ view: SCNView, context: Context) {}
}
#else
import AppKit
struct GlobeView: NSViewRepresentable {
    func makeNSView(context: Context) -> SCNView { makeSceneView() }
    func updateNSView(_ view: SCNView, context: Context) {}
}
#endif

func makeSceneView() -> SCNView {
    let v = SCNView()
    v.scene = makeScene()
    v.backgroundColor = .clear
    v.autoenablesDefaultLighting = true
    v.antialiasingMode = .multisampling4X
    return v
}

func makeScene() -> SCNScene {

    let scene = SCNScene()

    let sphere = SCNSphere(radius: 1)
    sphere.segmentCount = 300

    let material = SCNMaterial()

    #if os(iOS)
    material.diffuse.contents = UIImage(named: "earth")
    #else
    material.diffuse.contents = NSImage(named: "earth")
    #endif

    material.lightingModel = .physicallyBased
    material.shininess = 0.2

    sphere.firstMaterial = material

    let node = SCNNode(geometry: sphere)

    node.runAction(
        .repeatForever(
            .rotateBy(x: 0, y: .pi * 2, z: 0, duration: 60)
        )
    )

    scene.rootNode.addChildNode(node)

    let camera = SCNNode()
    camera.camera = SCNCamera()
    camera.position = SCNVector3(0,0,3)

    scene.rootNode.addChildNode(camera)

    return scene
}

//////////////////////////////////////////////////////////////
// MARK: STARFIELD (FIXED ✨)
//////////////////////////////////////////////////////////////

struct StarfieldBackground: View {

    struct Star: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let size: CGFloat
        let opacity: Double
    }

    let stars: [Star] = (0..<160).map { _ in
        Star(
            x: .random(in: 0...1),
            y: .random(in: 0...1),
            size: .random(in: 1...2.5),
            opacity: .random(in: 0.4...1)
        )
    }

    @State private var twinkle = false

    var body: some View {

        GeometryReader { geo in

            ZStack {

                Color.black

                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(
                            x: star.x * geo.size.width,
                            y: star.y * geo.size.height
                        )
                        .opacity(twinkle ? star.opacity : star.opacity * 0.3)
                        .blur(radius: 0.6)
                        .animation(
                            .easeInOut(duration: Double.random(in: 1.5...3))
                                .repeatForever(autoreverses: true),
                            value: twinkle
                        )
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            twinkle.toggle()
        }
    }
}
