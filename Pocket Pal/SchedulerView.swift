import SwiftUI
import Combine

//////////////////////////////////////////////////////////////
// MARK: Scheduler View (BULK CONVERTER ONLY 🔥)
//////////////////////////////////////////////////////////////

struct SchedulerView: View {
    
    @State private var inputText = ""
    @State private var outputText = ""
    
    @State private var fromTimeZone = TimeZone.current.identifier
    @State private var toTimeZone = "America/New_York"
    
    @State private var activePicker: PickerType?
    @State private var copied = false
    @State private var currentTime = Date()
    
    @State private var showTemplates = false
    @State private var savedPresets: [TimezonePreset] = []
    @State private var showPresets = false
    @State private var showQuickConvert = false
    @State private var quickTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    enum PickerType: Identifiable {
        case from, to
        var id: Int { hashValue }
    }
    
    var body: some View {
        
        ZStack {
            
            LinearGradient(
                colors: [.black, Color(red: 0.04, green: 0.05, blue: 0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                
                VStack(spacing: 24) {
                    
                    ////////////////////////////////////////////////////
                    // TITLE & ACTIONS
                    ////////////////////////////////////////////////////
                    
                    HStack {
                        Text("Scheduler")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .purple],
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                        
                        Spacer()
                        
                        // Quick Actions Menu
                        Menu {
                            Button {
                                showQuickConvert = true
                            } label: {
                                Label("Quick Convert", systemImage: "clock.badge.checkmark")
                            }
                            
                            Button {
                                showTemplates = true
                            } label: {
                                Label("Templates", systemImage: "doc.text")
                            }
                            
                            Button {
                                showPresets = true
                            } label: {
                                Label("Saved Presets", systemImage: "star.fill")
                            }
                            
                            Divider()
                            
                            Button {
                                saveCurrentAsPreset()
                            } label: {
                                Label("Save Current Pair", systemImage: "bookmark.fill")
                            }
                            
                            Button {
                                clearAll()
                            } label: {
                                Label("Clear All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    LinearGradient(colors: [.cyan, .purple],
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing)
                                )
                        }
                    }
                    .padding(.top, 20)
                    
                    ////////////////////////////////////////////////////
                    // CLOCKS WITH TIME DIFFERENCE
                    ////////////////////////////////////////////////////
                    
                    VStack(spacing: 16) {
                        HStack(spacing: 20) {
                            clockCard(timeZone: fromTimeZone)
                            clockCard(timeZone: toTimeZone)
                        }
                        
                        // Time difference indicator
                        timeDifferenceView()
                    }
                    
                    ////////////////////////////////////////////////////
                    // TIMEZONE SELECTORS
                    ////////////////////////////////////////////////////
                    
                    HStack(spacing: 12) {
                        
                        Button { activePicker = .from } label: {
                            selector(displayName(fromTimeZone))
                        }
                        
                        Button {
                            withAnimation(.spring()) {
                                swap(&fromTimeZone, &toTimeZone)
                            }
                        } label: {
                            Image(systemName: "arrow.left.arrow.right")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        
                        Button { activePicker = .to } label: {
                            selector(displayName(toTimeZone))
                        }
                    }
                    
                    ////////////////////////////////////////////////////
                    // INPUT BOX WITH ENHANCEMENTS
                    ////////////////////////////////////////////////////
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Paste Schedules")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            // Character count
                            Text("\(inputText.count) chars")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            
                            // Clear button
                            if !inputText.isEmpty {
                                Button {
                                    withAnimation {
                                        inputText = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        
                        ZStack(alignment: .topLeading) {
                            if inputText.isEmpty {
                                Text("Paste your schedule here...\n\nExample:\nMonday Jan 15, 2024\n02:00 PM - 03:00 PM")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.3))
                                    .padding(.top, 8)
                                    .padding(.leading, 14)
                            }
                            
                            TextEditor(text: $inputText)
                                .scrollContentBackground(.hidden)
                                .frame(height: 200)
                                .padding(10)
                                .foregroundColor(.white)
                                .font(.system(.body, design: .monospaced))
                        }
                        .background(glass())
                    }
                    
                    ////////////////////////////////////////////////////
                    // CONVERT BUTTON WITH ANIMATION
                    ////////////////////////////////////////////////////
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            convertBulk()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Convert")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [.green, .mint],
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                    }
                    .disabled(inputText.isEmpty)
                    
                    ////////////////////////////////////////////////////
                    // OUTPUT WITH STATS
                    ////////////////////////////////////////////////////
                    
                    VStack(alignment: .leading, spacing: 12) {
                        
                        HStack {
                            Text("Converted Time")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                            if !outputText.isEmpty && !outputText.contains("⚠️") {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("\(lineCount(outputText) / 2) events")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }
                        }
                        
                        ScrollView {
                            Text(outputText.isEmpty ? "Results will appear here..." : outputText)
                                .font(.system(size: 17, weight: .medium, design: .monospaced))
                                .foregroundColor(outputText.contains("⚠️") ? .orange : .cyan)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 250)
                        .padding()
                        .background(glass())
                    }
                    
                    ////////////////////////////////////////////////////
                    // ACTION BUTTONS
                    ////////////////////////////////////////////////////
                    
                    HStack(spacing: 12) {
                        // Copy button
                        Button {
                            copyToClipboard(outputText)
                            copied = true
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                copied = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                Text(copied ? "Copied ✓" : "Copy")
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(colors: [.cyan, .blue],
                                               startPoint: .leading,
                                               endPoint: .trailing)
                            )
                            .cornerRadius(12)
                            .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(outputText.isEmpty)
                        
                        // Share button
                        Button {
                            shareOutput()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                                .frame(width: 50)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(colors: [.purple, .pink],
                                                   startPoint: .leading,
                                                   endPoint: .trailing)
                                )
                                .cornerRadius(12)
                                .shadow(color: .purple.opacity(0.3), radius: 8, y: 4)
                        }
                        .disabled(outputText.isEmpty)
                    }
                    
                    Spacer().frame(height: 60)
                }
                .padding(.horizontal, 20)
            }
        }
        .onReceive(timer) { _ in currentTime = Date() }
        
        //////////////////////////////////////////////////////////
        // SHEETS
        //////////////////////////////////////////////////////////
        
        .sheet(isPresented: $showTemplates) {
            TemplatesView { template in
                inputText = template
                showTemplates = false
            }
        }
        
        .sheet(isPresented: $showPresets) {
            PresetsView(presets: $savedPresets) { preset in
                fromTimeZone = preset.fromZone
                toTimeZone = preset.toZone
                showPresets = false
            }
        }
        
        .sheet(isPresented: $showQuickConvert) {
            QuickConvertView(
                fromZone: fromTimeZone,
                toZone: toTimeZone,
                selectedTime: $quickTime
            )
        }
        
        //////////////////////////////////////////////////////////
        // TIMEZONE PICKER
        //////////////////////////////////////////////////////////
        
        .sheet(item: $activePicker) { picker in
            TimezonePicker(
                selectedZone: Binding(
                    get: { picker == .from ? fromTimeZone : toTimeZone },
                    set: {
                        if picker == .from { fromTimeZone = $0 }
                        else { toTimeZone = $0 }
                    }
                )
            )
        }
    }
    
