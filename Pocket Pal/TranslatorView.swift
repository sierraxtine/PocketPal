import SwiftUI
import AVFoundation

// Extracted to reduce type-checking complexity
private struct AnimatedGradientBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.2, blue: 0.8),
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.1, green: 0.6, blue: 0.8),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [
                    Color.cyan.opacity(0.2),
                    Color.purple.opacity(0.15),
                    Color.blue.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
        .ignoresSafeArea()
    }
}

private struct LanguageSelector: View {
    @Binding var sourceLang: String
    @Binding var targetLang: String
    @Binding var autoDetect: Bool
    let languages: [String: String]
    let languageFlags: [String: String]
    let loading: Bool
    let swapAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Source Language
            VStack(spacing: 8) {
                Text(languageFlags[sourceLang] ?? "🌐")
                    .font(.system(size: 32))
                Menu {
                    ForEach(languages.keys.sorted(), id: \.self) { lang in
                        Button {
                            sourceLang = lang
                            autoDetect = (lang == "Auto Detect")
                        } label: {
                            Label { Text(lang) } icon: { Text(languageFlags[lang] ?? "") }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(sourceLang)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .frame(maxWidth: .infinity)

            // Swap Button
            Button(action: swapAction) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(Color.cyan.opacity(0.1)))
                    .rotationEffect(.degrees(loading ? 360 : 0))
                    .animation(loading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: loading)
            }

            // Target Language
            VStack(spacing: 8) {
                Text(languageFlags[targetLang] ?? "🌐")
                    .font(.system(size: 32))

                Menu {
                    ForEach(languages.keys.sorted().filter { $0 != "Auto Detect" }, id: \.self) { lang in
                        Button { targetLang = lang } label: {
                            Label { Text(lang) } icon: { Text(languageFlags[lang] ?? "") }
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(targetLang)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .cyan.opacity(0.15), radius: 10)
        )
    }
}

struct TranslatorView: View {
    
    //////////////////////////////////////////////////////////
    // MARK: State
    //////////////////////////////////////////////////////////
    
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    
    @State private var sourceLang: String = "English"
    @State private var targetLang: String = "Spanish"
    
    @State private var loading = false
    @State private var autoDetect = false
    @State private var detectedLanguage: String = ""
    
    @State private var showHistory = false
    @State private var showFavorites = false
    @State private var conversationMode = false
    
    @State private var recentTranslations: [Translation] = []
    @State private var favoriteTranslations: [Translation] = []
    
    @State private var characterCount: Int = 0
    
    @AppStorage("speechRates") private var speechRatesData: Data = Data()
    @AppStorage("speechPitches") private var speechPitchesData: Data = Data()
    @State private var currentVoiceDescription: String = ""
    
    private var speechRates: [String: Float] {
        get { (try? JSONDecoder().decode([String: Float].self, from: speechRatesData)) ?? [:] }
        set { speechRatesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    private var speechPitches: [String: Float] {
        get { (try? JSONDecoder().decode([String: Float].self, from: speechPitchesData)) ?? [:] }
        set { speechPitchesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    private var currentRate: Float { speechRates[languages[targetLang] ?? "default"] ?? 0.5 }
    private var currentPitch: Float { speechPitches[languages[targetLang] ?? "default"] ?? 1.0 }
    
    private func getSpeechRates() -> [String: Float] {
        (try? JSONDecoder().decode([String: Float].self, from: speechRatesData)) ?? [:]
    }

    private func setSpeechRate(for key: String, value: Float) {
        var rates = getSpeechRates()
        rates[key] = value
        if let data = try? JSONEncoder().encode(rates) {
            speechRatesData = data
        }
    }

    private func getSpeechPitches() -> [String: Float] {
        (try? JSONDecoder().decode([String: Float].self, from: speechPitchesData)) ?? [:]
    }

    private func setSpeechPitch(for key: String, value: Float) {
        var pitches = getSpeechPitches()
        pitches[key] = value
        if let data = try? JSONEncoder().encode(pitches) {
            speechPitchesData = data
        }
    }
    
    @FocusState private var keyboardOpen: Bool
    
    private let speechSynth = AVSpeechSynthesizer()
    
    //////////////////////////////////////////////////////////
    // MARK: Languages
    //////////////////////////////////////////////////////////
    
    let languages: [String:String] = [
        "Auto Detect":"auto",
        "English":"en",
        "Spanish":"es",
        "French":"fr",
        "German":"de",
        "Italian":"it",
        "Portuguese":"pt",
        "Dutch":"nl",
        "Russian":"ru",
        "Japanese":"ja",
        "Chinese (Simplified)":"zh-CN",
        "Chinese (Traditional)":"zh-TW",
        "Korean":"ko",
        "Arabic":"ar",
        "Hindi":"hi",
        "Turkish":"tr",
        "Polish":"pl",
        "Swedish":"sv",
        "Danish":"da",
        "Norwegian":"no",
        "Finnish":"fi",
        "Greek":"el",
        "Czech":"cs",
        "Hungarian":"hu",
        "Romanian":"ro",
        "Thai":"th",
        "Vietnamese":"vi",
        "Indonesian":"id",
        "Malay":"ms",
        "Hebrew":"he"
    ]
    
    let languageFlags: [String:String] = [
        "Auto Detect":"🌐",
        "English":"🇬🇧",
        "Spanish":"🇪🇸",
        "French":"🇫🇷",
        "German":"🇩🇪",
        "Italian":"🇮🇹",
        "Portuguese":"🇵🇹",
        "Dutch":"🇳🇱",
        "Russian":"🇷🇺",
        "Japanese":"🇯🇵",
        "Chinese (Simplified)":"🇨🇳",
        "Chinese (Traditional)":"🇹🇼",
        "Korean":"🇰🇷",
        "Arabic":"🇸🇦",
        "Hindi":"🇮🇳",
        "Turkish":"🇹🇷",
        "Polish":"🇵🇱",
        "Swedish":"🇸🇪",
        "Danish":"🇩🇰",
        "Norwegian":"🇳🇴",
        "Finnish":"🇫🇮",
        "Greek":"🇬🇷",
        "Czech":"🇨🇿",
        "Hungarian":"🇭🇺",
        "Romanian":"🇷🇴",
        "Thai":"🇹🇭",
        "Vietnamese":"🇻🇳",
        "Indonesian":"🇮🇩",
        "Malay":"🇲🇾",
        "Hebrew":"🇮🇱"
    ]
    
    //////////////////////////////////////////////////////////
    // MARK: UI
    //////////////////////////////////////////////////////////
    
    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            StarfieldBackground()
                .ignoresSafeArea()
                .onTapGesture { keyboardOpen = false }
            ScrollView { mainContent }
                .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showHistory) { historySheet }
        .sheet(isPresented: $showFavorites) { favoritesSheet }
        .onAppear { currentVoiceDescription = "" }
    }
    
    @ViewBuilder private var mainContent: some View {
        VStack(spacing: 24) {
            headerSection
            conversationToggle
            languageSelectorSection
            speechControlsSection
            inputSection
            translateButton
            resultSection
            Spacer(minLength: 40)
        }
    }
    
    @ViewBuilder private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Translator")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if !detectedLanguage.isEmpty {
                    Text("Detected: \(detectedLanguage)")
                        .font(.system(size: 12))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }
            
            Spacer()
            
            // History & Favorites buttons
            HStack(spacing: 12) {
                
                Button {
                    showHistory.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                        Text("History")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                Button {
                    showFavorites.toggle()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                        Text("Saved")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.yellow)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    @ViewBuilder private var conversationToggle: some View {
        Toggle(isOn: $conversationMode) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.cyan)
                Text("Conversation Mode")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
            }
        }
        .tint(.cyan)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder private var languageSelectorSection: some View {
        VStack(spacing: 0) {
            LanguageSelector(
                sourceLang: $sourceLang,
                targetLang: $targetLang,
                autoDetect: $autoDetect,
                languages: languages,
                languageFlags: languageFlags,
                loading: loading,
                swapAction: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        swapLanguages()
                    }
                }
            )
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder private var speechControlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speedometer")
                    .foregroundColor(.cyan)
                Text("Speech Controls")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                Spacer()
                if !currentVoiceDescription.isEmpty {
                    Text(currentVoiceDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Rate Slider
            VStack(alignment: .leading) {
                HStack {
                    Text("Rate")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(String(format: "%.2f", currentRate))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Slider(value: Binding(
                    get: { Double(currentRate) },
                    set: { newVal in
                        let key = languages[targetLang] ?? "default"
                        setSpeechRate(for: key, value: Float(newVal))
                    }
                ), in: 0.3...0.7)
                .tint(.cyan)
            }

            // Pitch Slider
            VStack(alignment: .leading) {
                HStack {
                    Text("Pitch")
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(String(format: "%.2f", currentPitch))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Slider(value: Binding(
                    get: { Double(currentPitch) },
                    set: { newVal in
                        let key = languages[targetLang] ?? "default"
                        setSpeechPitch(for: key, value: Float(newVal))
                    }
                ), in: 0.5...1.5)
                .tint(.cyan)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            HStack {
                Text("Enter Text")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("\(characterCount) / 5000")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(characterCount > 4500 ? .red : .white.opacity(0.5))
                
                if !inputText.isEmpty {
                    Button {
                        withAnimation {
                            inputText = ""
                            translatedText = ""
                            characterCount = 0
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            ZStack(alignment: .topLeading) {
                
                if inputText.isEmpty {
                    Text("Type or paste text to translate...")
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $inputText)
                    .frame(height: 140)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .foregroundColor(.white)
                    .focused($keyboardOpen)
                    .onChange(of: inputText) { newValue in
                        characterCount = newValue.count
                        if newValue.count > 5000 {
                            inputText = String(newValue.prefix(5000))
                        }
                    }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
            )
            
            // Quick Actions for Input
            HStack(spacing: 12) {
                
                Button {
                    speakInput()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speaker.wave.2")
                        Text("Listen")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.15))
                    )
                }
                .disabled(inputText.isEmpty)
                
                Button {
                    pasteFromClipboard()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste")
                    }
                    .font(.system(size: 13))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.15))
                    )
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
    
    @ViewBuilder private var translateButton: some View {
        Button {
            translate()
        } label: {
            
            HStack(spacing: 12) {
                
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18))
                }
                
                Text(loading ? "Translating..." : "Translate")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: inputText.isEmpty ? [.gray.opacity(0.5)] : [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: inputText.isEmpty ? .clear : .cyan.opacity(0.4), radius: 15, y: 5)
            )
        }
        .disabled(inputText.isEmpty || loading)
        .padding(.horizontal)
    }
    
    @ViewBuilder private var resultSection: some View {
        if !translatedText.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Text("Translation")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    // Favorite button
                    Button {
                        addToFavorites()
                    } label: {
                        Image(systemName: isFavorited() ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 18))
                    }
                }
                
                Text(translatedText)
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .medium))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(0.3))
                    )
                
