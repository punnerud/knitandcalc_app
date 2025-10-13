//
//  SettingsView.swift
//  KnitAndCalc
//
//  Settings view for language and unit preferences
//

import SwiftUI
import UniformTypeIdentifiers
import StoreKit

struct FileData: Codable {
    let fileName: String
    let base64Data: String
    let mimeType: String
}

struct BackupData: Codable {
    let yarnStash: [YarnStashEntry]
    let projects: [Project]
    let recipes: [Recipe]
    let files: [FileData]?
    let exportDate: Date
    let appVersion: String

    init(yarnStash: [YarnStashEntry], projects: [Project], recipes: [Recipe], files: [FileData]? = nil) {
        self.yarnStash = yarnStash
        self.projects = projects
        self.recipes = recipes
        self.files = files
        self.exportDate = Date()
        self.appVersion = "1.0"
    }
}

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var showLanguageChangeAlert = false
    @State private var pendingLanguage: AppLanguage?
    @State private var showExportSheet = false
    @State private var showImportPicker = false
    @State private var exportedFileURL: URL?
    @State private var showExportSuccess = false
    @State private var showImportSuccess = false
    @State private var showImportError = false
    @State private var importErrorMessage = ""
    @State private var showExportOptions = false
    @State private var includeFiles = true
    @AppStorage("hasRatedApp") private var hasRatedApp = false
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @State private var showNotificationAlert = false

    // Debug menu sequence tracking
    @State private var debugSequence: [String] = []
    @State private var debugSequenceStartTime: Date?
    @State private var showDebugMenu = false

    var body: some View {
        Form {
            Section(header: Text(NSLocalizedString("settings.language.header", comment: ""))) {
                Picker(NSLocalizedString("settings.language.header", comment: ""), selection: Binding(
                    get: { settings.currentLanguage },
                    set: { newLanguage in
                        if newLanguage != settings.currentLanguage {
                            pendingLanguage = newLanguage
                            showLanguageChangeAlert = true
                        }
                    }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            Section(header: Text(NSLocalizedString("settings.units.header", comment: ""))) {
                Picker(NSLocalizedString("settings.units.system", comment: ""), selection: $settings.unitSystem) {
                    ForEach(UnitSystem.allCases, id: \.self) { unit in
                        Text(unit.displayName).tag(unit.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: settings.unitSystem) { newValue in
                    trackDebugSequence("unit:\(newValue)")
                }
            }

            Section(header: Text("Facebook-gruppe")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bli med i KnitAndCalc-gruppen på Facebook")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appText)

                    Text("Del tips, få hjelp og gi tilbakemeldinger til fellesskapet!")
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: {
                        if let url = URL(string: "https://www.facebook.com/groups/knitandcalc/") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.appIconTint)
                            Text("Gå til Facebook-gruppen")
                                .foregroundColor(.appIconTint)
                        }
                    }

                    Text("Skriv \"CalcAndKnit\" for å bli medlem")
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
            }

            if settings.currentLanguage == .norwegian {
                Section(header: Text(NSLocalizedString("Varsler", comment: ""))) {
                    Toggle(isOn: Binding(
                        get: { notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                // Request permission
                                NotificationManager.shared.requestAuthorization { granted in
                                    if granted {
                                        notificationsEnabled = true
                                        trackDebugSequence("notif:on")
                                    } else {
                                        showNotificationAlert = true
                                    }
                                }
                            } else {
                                notificationsEnabled = false
                                trackDebugSequence("notif:off")
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("Påminnelser om strikking (bare for gøy)", comment: ""))
                                .font(.system(size: 15))
                            Text(NSLocalizedString("Får kun varsel hvis appen ikke er brukt på 3 dager", comment: ""))
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                }
            }

            Section(header: Text(NSLocalizedString("Backup", comment: ""))) {
                Button(action: {
                    showExportOptions = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.appIconTint)
                        Text(NSLocalizedString("Eksporter backup", comment: ""))
                            .foregroundColor(.primary)
                    }
                }

                Button(action: {
                    showImportPicker = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.appIconTint)
                        Text(NSLocalizedString("Importer backup", comment: ""))
                            .foregroundColor(.primary)
                    }
                }
            }

            if !hasRatedApp {
                Section(header: Text(NSLocalizedString("Rate denne appen", comment: ""))) {
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("Liker du KnitAndCalc?", comment: ""))
                            .font(.system(size: 15))
                            .foregroundColor(.appText)

                        HStack(spacing: 16) {
                            ForEach(1...5, id: \.self) { rating in
                                Button(action: {
                                    handleRating(rating)
                                }) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appIconTint)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                }
            }

            Section(header: Text(NSLocalizedString("Kontakt", comment: ""))) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("Any questions or feedback?", comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.appText)

                    Button(action: {
                        if let url = URL(string: "mailto:morten@punnerud.net") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.appIconTint)
                            Text("morten@punnerud.net")
                                .foregroundColor(.appIconTint)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if settings.currentLanguage == .norwegian {
                Section(header: Text("Om appen og fremtiden")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prising")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appText)

                        Text("Vi jobber for å holde denne appen rimelig og helst gratis. Skulle vi innføre betaling, vil det aldri koste mer enn 20kr/mnd.")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .padding(.vertical, 4)

                        Text("Fremtidig funksjon: Anonymt søk")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appText)

                        Text("Vi vurderer en funksjon hvor du kan søke anonymt etter garn du mangler. Ditt garnlager forblir privat, men hvis noen mangler ett nøste til et stort prosjekt, kan du motta tilbud om kjøp. Dette kan være en bedre finansieringsmodell for appen.")
                            .font(.system(size: 13))
                            .foregroundColor(.appSecondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("settings.info.title", comment: ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.appSecondaryText)

                    Text(NSLocalizedString("settings.info.description", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.appSecondaryText)
                }
            }
        }
        .navigationTitle(NSLocalizedString("settings.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("settings.language.restart.title", comment: ""), isPresented: $showLanguageChangeAlert) {
            Button(NSLocalizedString("settings.language.restart.cancel", comment: ""), role: .cancel) {
                pendingLanguage = nil
            }
            Button(NSLocalizedString("settings.language.restart.confirm", comment: "")) {
                if let language = pendingLanguage {
                    settings.setLanguage(language)
                }
            }
        } message: {
            Text(NSLocalizedString("settings.language.restart.message", comment: ""))
        }
        .alert(NSLocalizedString("Backup eksportert", comment: ""), isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Backup-filen er lagret og klar til deling", comment: ""))
        }
        .alert(NSLocalizedString("Backup importert", comment: ""), isPresented: $showImportSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Data er importert og appen er oppdatert", comment: ""))
        }
        .alert(NSLocalizedString("Importfeil", comment: ""), isPresented: $showImportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .alert(NSLocalizedString("Varsler deaktivert", comment: ""), isPresented: $showNotificationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(NSLocalizedString("Gå til Innstillinger > KnitAndCalc > Varsler for å aktivere varsler", comment: ""))
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showImportPicker) {
            BackupDocumentPicker(onDocumentPicked: { url in
                importBackup(from: url)
            })
        }
        .alert(NSLocalizedString("Eksporter backup", comment: ""), isPresented: $showExportOptions) {
            Button(NSLocalizedString("Avbryt", comment: ""), role: .cancel) {}
            Button(NSLocalizedString("Med filer", comment: "")) {
                includeFiles = true
                exportBackup()
            }
            Button(NSLocalizedString("Uten filer", comment: "")) {
                includeFiles = false
                exportBackup()
            }
        } message: {
            Text("Vil du inkludere bilder og PDF-filer i backupen? Med filer tar det lengre tid, men sikrer fullstendig backup.")
        }
        .sheet(isPresented: $showDebugMenu) {
            DebugMenuView()
        }
    }

    func handleRating(_ rating: Int) {
        hasRatedApp = true

        if rating <= 4 {
            // Open feedback form
            if let url = URL(string: "https://forms.gle/kbhC6jx9qnRhxsrH6") {
                UIApplication.shared.open(url)
            }
        } else {
            // Request App Store review
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }

    func exportBackup() {
        // Load data from UserDefaults
        var yarnStash: [YarnStashEntry] = []
        var projects: [Project] = []
        var recipes: [Recipe] = []

        if let yarnData = UserDefaults.standard.data(forKey: "savedYarnStash"),
           let decodedYarn = try? JSONDecoder().decode([YarnStashEntry].self, from: yarnData) {
            yarnStash = decodedYarn
        }

        if let projectData = UserDefaults.standard.data(forKey: "savedProjects"),
           let decodedProjects = try? JSONDecoder().decode([Project].self, from: projectData) {
            projects = decodedProjects
        }

        if let recipeData = UserDefaults.standard.data(forKey: "savedRecipes"),
           let decodedRecipes = try? JSONDecoder().decode([Recipe].self, from: recipeData) {
            recipes = decodedRecipes
        }

        // Collect files if requested
        var files: [FileData]? = nil
        if includeFiles {
            files = collectFiles(from: recipes)
        }

        let backup = BackupData(yarnStash: yarnStash, projects: projects, recipes: recipes, files: files)

        // Encode to JSON
        guard let jsonData = try? JSONEncoder().encode(backup) else {
            return
        }

        // Create file in temporary directory
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let dateString = dateFormatter.string(from: Date())
        let fileName = "KnitAndCalc_Backup_\(dateString).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try jsonData.write(to: tempURL)
            exportedFileURL = tempURL
            showExportSheet = true
        } catch {
            print("Export error: \(error)")
        }
    }

    func collectFiles(from recipes: [Recipe]) -> [FileData] {
        var fileDataArray: [FileData] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        for recipe in recipes {
            if recipe.type == .pdf {
                // PDF file
                let fileURL = documentsURL.appendingPathComponent(recipe.content)
                if let data = try? Data(contentsOf: fileURL) {
                    let base64 = data.base64EncodedString()
                    fileDataArray.append(FileData(fileName: recipe.content, base64Data: base64, mimeType: "application/pdf"))
                }
            } else if recipe.type == .images {
                // Image files
                if let imagePathsData = recipe.content.data(using: .utf8),
                   let imagePaths = try? JSONDecoder().decode([String].self, from: imagePathsData) {
                    for imagePath in imagePaths {
                        let fileURL = documentsURL.appendingPathComponent(imagePath)
                        if let data = try? Data(contentsOf: fileURL) {
                            let base64 = data.base64EncodedString()
                            let mimeType = imagePath.lowercased().hasSuffix(".png") ? "image/png" : "image/jpeg"
                            fileDataArray.append(FileData(fileName: imagePath, base64Data: base64, mimeType: mimeType))
                        }
                    }
                }
            }
        }

        return fileDataArray
    }

    func importBackup(from url: URL) {
        do {
            // Access the file
            let accessing = url.startAccessingSecurityScopedResource()
            defer {
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let backup = try JSONDecoder().decode(BackupData.self, from: data)

            // Restore files if included
            if let files = backup.files {
                restoreFiles(files)
            }

            // Save to UserDefaults
            if let yarnData = try? JSONEncoder().encode(backup.yarnStash) {
                UserDefaults.standard.set(yarnData, forKey: "savedYarnStash")
            }

            if let projectData = try? JSONEncoder().encode(backup.projects) {
                UserDefaults.standard.set(projectData, forKey: "savedProjects")
            }

            if let recipeData = try? JSONEncoder().encode(backup.recipes) {
                UserDefaults.standard.set(recipeData, forKey: "savedRecipes")
            }

            showImportSuccess = true
        } catch {
            importErrorMessage = "Kunne ikke lese backup-filen: \(error.localizedDescription)"
            showImportError = true
        }
    }

    func restoreFiles(_ files: [FileData]) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        for fileData in files {
            guard let data = Data(base64Encoded: fileData.base64Data) else { continue }
            let fileURL = documentsURL.appendingPathComponent(fileData.fileName)

            // Create directory if needed
            let directory = fileURL.deletingLastPathComponent()
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

            // Write file
            try? data.write(to: fileURL)
        }
    }

    // MARK: - Debug Sequence Tracking

    func trackDebugSequence(_ action: String) {
        let now = Date()

        // Reset if more than 10 seconds since start
        if let startTime = debugSequenceStartTime {
            if now.timeIntervalSince(startTime) > 10 {
                debugSequence = []
                debugSequenceStartTime = nil
            }
        }

        // Start or continue sequence
        if debugSequenceStartTime == nil {
            debugSequenceStartTime = now
        }

        debugSequence.append(action)

        // Check if sequence matches
        // Metrisk->Imperial, Imperial->Metrisk, Metrisk->Imperial, Imperial->Metrisk,
        // Påminnelser av, Påminnelser på, Metrisk->Imperial, Imperial->Metrisk
        let expectedSequence = [
            "unit:imperial",
            "unit:metric",
            "unit:imperial",
            "unit:metric",
            "notif:off",
            "notif:on",
            "unit:imperial",
            "unit:metric"
        ]

        // Check if we have the correct sequence
        if debugSequence.count >= expectedSequence.count {
            let lastActions = Array(debugSequence.suffix(expectedSequence.count))
            if lastActions == expectedSequence {
                print("Debug menu sequence detected!")
                showDebugMenu = true
                debugSequence = []
                debugSequenceStartTime = nil
            }
        }

        // Cleanup old entries
        if debugSequence.count > 20 {
            debugSequence.removeFirst()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct BackupDocumentPicker: UIViewControllerRepresentable {
    let onDocumentPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void

        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onDocumentPicked(url)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}