    //////////////////////////////////////////////////////////
    // BULK CONVERSION
    //////////////////////////////////////////////////////////
    
    func convertBulk() {
        
        guard let fromTZ = TimeZone(identifier: fromTimeZone),
              let toTZ = TimeZone(identifier: toTimeZone) else {
            outputText = "Invalid Timezone"
            return
        }
        
        let lines = inputText
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        var result = ""
        
        ////////////////////////////////////////////////////
        // 🔥 FIXED PARSER (iOS SAFE)
        ////////////////////////////////////////////////////
        
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX") // 🔥 REQUIRED
        parser.timeZone = fromTZ
        
        let dateFormats = [
            "EEEE MMM d, yyyy hh:mm a",
            "EEEE MMM dd, yyyy hh:mm a"
        ]
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEEE MMM d, yyyy"
        dateFormatter.timeZone = toTZ
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")
        timeFormatter.dateFormat = "hh:mm a"
        timeFormatter.timeZone = toTZ
        
        let tzFormatter = DateFormatter()
        tzFormatter.locale = Locale(identifier: "en_US_POSIX")
        tzFormatter.dateFormat = "zzzz"
        tzFormatter.timeZone = toTZ
        
        var i = 0
        
        while i < lines.count - 1 {
            
            let dateLine = lines[i]
            let timeLine = lines[i + 1]
            
            let parts = timeLine.components(separatedBy: " - ")
            if parts.count < 2 {
                i += 1
                continue
            }
            
            let start = parts[0]
            let end = parts[1]
                .components(separatedBy: " ")
                .prefix(2)
                .joined(separator: " ")
            
            ////////////////////////////////////////////////////
            // 🔥 FLEXIBLE PARSING
            ////////////////////////////////////////////////////
            
            var startDate: Date? = nil
            var endDate: Date? = nil
            
            for format in dateFormats {
                parser.dateFormat = format
                
                if startDate == nil {
                    startDate = parser.date(from: "\(dateLine) \(start)")
                }
                
                if endDate == nil {
                    endDate = parser.date(from: "\(dateLine) \(end)")
                }
            }
            
            guard let s = startDate, let e = endDate else {
                i += 2
                continue
            }
            
            ////////////////////////////////////////////////////
            // OUTPUT
            ////////////////////////////////////////////////////
            
            result += """
    \(dateFormatter.string(from: s))
    \(timeFormatter.string(from: s)) - \(timeFormatter.string(from: e)) \(tzFormatter.string(from: s))

    """
            
            i += 2
        }
        
        outputText = result.isEmpty ? "⚠️ Could not parse schedule. Check format." : result
    }
    
