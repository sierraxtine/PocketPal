import SwiftUI

//////////////////////////////////////////////////////////
// MARK: Compass Mode
//////////////////////////////////////////////////////////

enum CompassMode: String, CaseIterable, Identifiable {
    case trueNorth = "True North"
    case magneticNorth = "Magnetic North"
    
    var id: String { rawValue }
    
    var description: String {
        rawValue
    }
}

//////////////////////////////////////////////////////////
// MARK: Compass View
//////////////////////////////////////////////////////////

struct CompassView: View {
    
    @StateObject private var headingManager = HeadingManager()
    @State private var showAccuracy = false
    @State private var selectedCompassMode: CompassMode = .trueNorth
    
    var body: some View {
        
        ZStack {
            
            ////////////////////////////////////////////////////
            // Enhanced Cosmic Background
            ////////////////////////////////////////////////////
            
            ZStack {
                RadialGradient(
                    colors: [
                        Color(red: 0.05, green: 0.08, blue: 0.15),
                        .black,
                        .black
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 800
                )
                
                // Subtle stars effect
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.2...0.6)))
                        .frame(width: CGFloat.random(in: 1...2))
                        .position(
                            x: CGFloat.random(in: 0...400),
                            y: CGFloat.random(in: 0...800)
                        )
                }
            }
            .ignoresSafeArea()
            
            
            ////////////////////////////////////////////////////
            // Enhanced Radar Pulses
            ////////////////////////////////////////////////////
            
            ZStack {
                RadarPulse(delay: 0)
                RadarPulse(delay: 0.7)
                RadarPulse(delay: 1.4)
            }
            
            
            ////////////////////////////////////////////////////
            // Main Layout
            ////////////////////////////////////////////////////
            
            VStack(spacing: 28) {
                
                ////////////////////////////////////////////////////
                // Enhanced Title with Mode Selector
                ////////////////////////////////////////////////////
                
                VStack(spacing: 12) {
                    Text("Compass")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .cyan.opacity(0.6), radius: 10)
                        .shadow(color: .blue.opacity(0.4), radius: 20)
                    
                    // Mode selector
                    Picker("Mode", selection: $selectedCompassMode) {
                        ForEach(CompassMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 300)
                    .onChange(of: selectedCompassMode) { oldValue, newValue in
                        headingManager.useTrueNorth = (newValue == .trueNorth)
                    }
                }
                
                
                ////////////////////////////////////////////////////
                // Enhanced Compass Dial
                ////////////////////////////////////////////////////
                
                ZStack {
                    
                    ////////////////////////////////////////////////////
                    // Outer Glow Ring
                    ////////////////////////////////////////////////////
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 360, height: 360)
                        .blur(radius: 8)
                    
                    
                    ////////////////////////////////////////////////////
                    // Glass Dial Background with depth
                    ////////////////////////////////////////////////////
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.03),
                                    Color.white.opacity(0.01)
                                ],
                                center: .topLeading,
                                startRadius: 10,
                                endRadius: 200
                            )
                        )
                        .frame(width: 340, height: 340)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.cyan.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: .cyan.opacity(0.2), radius: 15)
                    
                    
                    ////////////////////////////////////////////////////
                    // Degree Markers (every 30 degrees)
                    ////////////////////////////////////////////////////
                    
                    ForEach(0..<12) { index in
                        Text("\(index * 30)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .offset(y: -130)
                            .rotationEffect(.degrees(Double(index) * 30))
                            .rotationEffect(.degrees(-headingManager.heading))
                    }
                    .animation(.easeInOut(duration: 0.2), value: headingManager.heading)
                    
                    
                    ////////////////////////////////////////////////////
                    // Rotating Compass Ring
                    ////////////////////////////////////////////////////
                    
                    ZStack {
                        
                        ////////////////////////////////////////////////////
                        // Enhanced Tick Marks
                        ////////////////////////////////////////////////////
                        
                        ForEach(0..<72) { tick in
                            
                            let isMajor = tick % 6 == 0
                            let isCardinal = tick % 18 == 0
                            
                            Rectangle()
                                .fill(
                                    isCardinal ? Color.cyan :
                                    isMajor ? Color.white.opacity(0.8) :
                                    Color.white.opacity(0.4)
                                )
                                .frame(
                                    width: isCardinal ? 3 : 2,
                                    height: isCardinal ? 24 : (isMajor ? 16 : 8)
                                )
                                .offset(y: -158)
                                .rotationEffect(.degrees(Double(tick) * 5))
                        }
                        
                        
                        ////////////////////////////////////////////////////
                        // Enhanced Cardinal Labels with intercardinals
                        ////////////////////////////////////////////////////
                        
                        Group {
                            // Main Cardinals
                            cardinal("N", color: .red, size: 28)
                                .offset(y: -150)
                            
                            cardinal("S", color: .white, size: 24)
                                .offset(y: 150)
                            
                            cardinal("E", color: .white, size: 24)
                                .offset(x: 150)
                            
                            cardinal("W", color: .white, size: 24)
                                .offset(x: -150)
                            
                            // Intercardinals
                            cardinal("NE", color: .cyan.opacity(0.8), size: 16)
                                .offset(x: 106, y: -106)
                            
                            cardinal("SE", color: .cyan.opacity(0.8), size: 16)
                                .offset(x: 106, y: 106)
                            
                            cardinal("SW", color: .cyan.opacity(0.8), size: 16)
                                .offset(x: -106, y: 106)
                            
                            cardinal("NW", color: .cyan.opacity(0.8), size: 16)
                                .offset(x: -106, y: -106)
                        }
                        
                    }
                    .rotationEffect(.degrees(-headingManager.heading))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7),
                               value: headingManager.heading)
                    
                    
                    ////////////////////////////////////////////////////
                    // Enhanced Needle with glow
                    ////////////////////////////////////////////////////
                    
                    ZStack {
                        // Glow effect
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 150))
                            .foregroundStyle(Color.red.opacity(0.3))
                            .blur(radius: 20)
                        
                        // Main needle
                        Image(systemName: "location.north.fill")
                            .font(.system(size: 150))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .shadow(color: .red.opacity(0.8), radius: 14)
                            .shadow(color: .orange.opacity(0.6), radius: 8)
                    }
                    
                    
                    ////////////////////////////////////////////////////
                    // Center Hub with metallic look
                    ////////////////////////////////////////////////////
                    
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [.white, .gray.opacity(0.8)],
                                    center: .topLeading,
                                    startRadius: 1,
                                    endRadius: 8
                                )
                            )
                            .frame(width: 16, height: 16)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 10, height: 10)
                            .shadow(color: .white.opacity(0.8), radius: 6)
                    }
                    
                    
                    ////////////////////////////////////////////////////
                    // Accuracy indicator ring
                    ////////////////////////////////////////////////////
                    
                    if showAccuracy {
                        Circle()
                            .stroke(
                                headingManager.heading > 0 ? Color.green.opacity(0.5) : Color.orange.opacity(0.5),
                                style: StrokeStyle(lineWidth: 3, dash: [5, 5])
                            )
                            .frame(width: 350, height: 350)
                            .animation(.easeInOut(duration: 0.3), value: headingManager.heading)
                    }
                }
                
                
                ////////////////////////////////////////////////////
                // Enhanced Heading Readout
                ////////////////////////////////////////////////////
                
                VStack(spacing: 8) {
                    
                    HStack(spacing: 12) {
                        Text("\(Int(headingManager.heading))°")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .cyan.opacity(0.8), radius: 12)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3), value: headingManager.heading)
                        
                        Button {
                            showAccuracy.toggle()
                        } label: {
                            Image(systemName: showAccuracy ? "eye.fill" : "eye.slash.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Text(direction(from: headingManager.heading))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))
                        .textCase(.uppercase)
                        .tracking(2)
                    
                    Text(directionAbbreviation(from: headingManager.heading))
                        .font(.caption)
                        .foregroundColor(.cyan.opacity(0.7))
                        .fontWeight(.medium)
                }
                
                
                ////////////////////////////////////////////////////
                // Enhanced Sensor Status with more detail
                ////////////////////////////////////////////////////
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(headingManager.heading > 0 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(sensorStatus)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text("Mode: \(selectedCompassMode.description)")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
    
    
    ////////////////////////////////////////////////////
    // Cardinal Label Builder
    ////////////////////////////////////////////////////
    
    func cardinal(_ letter: String, color: Color) -> some View {
        
        Text(letter)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.7), radius: 8)
    }
    
    func cardinal(_ letter: String, color: Color, size: CGFloat) -> some View {
        
        Text(letter)
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
            .shadow(color: color.opacity(0.7), radius: 8)
    }
    
    
    ////////////////////////////////////////////////////
    // Direction Logic
    ////////////////////////////////////////////////////
    
    func direction(from degrees: Double) -> String {
        
        switch degrees {
        case 337...360, 0..<23:
            return "North"
            
        case 23..<68:
            return "North East"
            
        case 68..<113:
            return "East"
            
        case 113..<158:
            return "South East"
            
        case 158..<203:
            return "South"
            
        case 203..<248:
            return "South West"
            
        case 248..<293:
            return "West"
            
        default:
            return "North West"
        }
    }
    
    func directionAbbreviation(from degrees: Double) -> String {
        
        switch degrees {
        case 337...360, 0..<23:
            return "N"
            
        case 23..<68:
            return "NE"
            
        case 68..<113:
            return "E"
            
        case 113..<158:
            return "SE"
            
        case 158..<203:
            return "S"
            
        case 203..<248:
            return "SW"
            
        case 248..<293:
            return "W"
            
        default:
            return "NW"
        }
    }
    
    
    ////////////////////////////////////////////////////
    // Sensor Status
    ////////////////////////////////////////////////////
    
    var sensorStatus: String {
        
        if headingManager.heading == 0 {
            return "Sensor Status: No heading detected (simulator or Mac)"
        } else {
            return "Sensor Status: Magnetometer active"
        }
    }
}

//////////////////////////////////////////////////////////
// MARK: Radar Pulse Animation
//////////////////////////////////////////////////////////

struct RadarPulse: View {
    
    @State private var animate = false
    let delay: Double
    
    var body: some View {
        
        Circle()
            .stroke(Color.cyan.opacity(0.25), lineWidth: 2)
            .frame(width: 380, height: 380)
            .scaleEffect(animate ? 1.6 : 0.4)
            .opacity(animate ? 0 : 1)
            .animation(
                .easeOut(duration: 2)
                .repeatForever(autoreverses: false),
                value: animate
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    animate = true
                }
            }
    }
}
