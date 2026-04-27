import SwiftUI
import Combine

//////////////////////////////////////////////////////////
// MARK: Home View
//////////////////////////////////////////////////////////

struct PocketPalHomeView: View {
    
    @State private var animateTiles = false
    @State private var showTitle = false
    @State private var particleRotation: Double = 0
    @State private var currentTime = Date()
    @State private var meshGradientPhase: CGFloat = 0
    
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                //////////////////////////////////////////////////////////
                // Premium Background Layers
                //////////////////////////////////////////////////////////
                
                // Deep animated gradient background
                AnimatedMeshGradient(phase: meshGradientPhase)
                    .ignoresSafeArea()
                
                // Layered aurora effects
                AuroraGlow()
                    .blur(radius: 120)
                    .opacity(0.35)
                
                // Floating orbs with depth
                FloatingOrbs()
                    .blur(radius: 3)
                    .opacity(0.4)
                
                // Enhanced floating particles
                FloatingParticles()
                    .blur(radius: 1.5)
                    .opacity(0.25)
                
                // Animated center glow with pulse
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.12),
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.03),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 20,
                    endRadius: 450
                )
                .ignoresSafeArea()
                .scaleEffect(showTitle ? 1 : 0.5)
                .opacity(showTitle ? 1 : 0)
                .animation(.easeOut(duration: 1.5).delay(0.2), value: showTitle)
                
                
                //////////////////////////////////////////////////////////
                // Content
                //////////////////////////////////////////////////////////
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 35) {
                        
                        //////////////////////////////////////////////////////////
                        // Premium Title Section with Live Clock
                        //////////////////////////////////////////////////////////
                        
                        VStack(spacing: 16) {
                            
                            // Animated logo/icon
                            ZStack {
                                // Pulsing glow rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.cyan.opacity(0.3 - Double(i) * 0.1),
                                                    Color.blue.opacity(0.2 - Double(i) * 0.05),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                        .frame(width: 80 + CGFloat(i) * 20, height: 80 + CGFloat(i) * 20)
                                        .scaleEffect(showTitle ? 1 : 0.5)
                                        .opacity(showTitle ? 1 : 0)
                                        .animation(
                                            .easeOut(duration: 1.0 + Double(i) * 0.3)
                                            .delay(0.3 + Double(i) * 0.1)
                                            .repeatForever(autoreverses: true),
                                            value: showTitle
                                        )
                                }
                                
                                // Main icon
                                Image(systemName: "airplane.circle.fill")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                .white,
                                                .cyan.opacity(0.9),
                                                .blue.opacity(0.7)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .cyan.opacity(0.5), radius: 20, x: 0, y: 5)
                                    .rotationEffect(.degrees(showTitle ? 0 : -180))
                                    .scaleEffect(showTitle ? 1 : 0.3)
                                    .animation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.2), value: showTitle)
                            }
                            .frame(height: 120)
                            
                            // Premium title with shimmer effect
                            Text("Pocket Pal")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .kerning(1)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            .white,
                                            .cyan.opacity(0.9),
                                            .blue.opacity(0.8),
                                            .purple.opacity(0.7)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 20, x: 0, y: 8)
                                .shadow(color: .blue.opacity(0.2), radius: 40, x: 0, y: 15)
                            
                            // Live time display
                            Text(currentTime, style: .time)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.8), .blue.opacity(0.6)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(
                                                    LinearGradient(
                                                        colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                                                        startPoint: .leading,
                                                        endPoint: .trailing
                                                    ),
                                                    lineWidth: 1
                                                )
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                .opacity(showTitle ? 1 : 0)
                                .offset(y: showTitle ? 0 : 10)
                                .animation(.easeOut(duration: 0.8).delay(0.5), value: showTitle)
                            
                            // Enhanced subtitle
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("Your Ultimate Travel Companion")
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                Image(systemName: "sparkles")
                                    .font(.caption)
                            }
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.6), value: showTitle)
                        }
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : -30)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.1), value: showTitle)
                        .padding(.top, 60)
                        .padding(.bottom, 10)
                        
                        // Quick stats bar
                        QuickStatsBar()
                            .opacity(showTitle ? 1 : 0)
                            .offset(y: showTitle ? 0 : 20)
                            .animation(.easeOut(duration: 0.8).delay(0.7), value: showTitle)
                            .padding(.horizontal, 20)
                        
                        
                        //////////////////////////////////////////////////////////
                        // Enhanced Tiles Grid
                        //////////////////////////////////////////////////////////

                        LazyVGrid(columns: columns, spacing: 18) {
                            
                            EnhancedTile(
                                title: "World Clock",
                                subtitle: "Time zones",
                                icon: "globe.americas.fill",
                                gradient: [.blue, .cyan, .teal],
                                delay: 0.1,
                                animateTiles: animateTiles
                            ) {
                                WorldClockView()
                            }
                            
                            EnhancedTile(
                                title: "Compass",
                                subtitle: "Navigation",
                                icon: "location.north.circle.fill",
                                gradient: [.green, .mint, .cyan],
                                delay: 0.15,
                                animateTiles: animateTiles
                            ) {
                                CompassView()
                            }
                            
                            EnhancedTile(
                                title: "Weather",
                                subtitle: "Forecast",
                                icon: "cloud.sun.rain.fill",
                                gradient: [.orange, .yellow, .pink],
                                delay: 0.2,
                                animateTiles: animateTiles
                            ) {
                                WeatherView()
                            }
                            
                            EnhancedTile(
                                title: "Translator",
                                subtitle: "Languages",
                                icon: "character.bubble.fill",
                                gradient: [.cyan, .teal, .blue],
                                delay: 0.25,
                                animateTiles: animateTiles
                            ) {
                                TranslatorView()
                            }
                            
                            EnhancedTile(
                                title: "Scheduler",
                                subtitle: "Events",
                                icon: "calendar.badge.clock",
                                gradient: [.purple, .pink, .red],
                                delay: 0.3,
                                animateTiles: animateTiles
                            ) {
                                SchedulerView()
                            }
                            
                            EnhancedTile(
                                title: "Maps",
                                subtitle: "Explore",
                                icon: "map.circle.fill",
                                gradient: [.indigo, .blue, .purple],
                                delay: 0.35,
                                animateTiles: animateTiles
                            ) {
                                MapsView()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 60)
                    }
                }
            }
            .onAppear {
                showTitle = true
                
                // Animate mesh gradient
                withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                    meshGradientPhase = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    animateTiles = true
                }
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Animated Mesh Gradient Background
//////////////////////////////////////////////////////////