    //////////////////////////////////////////////////////////
    // HELPERS
    //////////////////////////////////////////////////////////
    
    func clockCard(timeZone: String) -> some View {
        
        let tz = TimeZone(identifier: timeZone) ?? .current
        
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.timeZone = tz
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeZone = tz
        
        return VStack(spacing: 8) {
            Text(displayName(timeZone))
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Text(formatter.string(from: currentTime))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(dateFormatter.string(from: currentTime))
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding()
        .frame(width: 160)
        .background(
            ZStack {
                glass()
                LinearGradient(
                    colors: [.cyan.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
    }
    
    func timeDifferenceView() -> some View {
        let fromTZ = TimeZone(identifier: fromTimeZone) ?? .current
        let toTZ = TimeZone(identifier: toTimeZone) ?? .current
        
        let fromOffset = fromTZ.secondsFromGMT()
        let toOffset = toTZ.secondsFromGMT()
        let difference = (toOffset - fromOffset) / 3600
        
        let sign = difference >= 0 ? "+" : ""
        let hourText = abs(difference) == 1 ? "hour" : "hours"
        
        return HStack(spacing: 6) {
            Image(systemName: "clock.arrow.2.circlepath")
                .font(.caption)
            Text("\(sign)\(difference) \(hourText)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.cyan)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.cyan.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func displayName(_ id: String) -> String {
        if let tz = TimeZone(identifier: id) {
            let formatter = DateFormatter()
            formatter.timeZone = tz
            formatter.dateFormat = "zzzz"
            return formatter.string(from: Date())
        }
        return id
    }
    
    func selector(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
    }
    
    func glass() -> some View {
        Color.white.opacity(0.06)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
    }
    
    func copyToClipboard(_ text: String) {
#if os(iOS)
        UIPasteboard.general.string = text
#else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
    }
    
    func shareOutput() {
#if os(iOS)
        let activityVC = UIActivityViewController(
            activityItems: [outputText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
#endif
    }
    
    func lineCount(_ text: String) -> Int {
        return text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
    }
    
    func saveCurrentAsPreset() {
        let preset = TimezonePreset(
            name: "\(displayName(fromTimeZone)) → \(displayName(toTimeZone))",
            fromZone: fromTimeZone,
            toZone: toTimeZone
        )
        if !savedPresets.contains(where: { $0.id == preset.id }) {
            savedPresets.append(preset)
        }
    }
    
    func clearAll() {
        withAnimation {
            inputText = ""
            outputText = ""
        }
    }
}

//////////////////////////////////////////////////////////////
// MARK: TIMEZONE PRESET MODEL
//////////////////////////////////////////////////////////////

struct TimezonePreset: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let fromZone: String
    let toZone: String
}

//////////////////////////////////////////////////////////////
// MARK: TEMPLATES VIEW
//////////////////////////////////////////////////////////////

struct TemplatesView: View {
    @Environment(\.dismiss) var dismiss
    let onSelect: (String) -> Void
    
    let templates = [
        Template(
            name: "Standard Meeting",
            example: """
            Monday Jan 15, 2024
            02:00 PM - 03:00 PM
            """
        ),
        Template(
            name: "Full Day Schedule",
            example: """
            Monday Jan 15, 2024
            09:00 AM - 10:00 AM
            10:30 AM - 11:30 AM
            02:00 PM - 03:00 PM
            """
        ),
        Template(
            name: "Multi-Day",
            example: """
            Monday Jan 15, 2024
            02:00 PM - 03:00 PM
            Tuesday Jan 16, 2024
            09:00 AM - 10:00 AM
            """
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(templates) { template in
                            Button {
                                onSelect(template.example)
                            } label: {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(template.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.cyan)
                                    }
                                    
                                    Text(template.example)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle("Templates")
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

struct Template: Identifiable {
    let id = UUID()
    let name: String
    let example: String
}

//////////////////////////////////////////////////////////////
// MARK: PRESETS VIEW
//////////////////////////////////////////////////////////////

struct PresetsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var presets: [TimezonePreset]
    let onSelect: (TimezonePreset) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if presets.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.cyan.opacity(0.3))
                        Text("No Saved Presets")
                            .foregroundColor(.white.opacity(0.6))
                        Text("Save timezone pairs from the menu")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(presets) { preset in
                                Button {
                                    onSelect(preset)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.name)
                                                .font(.subheadline)
                                                .foregroundColor(.white)
                                            
                                            Text("\(preset.fromZone) → \(preset.toZone)")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        
                                        Spacer()
                                        
                                        Button {
                                            withAnimation {
                                                presets.removeAll { $0.id == preset.id }
                                            }
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)
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
            .navigationTitle("Saved Presets")
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
// MARK: QUICK CONVERT VIEW
//////////////////////////////////////////////////////////////

struct QuickConvertView: View {
    @Environment(\.dismiss) var dismiss
    let fromZone: String
    let toZone: String
    @Binding var selectedTime: Date
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    
                    // Time Picker
                    DatePicker(
                        "Select Time",
                        selection: $selectedTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.graphical)
                    .colorScheme(.dark)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                    )
                    
                    // Conversion Result
                    VStack(spacing: 16) {
                        conversionCard(
                            title: "From",
                            time: selectedTime,
                            zone: fromZone
                        )
                        
                        Image(systemName: "arrow.down")
                            .foregroundColor(.cyan)
                            .font(.title2)
                        
                        conversionCard(
                            title: "To",
                            time: selectedTime,
                            zone: toZone
                        )
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Quick Convert")
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
    
    func conversionCard(title: String, time: Date, zone: String) -> some View {
        let tz = TimeZone(identifier: zone) ?? .current
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.timeZone = tz
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeZone = tz
        
        return VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
            
            Text(timeFormatter.string(from: time))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
            
            Text(dateFormatter.string(from: time))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(displayZoneName(zone))
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    func displayZoneName(_ id: String) -> String {
        if let tz = TimeZone(identifier: id) {
            let formatter = DateFormatter()
            formatter.timeZone = tz
            formatter.dateFormat = "zzzz"
            return formatter.string(from: Date())
        }
        return id
    }
}

//////////////////////////////////////////////////////////////
// MARK: TIMEZONE PICKER (FIXED + POPULATING ✅)
//////////////////////////////////////////////////////////////

struct TimezonePicker: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var selectedZone: String
    
    @State private var search = ""
    
    let zones = TimeZone.knownTimeZoneIdentifiers.sorted()
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 12) {
                
                HStack {
                    TextField("Search timezone...", text: $search)
                        .foregroundColor(.white)
                    
                    if !search.isEmpty {
                        Button {
                            search = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 10) {
                        
                        ForEach(filteredZones, id: \.self) { zoneID in
                            
                            if let tz = TimeZone(identifier: zoneID) {
                                
                                Button {
                                    selectedZone = zoneID
                                    dismiss()
                                } label: {
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        
                                        Text(format(tz))
                                            .foregroundColor(.white)
                                        
                                        Text(gmtOffset(tz))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxHeight: 350)
                
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Select Timezone")
            
            .toolbar {
                ToolbarItem {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    var filteredZones: [String] {
        
        if search.isEmpty {
            return Array(zones.prefix(100))
        }
        
        return zones.filter { id in
            guard let tz = TimeZone(identifier: id) else { return false }
            return format(tz).lowercased().contains(search.lowercased())
        }
    }
    
    func format(_ zone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.dateFormat = "zzzz"
        return formatter.string(from: Date())
    }
    
    func gmtOffset(_ zone: TimeZone) -> String {
        let seconds = zone.secondsFromGMT()
        let hours = seconds / 3600
        return "GMT\(hours >= 0 ? "+" : "")\(hours)"
    }
}

#Preview {
    SchedulerView()
}
