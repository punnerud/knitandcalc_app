//
//  ProjectDetailView.swift
//  KnitAndCalc
//
//  Project detail view
//

import SwiftUI

enum NeedleSize: String, CaseIterable {
    case none = ""
    case size1 = "1"
    case size1_5 = "1,5"
    case size2 = "2"
    case size2_5 = "2,5"
    case size3 = "3"
    case size3_5 = "3,5"
    case size4 = "4"
    case size4_5 = "4,5"
    case size5 = "5"
    case size5_5 = "5,5"
    case size6 = "6"
    case size6_5 = "6,5"
    case size7 = "7"
    case size7_5 = "7,5"
    case size8 = "8"
    case size8_5 = "8,5"
    case size9 = "9"
    case size9_5 = "9,5"
    case size10 = "10"
    case other = "Annet"

    var displayName: String {
        return self.rawValue
    }
}

struct ProjectDetailView: View {
    let projectId: UUID
    @Binding var projects: [Project]
    let recipes: [Recipe]

    @ObservedObject private var settings = AppSettings.shared
    @State private var yarnEntries: [YarnStashEntry] = []
    @State private var showRecipePicker: Bool = false
    @State private var showAddYarn: Bool = false
    @State private var counterToDelete: RowCounter?
    @State private var yarnToDelete: ProjectYarn?
    @State private var selectedNeedleSize: NeedleSize = .none
    @State private var customNeedleSize: String = ""
    @State private var showCustomNeedleInput: Bool = false
    @FocusState private var isCustomNeedleSizeFocused: Bool
    @State private var showDeleteConfirmation: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var selectedImages: [UIImage] = []
    @State private var imageToDelete: String?
    @State private var showImageGallery: Bool = false
    @State private var selectedImageIndex: Int = 0
    @Environment(\.dismiss) var dismiss

    var project: Project {
        projects.first { $0.id == projectId } ?? Project(name: "")
    }

    var linkedRecipe: Recipe? {
        if let recipeId = project.recipeId {
            return recipes.first { $0.id == recipeId }
        }
        return nil
    }

    var projectIndex: Int? {
        projects.firstIndex { $0.id == projectId }
    }

