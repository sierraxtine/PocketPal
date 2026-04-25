import SwiftUI

//////////////////////////////////////////////////////////
// MARK: Home View
//////////////////////////////////////////////////////////

struct PocketPalHomeView: View {
    
    @State private var animateTiles = false
    @State private var showTitle = false
    @State private var particleRotation: Double = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                //////////////////////////////////////////////////////////
                // Elegant Background Layers
                //////////////////////////////////////////////////////////
                
                // Refined gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.03, blue: 0.12),
                        Color(red: 0.01, green: 0.02, blue: 0.08),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle animated glow
                AuroraGlow()
                    .blur(radius: 100)
                    .opacity(0.25)
                
                // Minimal floating particles
                FloatingParticles()
                    .blur(radius: 2)
                    .opacity(0.3)
                
                // Elegant center glow
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.08),
                        Color.blue.opacity(0.04),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 500
                )
                .ignoresSafeArea()
                .scaleEffect(showTitle ? 1 : 0.5)
                .opacity(showTitle ? 1 : 0)
                .animation(.easeOut(duration: 1.5).delay(0.2), value: showTitle)
                
                
                //////////////////////////////////////////////////////////
                // Content
                //////////////////////////////////////////////////////////
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 40) {
                        
                        //////////////////////////////////////////////////////////
                        // Elegant Title Section
                        //////////////////////////////////////////////////////////
                        
                        VStack(spacing: 12) {
                            
                            // Refined title
                            Text("Pocket Pal")
                                .font(.system(size: 48, weight: .semibold, design: .rounded))
                                .kerning(0.5)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            .white,
                                            .white.opacity(0.95),
                                            .cyan.opacity(0.7)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.2), radius: 15, x: 0, y: 5)
                            
                            // Refined subtitle
                            Text("Your Travel Companion")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.5))
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 15)
                                .animation(.easeOut(duration: 0.8).delay(0.4), value: showTitle)
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : -50)
                        .animation(.easeOut(duration: 1.0).delay(0.1), value: showTitle)
                        .padding(.top, 70)
                        .padding(.bottom, 10)
                        
                        
                        //////////////////////////////////////////////////////////
                        // Elegant Tiles Grid
                        //////////////////////////////////////////////////////////

                        LazyVGrid(columns: columns, spacing: 16) {
                            
                            Tile(
                                title: "World Clock",
                                icon: "globe",
                                gradient: [.blue, .cyan],
                                delay: 0.1,
                                animateTiles: animateTiles
                            ) {
                                WorldClockView()
                            }
                            
                            Tile(
                                title: "Compass",
                                icon: "location.north.fill",
                                gradient: [.green, .mint],
                                delay: 0.15,
                                animateTiles: animateTiles
                            ) {
                                CompassView()
                            }
                            
                            Tile(
                                title: "Weather",
                                icon: "cloud.sun.fill",
                                gradient: [.orange, .yellow],
                                delay: 0.2,
                                animateTiles: animateTiles
                            ) {
                                WeatherView()
                            }
                            
                            Tile(
                                title: "Translator",
                                icon: "globe.badge.chevron.backward",
                                gradient: [.cyan, .teal],
                                delay: 0.25,
                                animateTiles: animateTiles
                            ) {
                                TranslatorView()
                            }
                            
                            Tile(
                                title: "Scheduler",
                                icon: "calendar.badge.clock",
                                gradient: [.purple, .pink],
                                delay: 0.3,
                                animateTiles: animateTiles
                            ) {
                                SchedulerView()
                            }
                            
                            Tile(
                                title: "Maps",
                                icon: "map.fill",
                                gradient: [.indigo, .blue],
                                delay: 0.35,
                                animateTiles: animateTiles
                            ) {
                                MapsView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 50)
                    }
                }
            }
            .onAppear {
                showTitle = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateTiles = true
                }
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Elegant Tile
//////////////////////////////////////////////////////////

struct Tile<Destination: View>: View {
    
