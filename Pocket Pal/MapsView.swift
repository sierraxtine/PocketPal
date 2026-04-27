// TEST CHANGE 123
import SwiftUI
import MapKit
import CoreLocation
import Combine

//////////////////////////////////////////////////////////////
// MARK: Maps View
//////////////////////////////////////////////////////////////

struct MapsView: View {
    
    @StateObject private var locationManager = LocationManager()
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapStyle: MapStyle = .standard
    
    @State private var searchText = ""
    @State private var results: [MKMapItem] = []
    @State private var selectedItem: MKMapItem?
    
    @State private var showingDetail = false
    @State private var showFavorites = false
    @State private var showSearchHistory = false
    
    @State private var favoriteLocations: [SavedLocation] = []
    @State private var searchHistory: [String] = []
    
    @State private var route: MKRoute?
    @State private var showingRoute = false
    
    @State private var selectedCategory: PlaceCategory?
    @State private var isSearching = false
    
    @State private var isNavigating = false
    @State private var navigationSteps: [MKRoute.Step] = []
    @State private var currentStepIndex = 0
    @State private var showNavigationPanel = false
    
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        
        ZStack {
            
            //////////////////////////////////////////////////////////
            // BACKGROUND
            //////////////////////////////////////////////////////////
            
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.3, blue: 0.6),
                        Color(red: 0.1, green: 0.2, blue: 0.5),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                StarfieldBackground()
            }
            .ignoresSafeArea()
            
            //////////////////////////////////////////////////////////
            // MAP
            //////////////////////////////////////////////////////////
            
            Map(position: $cameraPosition) {
                
                // User location marker
                if let userLocation = locationManager.lastLocation {
                    Annotation("You", coordinate: userLocation.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.cyan.opacity(0.3))
                                .frame(width: 40, height: 40)
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        }
                    }
                }
                
                // Search results
                ForEach(results, id: \.self) { item in
                    let coordinate = item.location.coordinate
                    Annotation(item.name ?? "Place", coordinate: coordinate) {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(selectedItem == item ? Color.red : Color.red.opacity(0.8))
                                    .frame(width: selectedItem == item ? 44 : 36, height: selectedItem == item ? 44 : 36)
                                    .shadow(color: .red.opacity(0.5), radius: 8)
                                
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: selectedItem == item ? 28 : 22))
                                    .foregroundColor(.white)
                            }
                            
                            if selectedItem == item {
                                Text(item.name ?? "")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.black.opacity(0.75))
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedItem = item
                                showingDetail = true
                            }
                        }
                    }
                }
                
                // Favorite locations
                ForEach(favoriteLocations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                                .shadow(color: .yellow.opacity(0.6), radius: 8)
                        }
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                let item = MKMapItem()
                                item.name = location.name
                                item.setValue(CLLocation(latitude: location.coordinate.latitude,
                                                        longitude: location.coordinate.longitude),
                                            forKey: "location")
                                selectedItem = item
                                showingDetail = true
                            }
                        }
                    }
                }
                
                // Route polyline
                if let route = route {
                    MapPolyline(route)
                        .stroke(Color.cyan, lineWidth: 5)
                }
            }
            .mapStyle(mapStyle)
            .ignoresSafeArea()
            
            //////////////////////////////////////////////////////////
            // UI OVERLAY
            //////////////////////////////////////////////////////////
            
            VStack(spacing: 0) {
                
                //////////////////////////////////////////////////////////
                // TOP BAR
                //////////////////////////////////////////////////////////
                
                VStack(spacing: 16) {
                    
                    Spacer().frame(height: 8)
                    
                    // Title & Favorites
                    HStack {
                        Text("Maps")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Spacer()
                        
                        Button {
                            showFavorites.toggle()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18))
                                Text("Saved")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.yellow)
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Search Bar
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.6))
                            
                            TextField("Search places...", text: $searchText)
                                .focused($isSearchFocused)
                                .foregroundColor(.white)
                                .submitLabel(.search)
                                .onSubmit {
                                    searchPlaces()
                                }
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                    results = []
                                    selectedItem = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.black.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        Button {
                            searchPlaces()
                        } label: {
                            ZStack {
                                if isSearching {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .frame(width: 24, height: 24)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                            )
                        }
                        .disabled(searchText.isEmpty || isSearching)
                    }
                    .padding(.horizontal)
                    
                    // Quick Category Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(PlaceCategory.allCases) { category in
                                Button {
                                    selectedCategory = category
                                    searchText = category.searchTerm
                                    searchPlaces()
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                            .font(.system(size: 13, weight: .medium))
                                    }
                                    .foregroundColor(selectedCategory == category ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.cyan : Color.black.opacity(0.5))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.6),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Spacer()
                
                //////////////////////////////////////////////////////////
                // BOTTOM CONTROLS
                //////////////////////////////////////////////////////////
                
                HStack(spacing: 12) {
                    
                    // Location Button
                    Button {
                        centerOnUser()
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.cyan)
                                    .shadow(color: .cyan.opacity(0.5), radius: 8)
                            )
                    }
                    
                    // Map Style Selector
                    Menu {
                        Button {
                            mapStyle = .standard
                        } label: {
                            Label("Standard", systemImage: "map")
                        }
                        
                        Button {
                            mapStyle = .hybrid
                        } label: {
                            Label("Satellite", systemImage: "globe.americas.fill")
                        }
                        
                        Button {
                            mapStyle = .imagery
                        } label: {
                            Label("Imagery", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "map.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.purple)
                                    .shadow(color: .purple.opacity(0.5), radius: 8)
                            )
                    }
                    
                    Spacer()
                    
                    // Zoom Controls
                    VStack(spacing: 8) {
                        Button {
                            zoomIn()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                        
                        Button {
                            zoomOut()
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                )
                        }
                    }
                }
                .padding()
                .padding(.bottom, 8)
            }
            
            //////////////////////////////////////////////////////////
            // DETAIL SHEET
            //////////////////////////////////////////////////////////
            
            if showingDetail, let item = selectedItem {
                VStack {
                    Spacer()
                    
                    PlaceDetailCard(
                        item: item,
                        userLocation: locationManager.lastLocation,
                        onDismiss: {
                            withAnimation {
                                showingDetail = false
                            }
                        },
                        onGetDirections: {
                            getDirections(to: item)
                        },
                        onSave: {
                            saveFavorite(item: item)
                        },
                        isFavorited: isFavorited(item: item)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .background(
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showingDetail = false
                            }
                        }
                )
            }
            
            //////////////////////////////////////////////////////////
            // NAVIGATION PANEL
            //////////////////////////////////////////////////////////
            
            if showNavigationPanel && isNavigating {
                VStack {
                    NavigationPanel(
                        route: route,
                        steps: navigationSteps,
                        currentStepIndex: $currentStepIndex,
                        onEndNavigation: {
                            endNavigation()
                        },
                        onNextStep: {
                            if currentStepIndex < navigationSteps.count - 1 {
                                currentStepIndex += 1
                            }
                        },
                        onPreviousStep: {
                            if currentStepIndex > 0 {
                                currentStepIndex -= 1
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesMapView(favorites: $favoriteLocations) { location in
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        }
        .onAppear {
            locationManager.requestPermission()
        }
    }
    
    //////////////////////////////////////////////////////////
    // SEARCH
    //////////////////////////////////////////////////////////
    
    func searchPlaces() {
        isSearchFocused = false
        
        // Add to history
        if !searchText.isEmpty && !searchHistory.contains(searchText) {
            searchHistory.insert(searchText, at: 0)
            if searchHistory.count > 10 {
                searchHistory = Array(searchHistory.prefix(10))
            }
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        
        // Use user location for better results
        if let userLocation = locationManager.lastLocation {
            request.region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
        
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            // Check for errors
            if let error = error {
                print("Search error: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else {
                print("No response from search")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                withAnimation {
                    self.results = response.mapItems
                    
                    if let first = response.mapItems.first {
                        let coordinate = first.location.coordinate
                        self.cameraPosition = .region(
                            MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                            )
                        )
                    } else {
                        print("No results found for: \(self.searchText)")
                    }
                }
            }
        }
    }
    
    //////////////////////////////////////////////////////////
    // CENTER USER
    //////////////////////////////////////////////////////////
    
    func centerOnUser() {
        guard let location = locationManager.lastLocation else { return }
        
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
    
    //////////////////////////////////////////////////////////
    // ZOOM CONTROLS
    //////////////////////////////////////////////////////////
    
    func zoomIn() {
        // Zoom functionality handled by MapKit gestures
        // Manual zoom controls removed due to pattern matching issues
    }
    
    func zoomOut() {
        // Zoom functionality handled by MapKit gestures
        // Manual zoom controls removed due to pattern matching issues
    }
    
    //////////////////////////////////////////////////////////
    // DIRECTIONS
    //////////////////////////////////////////////////////////
    
    func getDirections(to item: MKMapItem) {
        guard let userLocation = locationManager.lastLocation else { return }
        
        let request = MKDirections.Request()
        
        // Create source MKMapItem from user's location
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        sourceItem.name = "My Location"
        
        request.source = sourceItem
        request.destination = item
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { response, error in
            guard let route = response?.routes.first else { return }
            
            withAnimation {
                self.route = route
                showingRoute = true
                showingDetail = false
                
                // Store navigation steps
                self.navigationSteps = route.steps
                self.currentStepIndex = 0
                self.isNavigating = true
                self.showNavigationPanel = true
                
                // Adjust camera to show entire route
                let coordinates = route.polyline.coordinates
                let rect = coordinates.reduce(MKMapRect.null) { currentRect, coordinate in
                    let point = MKMapPoint(coordinate)
                    let pointRect = MKMapRect(origin: point, size: MKMapSize(width: 0, height: 0))
                    return currentRect.union(pointRect)
                }
                
                cameraPosition = .rect(rect.insetBy(dx: -rect.size.width * 0.2, dy: -rect.size.height * 0.2))
            }
        }
    }
    
    //////////////////////////////////////////////////////////
    // NAVIGATION CONTROL
    //////////////////////////////////////////////////////////
    
    func endNavigation() {
        withAnimation {
            isNavigating = false
            showNavigationPanel = false
            route = nil
            showingRoute = false
            navigationSteps = []
            currentStepIndex = 0
        }
    }
    
    //////////////////////////////////////////////////////////
    // FAVORITES
    //////////////////////////////////////////////////////////
    
    func saveFavorite(item: MKMapItem) {
        let coordinate = item.location.coordinate
        let location = SavedLocation(
            name: item.name ?? "Unknown Place",
            coordinate: coordinate,
            address: formatAddress(item)
        )
        
        if !favoriteLocations.contains(where: { $0.id == location.id }) {
            favoriteLocations.append(location)
        }
    }
    
    func isFavorited(item: MKMapItem) -> Bool {
        let coordinate = item.location.coordinate
        return favoriteLocations.contains { location in
            abs(location.coordinate.latitude - coordinate.latitude) < 0.0001 &&
            abs(location.coordinate.longitude - coordinate.longitude) < 0.0001
        }
    }
    
    func formatAddress(_ item: MKMapItem) -> String {
        var components: [String] = []
        
        // Use the placemark API for address information
        let placemark = item.placemark
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        return components.joined(separator: ", ")
    }
}

//////////////////////////////////////////////////////////////
// MARK: LOCATION MANAGER
//////////////////////////////////////////////////////////////

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.first
    }
}

//////////////////////////////////////////////////////////////
// MARK: PLACE CATEGORY
//////////////////////////////////////////////////////////////

enum PlaceCategory: String, CaseIterable, Identifiable {
    case restaurants = "Restaurants"
    case gas = "Gas"
    case hotels = "Hotels"
    case coffee = "Coffee"
    case parking = "Parking"
    case atm = "ATM"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .restaurants: return "fork.knife"
        case .gas: return "fuelpump.fill"
        case .hotels: return "bed.double.fill"
        case .coffee: return "cup.and.saucer.fill"
        case .parking: return "parkingsign.circle.fill"
        case .atm: return "dollarsign.circle.fill"
        }
    }
    
    var searchTerm: String {
        switch self {
        case .restaurants: return "restaurants"
        case .gas: return "gas station"
        case .hotels: return "hotels"
        case .coffee: return "coffee"
        case .parking: return "parking"
        case .atm: return "atm"
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: SAVED LOCATION
//////////////////////////////////////////////////////////////

struct SavedLocation: Identifiable, Codable, Hashable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, address
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, address: String) {
        self.name = name
        self.coordinate = coordinate
        self.address = address
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        let lat = try container.decode(Double.self, forKey: .latitude)
        let lon = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        address = try container.decode(String.self, forKey: .address)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(address, forKey: .address)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SavedLocation, rhs: SavedLocation) -> Bool {
        lhs.id == rhs.id
    }
}

//////////////////////////////////////////////////////////////
// MARK: PLACE DETAIL CARD
//////////////////////////////////////////////////////////////

struct PlaceDetailCard: View {
    
    let item: MKMapItem
    let userLocation: CLLocation?
    let onDismiss: () -> Void
    let onGetDirections: () -> Void
    let onSave: () -> Void
    let isFavorited: Bool
    
    private var distance: String? {
        guard let userLocation = userLocation else { return nil }
        let itemLocation = CLLocation(
            latitude: item.location.coordinate.latitude,
            longitude: item.location.coordinate.longitude
        )
        let meters = userLocation.distance(from: itemLocation)
        let miles = meters / 1609.34
        
        if miles < 0.1 {
            return "\(Int(meters)) meters away"
        } else {
            return String(format: "%.1f miles away", miles)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name ?? "Unknown Place")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(distance)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.cyan)
                    }
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Address
            if let address = formatAddress() {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.cyan)
                    Text(address)
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            // Coordinates
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latitude")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(item.location.coordinate.latitude, specifier: "%.6f")")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Longitude")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(item.location.coordinate.longitude, specifier: "%.6f")")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
            )
            
            // Action Buttons
            HStack(spacing: 12) {
                
                Button {
                    onGetDirections()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        Text("Directions")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                
                Button {
                    openInMaps()
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Open")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }
                
                Button {
                    onSave()
                } label: {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorited ? .yellow : .white)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.8))
                        )
                }
            }
            
            // Share Button
            Button {
                shareLocation()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Location")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.15, blue: 0.2),
                            Color(red: 0.1, green: 0.1, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.5), radius: 20)
        )
        .padding()
    }
    
    private func formatAddress() -> String? {
        var components: [String] = []
        
        // Use the placemark API for address information
        let placemark = item.placemark
        
        if let thoroughfare = placemark.thoroughfare {
            components.append(thoroughfare)
        }
        if let locality = placemark.locality {
            components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        if let postalCode = placemark.postalCode {
            components.append(postalCode)
        }
        
        let formatted = components.joined(separator: ", ")
        return formatted.isEmpty ? nil : formatted
    }
    
    private func openInMaps() {
        item.openInMaps(launchOptions: nil)
    }
    
    private func shareLocation() {
        #if os(iOS)
        let text = "\(item.name ?? "Location"): https://maps.apple.com/?ll=\(item.location.coordinate.latitude),\(item.location.coordinate.longitude)"
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
}

//////////////////////////////////////////////////////////////
// MARK: FAVORITES MAP VIEW
//////////////////////////////////////////////////////////////

struct FavoritesMapView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var favorites: [SavedLocation]
    let onSelect: (SavedLocation) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow.opacity(0.3))
                        Text("No saved locations")
                            .foregroundColor(.white.opacity(0.6))
                        Text("Tap the star icon to save places")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites) { location in
                                Button {
                                    onSelect(location)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(location.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text(location.address)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))
                                                .lineLimit(2)
                                            
                                            HStack(spacing: 12) {
                                                Text("Lat: \(location.coordinate.latitude, specifier: "%.4f")")
                                                Text("Lon: \(location.coordinate.longitude, specifier: "%.4f")")
                                            }
                                            .font(.system(size: 12, design: .monospaced))
                                            .foregroundColor(.cyan.opacity(0.8))
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Button {
                                            withAnimation {
                                                favorites.removeAll { $0.id == location.id }
                                            }
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red.opacity(0.8))
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.08))
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: MKPolyline Extension
//////////////////////////////////////////////////////////////

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