                // Action Buttons
                HStack(spacing: 16) {
                    
                    Button {
                        speak()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 22))
                            Text("Speak")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cyan.opacity(0.1))
                        )
                    }
                    
                    Button {
                        copy()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 22))
                            Text("Copy")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    Button {
                        share()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up.fill")
                                .font(.system(size: 22))
                            Text("Share")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.1),
                                Color.cyan.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .green.opacity(0.2), radius: 15)
            )
            .padding(.horizontal)
            .transition(.scale.combined(with: .opacity))
        }
    }
    
    @ViewBuilder private var historySheet: some View {
        HistoryView(translations: recentTranslations) { translation in
            inputText = translation.original
            translatedText = translation.translated
            sourceLang = translation.sourceLang
            targetLang = translation.targetLang
        }
    }

    @ViewBuilder private var favoritesSheet: some View {
        FavoritesView(favorites: $favoriteTranslations) { translation in
            inputText = translation.original
            translatedText = translation.translated
            sourceLang = translation.sourceLang
            targetLang = translation.targetLang
        }
    }
    
    //////////////////////////////////////////////////////////
    // MARK: Translation Engine
    //////////////////////////////////////////////////////////
    
    func translate() {
        
        keyboardOpen = false
        
        // Resolve language codes and prefer auto-detect when needed
        let resolvedSource = languages[sourceLang] ?? "auto"
        let resolvedTarget = languages[targetLang] ?? "en"
        
        // If source and target resolve to the same code (or source is empty), force auto-detect
        let sl = (resolvedSource == resolvedTarget || resolvedSource.isEmpty) ? "auto" : resolvedSource
        let tl = resolvedTarget
        
        // Don't attempt if input is empty
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        loading = true
        
        let encoded = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        let urlString =
        "https://translate.googleapis.com/translate_a/single?client=gtx&sl=\(sl)&tl=\(tl)&dt=t&ie=UTF-8&oe=UTF-8&q=\(encoded)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                loading = false
            }
            guard let data = data else { return }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [Any] {
                    // Parse translation segments
                    var fullTranslation = ""
                    if let first = json.first as? [Any] {
                        for item in first {
                            if let seg = item as? [Any], let piece = seg.first as? String {
                                fullTranslation += piece
                            }
                        }
                    }
                    // Parse detected language if available (index 2 in the array)
                    var detected: String = ""
                    if json.count > 2, let detectedCode = json[2] as? String {
                        detected = detectedCode
                    }
                    DispatchQueue.main.async {
                        withAnimation {
                            translatedText = fullTranslation
                        }
                        // Update detected language label if we have a mapping
                        if !detected.isEmpty {
                            // Try to map detected code back to a display name
                            if let match = languages.first(where: { $0.value.hasPrefix(detected) })?.key {
                                detectedLanguage = match
                            } else {
                                detectedLanguage = detected
                            }
                        } else {
                            detectedLanguage = ""
                        }
                        // Add to history
                        addToHistory()
                    }
                }
            } catch {
                print("Translation error:", error)
            }
        }.resume()
    }
    
    //////////////////////////////////////////////////////////
    // MARK: Helpers
    //////////////////////////////////////////////////////////
    
    func swapLanguages() {
        if sourceLang != "Auto Detect" {
            let temp = sourceLang
            sourceLang = targetLang
            targetLang = temp
            
            // Also swap texts if in conversation mode
            if conversationMode && !translatedText.isEmpty {
                let tempText = inputText
                inputText = translatedText
                translatedText = tempText
            }
        }
    }
    
    func speak() {
        guard !translatedText.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: translatedText)
        let desiredCode = languages[targetLang]
        var selectedVoice: AVSpeechSynthesisVoice? = nil
        if let code = desiredCode, let voice = AVSpeechSynthesisVoice(language: code) {
            selectedVoice = voice
        } else if let current = AVSpeechSynthesisVoice(language: Locale.current.identifier) {
            selectedVoice = current
        } else {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
        if let v = selectedVoice { utterance.voice = v }
        
        utterance.rate = currentRate
        utterance.pitchMultiplier = currentPitch
        
        if let v = utterance.voice {
            currentVoiceDescription = "Voice: \(v.name) (\(v.language))"
        } else {
            currentVoiceDescription = ""
        }
        
        speechSynth.speak(utterance)
        // If you have speechState (not shown in this snippet), use speechState.isSpeaking = true here
    }
    
    func speakInput() {
        guard !inputText.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: inputText)
        let desiredCode = languages[sourceLang]
        var selectedVoice: AVSpeechSynthesisVoice? = nil
        if let code = desiredCode {
            let langCode = (code == "auto") ? "en" : code
            if let voice = AVSpeechSynthesisVoice(language: langCode) {
                selectedVoice = voice
            }
        }
        if selectedVoice == nil, let current = AVSpeechSynthesisVoice(language: Locale.current.identifier) {
            selectedVoice = current
        }
        if selectedVoice == nil {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-US")
        }
        if let v = selectedVoice { utterance.voice = v }
        
        utterance.rate = currentRate
        utterance.pitchMultiplier = currentPitch
        
        if let v = utterance.voice {
            currentVoiceDescription = "Voice: \(v.name) (\(v.language))"
        } else {
            currentVoiceDescription = ""
        }
        
        speechSynth.speak(utterance)
        // If you have speechState (not shown in this snippet), use speechState.isSpeaking = true here
    }
    
    func copy() {
        #if os(iOS)
        UIPasteboard.general.string = translatedText
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType:.string)
        #endif
    }
    
    func pasteFromClipboard() {
        #if os(iOS)
        if let clipboardText = UIPasteboard.general.string {
            inputText = clipboardText
        }
        #elseif os(macOS)
        if let clipboardText = NSPasteboard.general.string(forType: .string) {
            inputText = clipboardText
        }
        #endif
    }
    
    func share() {
        #if os(iOS)
        let activityVC = UIActivityViewController(
            activityItems: [translatedText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        #endif
    }
    
    func addToHistory() {
        let translation = Translation(
            id: UUID(),
            original: inputText,
            translated: translatedText,
            sourceLang: sourceLang,
            targetLang: targetLang,
            timestamp: Date()
        )
        
        recentTranslations.insert(translation, at: 0)
        
        // Keep only last 50 translations
        if recentTranslations.count > 50 {
            recentTranslations = Array(recentTranslations.prefix(50))
        }
    }
    
    func addToFavorites() {
        let translation = Translation(
            id: UUID(),
            original: inputText,
            translated: translatedText,
            sourceLang: sourceLang,
            targetLang: targetLang,
            timestamp: Date()
        )
        
        // Check if already favorited
        if !favoriteTranslations.contains(where: {
            $0.original == translation.original &&
            $0.translated == translation.translated
        }) {
            favoriteTranslations.insert(translation, at: 0)
        }
    }
    
    func isFavorited() -> Bool {
        favoriteTranslations.contains(where: {
            $0.original == inputText &&
            $0.translated == translatedText
        })
    }
}

//////////////////////////////////////////////////////////
// MARK: Translation Model
//////////////////////////////////////////////////////////

struct Translation: Identifiable, Codable {
    let id: UUID
    let original: String
    let translated: String
    let sourceLang: String
    let targetLang: String
    let timestamp: Date
}

//////////////////////////////////////////////////////////
// MARK: History View
//////////////////////////////////////////////////////////

struct HistoryView: View {
    
    @Environment(\.dismiss) var dismiss
    let translations: [Translation]
    let onSelect: (Translation) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if translations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No translation history")
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(translations) { translation in
                                Button {
                                    onSelect(translation)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(translation.sourceLang)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.cyan)
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 10))
                                                .foregroundColor(.white.opacity(0.5))
                                            Text(translation.targetLang)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.green)
                                            Spacer()
                                            Text(translation.timestamp, style: .relative)
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                        
                                        Text(translation.original)
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                            .lineLimit(2)
                                        
                                        Text(translation.translated)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.cyan.opacity(0.8))
                                            .lineLimit(2)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
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
            .navigationTitle("Translation History")
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

//////////////////////////////////////////////////////////
// MARK: Favorites View
//////////////////////////////////////////////////////////

struct FavoritesView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var favorites: [Translation]
    let onSelect: (Translation) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if favorites.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.yellow.opacity(0.3))
                        Text("No saved translations")
                            .foregroundColor(.white.opacity(0.6))
                        Text("Tap the star icon to save translations")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(favorites) { translation in
                                Button {
                                    onSelect(translation)
                                    dismiss()
                                } label: {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text(translation.sourceLang)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.cyan)
                                                Image(systemName: "arrow.right")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.white.opacity(0.5))
                                                Text(translation.targetLang)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.green)
                                            }
                                            
                                            Text(translation.original)
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                                .lineLimit(2)
                                            
                                            Text(translation.translated)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.cyan.opacity(0.8))
                                                .lineLimit(2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Button {
                                            withAnimation {
                                                favorites.removeAll { $0.id == translation.id }
                                            }
                                        } label: {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
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
            .navigationTitle("Saved Translations")
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