    var title: String
    var icon: String
    var gradient: [Color]
    var delay: Double
    var animateTiles: Bool
    
    var destination: () -> Destination
    
    @State private var isPressed = false
    @State private var iconFloat = false
    
    var body: some View {
        
        NavigationLink(destination: destination()) {
            
            VStack(spacing: 14) {
                
                //////////////////////////////////////////////////////////
                // Icon with subtle animation
                //////////////////////////////////////////////////////////
                
                ZStack {
                    // Soft glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradient[0].opacity(0.15),
                                    gradient[1].opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 35
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.95),
                                    gradient[0].opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(y: iconFloat ? -2 : 0)
                }
                
                //////////////////////////////////////////////////////////
                // Title
                //////////////////////////////////////////////////////////
                
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .tracking(0.3)
            }
            .frame(height: 135)
            .frame(maxWidth: .infinity)
            
            //////////////////////////////////////////////////////////
            // Elegant card background
            //////////////////////////////////////////////////////////
            
            .background(
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradient[0].opacity(0.08),
                                    gradient[1].opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            
            //////////////////////////////////////////////////////////
            // Refined border
            //////////////////////////////////////////////////////////
            
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.15),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            
            //////////////////////////////////////////////////////////
            // Subtle shadow
            //////////////////////////////////////////////////////////
            
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .shadow(color: gradient[0].opacity(0.1), radius: 20, x: 0, y: 10)
            
            //////////////////////////////////////////////////////////
            // Press effect
            //////////////////////////////////////////////////////////
            
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
        }
        .buttonStyle(.plain)
        
        //////////////////////////////////////////////////////////
        // Gesture handling
        //////////////////////////////////////////////////////////
        
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeOut(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPressed = false
                    }
                }
        )
        
        //////////////////////////////////////////////////////////
        // Entrance animation
        //////////////////////////////////////////////////////////
        
        .opacity(animateTiles ? 1 : 0)
        .offset(y: animateTiles ? 0 : 40)
        .scaleEffect(animateTiles ? 1 : 0.9)
        .animation(
            .easeOut(duration: 0.6)
                .delay(delay),
            value: animateTiles
        )
        
        //////////////////////////////////////////////////////////
        // Subtle float animation
        //////////////////////////////////////////////////////////
        
        .onAppear {
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                iconFloat = true
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Elegant Aurora Glow
//////////////////////////////////////////////////////////

struct AuroraGlow: View {
    
    @State private var animate = false
    
    var body: some View {
        
        ZStack {
            // First subtle layer
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.15),
                    Color.cyan.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .rotationEffect(.degrees(animate ? 10 : -10))
            .offset(x: animate ? 30 : -30)
            
            // Second layer
            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.12),
                    Color.blue.opacity(0.08),
                    Color.clear
                ],
                center: .center,
                startRadius: 50,
                endRadius: 400
            )
            .scaleEffect(animate ? 1.1 : 0.95)
        }
        .animation(
            .easeInOut(duration: 12)
                .repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear {
            animate = true
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Elegant Floating Particles
//////////////////////////////////////////////////////////

struct FloatingParticles: View {
    
    @State private var particles: [ParticleData] = (0..<20).map { _ in
        ParticleData(
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 2...5),
            duration: Double.random(in: 10...18)
        )
    }
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<particles.count, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.cyan.opacity(0.2),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: particles[i].size / 2
                            )
                        )
                        .frame(width: particles[i].size, height: particles[i].size)
                        .position(
                            x: particles[i].x * geo.size.width,
                            y: (animate ? (particles[i].y + 0.2) : particles[i].y) * geo.size.height
                        )
                        .opacity(animate ? 0.6 : 0.2)
                        .animation(
                            .easeInOut(duration: particles[i].duration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct ParticleData {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var duration: Double
}

//////////////////////////////////////////////////////////
// MARK: Preview
//////////////////////////////////////////////////////////

#Preview {
    PocketPalHomeView()
}