//////////////////////////////////////////////////////////////
// MARK: CLLocationCoordinate2D Codable
//////////////////////////////////////////////////////////////

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let latitude = try container.decode(Double.self)
        let longitude = try container.decode(Double.self)
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(latitude)
        try container.encode(longitude)
    }
}

//////////////////////////////////////////////////////////////
// MARK: NAVIGATION PANEL
//////////////////////////////////////////////////////////////

struct NavigationPanel: View {
    
    let route: MKRoute?
    let steps: [MKRoute.Step]
    @Binding var currentStepIndex: Int
    let onEndNavigation: () -> Void
    let onNextStep: () -> Void
    let onPreviousStep: () -> Void
    
    private var currentStep: MKRoute.Step? {
        guard currentStepIndex < steps.count else { return nil }
        return steps[currentStepIndex]
    }
    
    private var totalDistance: String {
        guard let route = route else { return "N/A" }
        let miles = route.distance / 1609.34
        return String(format: "%.1f mi", miles)
    }
    
    private var estimatedTime: String {
        guard let route = route else { return "N/A" }
        let minutes = Int(route.expectedTravelTime / 60)
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Main instruction card
            VStack(alignment: .leading, spacing: 12) {
                
                // Header with route info
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Navigation")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.cyan)
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(.system(size: 12))
                                Text(totalDistance)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 12))
                                Text(estimatedTime)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Button {
                        onEndNavigation()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                            Text("End")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Current step instruction
                if let step = currentStep {
                    HStack(alignment: .top, spacing: 12) {
                        // Direction icon
                        Image(systemName: getDirectionIcon(for: step.instructions))
                            .font(.system(size: 32))
                            .foregroundColor(.cyan)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(Color.cyan.opacity(0.2))
                            )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            // Step number
                            Text("Step \(currentStepIndex + 1) of \(steps.count)")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                            
                            // Instruction
                            Text(step.instructions.isEmpty ? "Continue on route" : step.instructions)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Distance for this step
                            if step.distance > 0 {
                                let stepMiles = step.distance / 1609.34
                                let distanceText = stepMiles < 0.1 ?
                                    "\(Int(step.distance)) meters" :
                                    String(format: "%.1f mi", stepMiles)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10))
                                    Text(distanceText)
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.cyan)
                            }
                        }
                    }
                    
                    // Navigation step controls
                    HStack(spacing: 12) {
                        Button {
                            onPreviousStep()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Previous")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(currentStepIndex > 0 ? .white : .white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(currentStepIndex > 0 ? 0.15 : 0.05))
                            )
                        }
                        .disabled(currentStepIndex == 0)
                        
                        Button {
                            onNextStep()
                        } label: {
                            HStack(spacing: 6) {
                                Text("Next")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(currentStepIndex < steps.count - 1 ? .white : .white.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white.opacity(currentStepIndex < steps.count - 1 ? 0.15 : 0.05))
                            )
                        }
                        .disabled(currentStepIndex >= steps.count - 1)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.15, green: 0.15, blue: 0.2),
                                Color(red: 0.1, green: 0.1, blue: 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: .black.opacity(0.4), radius: 15)
            )
            .padding(.horizontal)
            .padding(.top, 60) // Space for status bar and safe area
        }
    }
    
    private func getDirectionIcon(for instruction: String) -> String {
        let lowercased = instruction.lowercased()
        
        if lowercased.contains("right") {
            if lowercased.contains("slight") {
                return "arrow.turn.up.right"
            } else if lowercased.contains("sharp") {
                return "arrow.turn.right.up"
            } else {
                return "arrow.turn.up.right"
            }
        } else if lowercased.contains("left") {
            if lowercased.contains("slight") {
                return "arrow.turn.up.left"
            } else if lowercased.contains("sharp") {
                return "arrow.turn.left.up"
            } else {
                return "arrow.turn.up.left"
            }
        } else if lowercased.contains("u-turn") || lowercased.contains("uturn") {
            return "arrow.uturn.forward"
        } else if lowercased.contains("straight") || lowercased.contains("continue") {
            return "arrow.up"
        } else if lowercased.contains("merge") {
            return "arrow.triangle.merge"
        } else if lowercased.contains("exit") {
            return "arrow.uturn.right"
        } else if lowercased.contains("arrive") || lowercased.contains("destination") {
            return "mappin.circle.fill"
        } else {
            return "arrow.up.circle.fill"
        }
    }
}

// updated maps logic