    var body: some View {
        mainForm
            .navigationTitle(project.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lagre") {
                        dismiss()
                    }
                    .foregroundColor(.appIconTint)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Ferdig") {
                        hideKeyboard()
                    }
                }
            }
            .sheet(isPresented: $showRecipePicker) {
                RecipePickerView(selectedRecipeId: Binding(
                    get: { project.recipeId },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].recipeId = newValue
                        }
                    }
                ), recipes: recipes)
            }
            .alert("Slett teller", isPresented: .constant(counterToDelete != nil), presenting: counterToDelete) { counter in
                Button("Avbryt", role: .cancel) {
                    counterToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    if let index = projectIndex,
                       let counterIndex = projects[index].rowCounters.firstIndex(where: { $0.id == counter.id }) {
                        projects[index].rowCounters.remove(at: counterIndex)
                    }
                    counterToDelete = nil
                }
            } message: { counter in
                Text("Er du sikker på at du vil slette \"\(counter.name)\"?")
            }
            .alert("Slett garn", isPresented: .constant(yarnToDelete != nil), presenting: yarnToDelete) { yarn in
                Button("Avbryt", role: .cancel) {
                    yarnToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    if let index = projectIndex,
                       let yarnIndex = projects[index].linkedYarns.firstIndex(where: { $0.id == yarn.id }) {
                        projects[index].linkedYarns.remove(at: yarnIndex)
                    }
                    yarnToDelete = nil
                }
            } message: { yarn in
                if let yarnEntry = yarnEntries.first(where: { $0.id == yarn.yarnStashId }) {
                    Text("Er du sikker på at du vil fjerne \"\(yarnEntry.brand) \(yarnEntry.type)\"?")
                } else {
                    Text("Er du sikker på at du vil fjerne dette garnet?")
                }
            }
            .sheet(isPresented: $showAddYarn) {
                AddProjectYarnView(projects: $projects, projectId: projectId)
            }
            .sheet(isPresented: $showImagePicker, onDismiss: {
                handleNewImages(selectedImages)
            }) {
                ImagePicker(images: $selectedImages)
            }
            .alert("Slett bilde", isPresented: .constant(imageToDelete != nil), presenting: imageToDelete) { imagePath in
                Button("Avbryt", role: .cancel) {
                    imageToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    deleteImage(imagePath)
                }
            } message: { _ in
                Text("Er du sikker på at du vil slette dette bildet?")
            }
            .alert("Slett prosjekt", isPresented: $showDeleteConfirmation) {
                Button("Avbryt", role: .cancel) {}
                Button("Slett", role: .destructive) {
                    deleteProject()
                }
            } message: {
                Text("Er du sikker på at du vil slette \"\(project.name)\"?\n\nTips: Du kan også trekke til venstre på oversikten for å redigere eller slette. Det er raskere enn å bruke denne knappen.")
            }
            .onAppear {
                loadYarnEntries()
            }
    }

    var mainForm: some View {
        Form {
            Group {
            Section(header: Text("Status")) {
                Picker("Status", selection: Binding(
                    get: { project.status },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].status = newValue
                        }
                    }
                )) {
                    ForEach(ProjectStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
            }

            Section(header: Text("Oppskrift")) {
                if let recipe = linkedRecipe {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.system(size: 16, weight: .medium))
                            Text(recipe.displayCategory)
                                .font(.system(size: 13))
                                .foregroundColor(.appSecondaryText)
                        }

                        Spacer()

                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            EmptyView()
                        }
                    }

                    Button(action: { showRecipePicker = true }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.appIconTint)
                            Text("Bytt oppskrift")
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    Button(action: { showRecipePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.appIconTint)
                            Text("Legg til oppskrift")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }

            Section(header: Text("Detaljer")) {
                TextField("Størrelse", text: Binding(
                    get: { project.size },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].size = newValue
                        }
                    }
                ))

                TextField("Strikkefasthet", text: Binding(
                    get: { project.gauge },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].gauge = newValue
                        }
                    }
                ))
            }

            Section(header: Text("Pinnestørrelse")) {
                // Dropdown to add needle sizes
                HStack {
                    Picker("Legg til pinnestørrelse", selection: $selectedNeedleSize) {
                        ForEach(NeedleSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .onChange(of: selectedNeedleSize) { newValue in
                        if newValue != .none {
                            if newValue == .other {
                                showCustomNeedleInput = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    isCustomNeedleSizeFocused = true
                                }
                            } else {
                                addNeedleSize(newValue.rawValue)
                                selectedNeedleSize = .none
                            }
                        }
                    }
                }

                // Custom needle size input when "Annet" is selected
                if showCustomNeedleInput {
                    HStack {
                        TextField("Skriv inn pinnestørrelse", text: $customNeedleSize)
                            .keyboardType(.decimalPad)
                            .focused($isCustomNeedleSizeFocused)

                        Button("Legg til") {
                            if !customNeedleSize.isEmpty {
                                addNeedleSize(customNeedleSize)
                                customNeedleSize = ""
                                showCustomNeedleInput = false
                                selectedNeedleSize = .none
                            }
                        }
                        .foregroundColor(.appIconTint)

                        Button("Avbryt") {
                            customNeedleSize = ""
                            showCustomNeedleInput = false
                            selectedNeedleSize = .none
                        }
                        .foregroundColor(.red)
                    }
                }

                // List of selected needle sizes
                if !project.needleSizes.isEmpty {
                    ForEach(Array(project.needleSizes.enumerated()), id: \.offset) { index, size in
                        HStack {
                            Text(size)
                                .font(.system(size: 16))

                            Spacer()

                            Button(action: {
                                removeNeedleSize(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.appSecondaryText)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            Section(header: Text("Datoer")) {
                if let startDate = project.startDate {
                    HStack {
                        DatePicker("Startet", selection: Binding(
                            get: { startDate },
                            set: { newValue in
                                if let index = projectIndex {
                                    projects[index].startDate = newValue
                                }
                            }
                        ), displayedComponents: .date)

                        Button(action: {
                            if let index = projectIndex {
                                projects[index].startDate = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                } else {
                    Button(action: {
                        if let index = projectIndex {
                            projects[index].startDate = Date()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.appIconTint)
                            Text("Legg til startdato")
                                .foregroundColor(.primary)
                        }
                    }
                }

                // Completion date
                if let completedDate = project.completedDate {
                    HStack {
                        DatePicker("Ferdig", selection: Binding(
                            get: { completedDate },
                            set: { newValue in
                                if let index = projectIndex {
                                    projects[index].completedDate = newValue
                                }
                            }
                        ), displayedComponents: .date)

                        Button(action: {
                            if let index = projectIndex {
                                projects[index].completedDate = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.appSecondaryText)
                        }
                    }
                } else {
                    Button(action: {
                        if let index = projectIndex {
                            projects[index].completedDate = Date()
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.appIconTint)
                            Text("Legg til ferdigdato")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }

            Section(header: Text("Garn")) {
                ForEach(project.linkedYarns) { linkedYarn in
                    if let yarn = yarnEntries.first(where: { $0.id == linkedYarn.yarnStashId }) {
                        ProjectYarnItemView(linkedYarn: linkedYarn, yarn: yarn, onDelete: {
                            yarnToDelete = linkedYarn
                        })
                    }
                }

                Button(action: { showAddYarn = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.appIconTint)
                        Text("Legg til garn")
                            .foregroundColor(.primary)
                    }
                }
            }

            Section(header: Text("Notater")) {
                TextEditor(text: Binding(
                    get: { project.notes },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].notes = newValue
                        }
                    }
                ))
                .frame(minHeight: 100)
            }

            ProjectImagesSection(
                projectId: projectId,
                projects: $projects,
                showImagePicker: $showImagePicker,
                imageToDelete: $imageToDelete,
                showGallery: $showImageGallery,
                selectedImageIndex: $selectedImageIndex
            )
            }

            Group {
            Section(header: Text("Omgangsteller")) {
                ForEach(project.rowCounters) { counter in
                    if let counterIndex = project.rowCounters.firstIndex(where: { $0.id == counter.id }) {
                        VStack(spacing: 8) {
                            TextField("Navn", text: Binding(
                                get: { counter.name },
                                set: { newValue in
                                    if let index = projectIndex {
                                        projects[index].rowCounters[counterIndex].name = newValue
                                    }
                                }
                            ))
                            .font(.system(size: 16, weight: .medium))

                            HStack(spacing: 16) {
                                Button(action: {
                                    if let index = projectIndex {
                                        projects[index].rowCounters[counterIndex].count -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appIconTint)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Text("\(counter.count)")
                                    .font(.system(size: 24, weight: .semibold))
                                    .frame(minWidth: 50)

                                Button(action: {
                                    if let index = projectIndex {
                                        projects[index].rowCounters[counterIndex].count += 1
                                    }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.appIconTint)
                                }
                                .buttonStyle(PlainButtonStyle())

                                Spacer()

                                Button(action: {
                                    counterToDelete = counter
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Button(action: {
                    if let index = projectIndex {
                        projects[index].rowCounters.append(RowCounter(name: "Ny teller"))
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.appIconTint)
                        Text("Legg til teller")
                            .foregroundColor(.primary)
                    }
                }
            }

            Section {
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    HStack {
                        Spacer()
                        Text("Slett prosjekt")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            }
        }
    }

    func deleteProject() {
        if let index = projectIndex {
            projects.remove(at: index)
        }
        dismiss()
    }

    func addNeedleSize(_ size: String) {
        guard let index = projectIndex else { return }
        projects[index].needleSizes.append(size)
    }

    func removeNeedleSize(at index: Int) {
        guard let projectIdx = projectIndex else { return }
        projects[projectIdx].needleSizes.remove(at: index)
    }

    func loadYarnEntries() {
        if let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
           let decoded = try? JSONDecoder().decode([YarnStashEntry].self, from: data) {
            yarnEntries = decoded
        }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func handleNewImages(_ images: [UIImage]) {
        guard !images.isEmpty, let idx = projectIndex else { return }
        for img in images {
            if let path = saveImageToFile(img) {
                projects[idx].images.append(path)
                if projects[idx].primaryImageIndex == nil {
                    projects[idx].primaryImageIndex = 0
                }
            }
        }
        selectedImages = []
    }

    func saveImageToFile(_ img: UIImage) -> String? {
        guard let data = img.jpegData(compressionQuality: 0.8) else { return nil }
        let name = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
        try? data.write(to: url)
        return name
    }

    func deleteImage(_ imagePath: String) {
        guard let idx = projectIndex else { return }

        if let imageIndex = projects[idx].images.firstIndex(of: imagePath) {
            // Delete file
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(imagePath)
            try? FileManager.default.removeItem(at: url)

            // Remove from array
            projects[idx].images.remove(at: imageIndex)

            // Update primary index if needed
            if let primaryIdx = projects[idx].primaryImageIndex {
                if primaryIdx == imageIndex {
                    projects[idx].primaryImageIndex = projects[idx].images.isEmpty ? nil : 0
                } else if primaryIdx > imageIndex {
                    projects[idx].primaryImageIndex = primaryIdx - 1
                }
            }
        }
        imageToDelete = nil
    }
}

struct RecipePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedRecipeId: UUID?
    let recipes: [Recipe]

    @State private var projects: [Project] = []

    var recipesInProjects: Set<UUID> {
        Set(projects.compactMap { $0.recipeId })
    }

    func recipesForStatus(_ status: ProjectStatus) -> [Recipe] {
        let projectRecipeIds = Set(projects.filter { $0.status == status }.compactMap { $0.recipeId })
        return recipes.filter { projectRecipeIds.contains($0.id) }
    }

    func hasRecipesForStatus(_ status: ProjectStatus) -> Bool {
        !recipesForStatus(status).isEmpty
    }

    var body: some View {
        NavigationView {
            List {
                // All section - always show
                Section(header: Text("Alle")) {
                    ForEach(recipes) { recipe in
                        RecipePickerRow(
                            recipe: recipe,
                            isSelected: selectedRecipeId == recipe.id,
                            action: {
                                selectedRecipeId = recipe.id
                                dismiss()
                            }
                        )
                    }
                }

                // Planned section - only show if there are recipes in planned projects
                if hasRecipesForStatus(.planned) {
                    Section(header: Text("Planlagt")) {
                        ForEach(recipesForStatus(.planned)) { recipe in
                            RecipePickerRow(
                                recipe: recipe,
                                isSelected: selectedRecipeId == recipe.id,
                                action: {
                                    selectedRecipeId = recipe.id
                                    dismiss()
                                }
                            )
                        }
                    }
                }

                // Active section - only show if there are recipes in active projects
                if hasRecipesForStatus(.active) {
                    Section(header: Text("Aktive")) {
                        ForEach(recipesForStatus(.active)) { recipe in
                            RecipePickerRow(
                                recipe: recipe,
                                isSelected: selectedRecipeId == recipe.id,
                                action: {
                                    selectedRecipeId = recipe.id
                                    dismiss()
                                }
                            )
                        }
                    }
                }

                // Completed section - only show if there are recipes in completed projects
                if hasRecipesForStatus(.completed) {
                    Section(header: Text("Fullført")) {
                        ForEach(recipesForStatus(.completed)) { recipe in
                            RecipePickerRow(
                                recipe: recipe,
                                isSelected: selectedRecipeId == recipe.id,
                                action: {
                                    selectedRecipeId = recipe.id
                                    dismiss()
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Velg oppskrift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if selectedRecipeId != nil {
                        Button(action: {
                            selectedRecipeId = nil
                            dismiss()
                        }) {
                            Text("Fjern oppskrift")
                                .foregroundColor(.red)
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ferdig") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProjects()
            }
        }
    }

    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }
}

struct RecipePickerRow: View {
    let recipe: Recipe
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.appText)

                    Text(recipe.displayCategory)
                        .font(.system(size: 13))
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.appIconTint)
                }
            }
        }
    }
}

struct ProjectYarnItemView: View {
    let linkedYarn: ProjectYarn
    let yarn: YarnStashEntry
    let onDelete: () -> Void
    @ObservedObject private var settings = AppSettings.shared

    var quantityText: String {
        switch linkedYarn.quantityType {
        case .skeins:
            return "\(Int(linkedYarn.quantity)) nøster"
        case .meters:
            return UnitConverter.formatLength(linkedYarn.quantity, unit: settings.currentUnitSystem)
        case .grams:
            return UnitConverter.formatWeight(linkedYarn.quantity, unit: settings.currentUnitSystem)
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(yarn.brand) \(yarn.type)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.appText)

                Text(quantityText)
                    .font(.system(size: 13))
                    .foregroundColor(.appSecondaryText)
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let testProject = Project(name: "Test Prosjekt")
    return NavigationView {
        ProjectDetailView(
            projectId: testProject.id,
            projects: .constant([testProject]),
            recipes: []
        )
    }
}