struct AnimatedMeshGradient: View {
    let phase: CGFloat
    
    var body: some View {
        ZStack {
            // Base layer
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.03, blue: 0.12),
                    Color(red: 0.01, green: 0.02, blue: 0.08),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay layers
            RadialGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.purple.opacity(0.08),
                    Color.clear
                ],
                center: UnitPoint(x: 0.3 + phase * 0.2, y: 0.2 + phase * 0.15),
                startRadius: 0,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    Color.cyan.opacity(0.12),
                    Color.teal.opacity(0.06),
                    Color.clear
                ],
                center: UnitPoint(x: 0.7 - phase * 0.2, y: 0.8 - phase * 0.15),
                startRadius: 0,
                endRadius: 350
            )
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Quick Stats Bar
//////////////////////////////////////////////////////////

struct QuickStatsBar: View {
    @State private var animateStats = false
    
    var body: some View {
        HStack(spacing: 0) {
            QuickStatItem(icon: "airplane", value: "6", label: "Tools", delay: 0)
            
            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.1))
            
            QuickStatItem(icon: "star.fill", value: "Pro", label: "Version", delay: 0.1)
            
            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.1))
            
            QuickStatItem(icon: "checkmark.seal.fill", value: "100%", label: "Ready", delay: 0.2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.2),
                                    .white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    let delay: Double
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan.opacity(0.9), .blue.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .opacity(animate ? 1 : 0)
        .offset(y: animate ? 0 : 10)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(delay)) {
                animate = true
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Enhanced Tile with Premium Effects
//////////////////////////////////////////////////////////

struct EnhancedTile<Destination: View>: View {
    
    var title: String
    var subtitle: String
    var icon: String
    var gradient: [Color]
    var delay: Double
    var animateTiles: Bool
    
    var destination: () -> Destination
    
    @State private var isPressed = false
    @State private var iconFloat = false
    @State private var shimmerPhase: CGFloat = 0
    
    var body: some View {
        
        NavigationLink(destination: destination()) {
            
            VStack(spacing: 12) {
                
                //////////////////////////////////////////////////////////
                // Icon with advanced effects
                //////////////////////////////////////////////////////////
                
                ZStack {
                    // Animated glow rings
                    ForEach(0..<2) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        gradient[0].opacity(0.3 - Double(i) * 0.15),
                                        gradient[1].opacity(0.2 - Double(i) * 0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 60 + CGFloat(i) * 15, height: 60 + CGFloat(i) * 15)
                            .scaleEffect(iconFloat ? 1.1 : 1)
                            .opacity(iconFloat ? 0.6 : 0.3)
                    }
                    
                    // Gradient background circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    gradient[0].opacity(0.25),
                                    gradient[1].opacity(0.15),
                                    gradient[2].opacity(0.08)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    gradient[0].opacity(0.95),
                                    gradient[1].opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: gradient[0].opacity(0.5), radius: 10, x: 0, y: 5)
                        .offset(y: iconFloat ? -3 : 0)
                        .rotationEffect(.degrees(isPressed ? 5 : 0))
                }
                .frame(height: 80)
                
                //////////////////////////////////////////////////////////
                // Text content
                //////////////////////////////////////////////////////////
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(0.3)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [gradient[0].opacity(0.7), gradient[1].opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .tracking(0.5)
                }
            }
            .frame(height: 155)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            
            //////////////////////////////////////////////////////////
            // Premium card background with shimmer
            //////////////////////////////////////////////////////////
            
            .background(
                ZStack {
                    // Base glass material
                    RoundedRectangle(cornerRadius: 28)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradient[0].opacity(0.12),
                                    gradient[1].opacity(0.08),
                                    gradient[2].opacity(0.04),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .offset(x: shimmerPhase * 300 - 150)
                        .mask(
                            RoundedRectangle(cornerRadius: 28)
                        )
                }
            )
            
            //////////////////////////////////////////////////////////
            // Premium border with gradient
            //////////////////////////////////////////////////////////
            
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                gradient[0].opacity(0.4),
                                gradient[1].opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            
            //////////////////////////////////////////////////////////
            // Advanced shadows
            //////////////////////////////////////////////////////////
            
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .shadow(color: gradient[0].opacity(0.2), radius: 25, x: 0, y: 12)
            .shadow(color: gradient[1].opacity(0.15), radius: 35, x: 0, y: 15)
            
            //////////////////////////////////////////////////////////
            // Press effect with spring
            //////////////////////////////////////////////////////////
            
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
        }
        .buttonStyle(.plain)
        
        //////////////////////////////////////////////////////////
        // Gesture handling
        //////////////////////////////////////////////////////////
        
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        
        //////////////////////////////////////////////////////////
        // Entrance animation
        //////////////////////////////////////////////////////////
        
        .opacity(animateTiles ? 1 : 0)
        .offset(y: animateTiles ? 0 : 50)
        .scaleEffect(animateTiles ? 1 : 0.85)
        .rotation3DEffect(
            .degrees(animateTiles ? 0 : 15),
            axis: (x: 1, y: 0, z: 0)
        )
        .animation(
            .spring(response: 0.8, dampingFraction: 0.7)
                .delay(delay),
            value: animateTiles
        )
        
        //////////////////////////////////////////////////////////
        // Continuous animations
        //////////////////////////////////////////////////////////
        
        .onAppear {
            // Float animation
            withAnimation(
                .easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
                .delay(delay)
            ) {
                iconFloat = true
            }
            
            // Shimmer animation
            withAnimation(
                .linear(duration: 3.0)
                .repeatForever(autoreverses: false)
                .delay(delay + 1.0)
            ) {
                shimmerPhase = 1
            }
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Floating Orbs (New Effect)
//////////////////////////////////////////////////////////

struct FloatingOrbs: View {
    @State private var orbs: [OrbData] = (0..<8).map { i in
        OrbData(
            x: CGFloat.random(in: 0.1...0.9),
            y: CGFloat.random(in: 0.1...0.9),
            size: CGFloat.random(in: 60...120),
            color: [Color.cyan, .blue, .purple, .teal, .indigo][Int.random(in: 0...4)],
            duration: Double.random(in: 15...25)
        )
    }
    
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<orbs.count, id: \.self) { i in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    orbs[i].color.opacity(0.3),
                                    orbs[i].color.opacity(0.15),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: orbs[i].size / 2
                            )
                        )
                        .frame(width: orbs[i].size, height: orbs[i].size)
                        .position(
                            x: (animate ? orbs[i].x + 0.2 : orbs[i].x - 0.1) * geo.size.width,
                            y: (animate ? orbs[i].y - 0.2 : orbs[i].y + 0.1) * geo.size.height
                        )
                        .animation(
                            .easeInOut(duration: orbs[i].duration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.3),
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

struct OrbData {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var duration: Double
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
