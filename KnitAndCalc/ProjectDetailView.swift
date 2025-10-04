//
//  ProjectDetailView.swift
//  KnitAndCalc
//
//  Project detail view
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @Binding var projects: [Project]
    let recipes: [Recipe]

    @ObservedObject private var settings = AppSettings.shared
    @State private var yarnEntries: [YarnStashEntry] = []
    @State private var showRecipePicker: Bool = false
    @State private var showAddYarn: Bool = false
    @State private var counterToDelete: RowCounter?
    @State private var yarnToDelete: ProjectYarn?

    var linkedRecipe: Recipe? {
        if let recipeId = project.recipeId {
            return recipes.first { $0.id == recipeId }
        }
        return nil
    }

    var projectIndex: Int? {
        projects.firstIndex { $0.id == project.id }
    }

    var body: some View {
        Form {
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
                                .foregroundColor(Color(white: 0.5))
                        }

                        Spacer()

                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            EmptyView()
                        }
                    }

                    Button(action: { showRecipePicker = true }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                            Text("Bytt oppskrift")
                                .foregroundColor(.primary)
                        }
                    }
                } else {
                    Button(action: { showRecipePicker = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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

                TextField("Pinnestørrelse", text: Binding(
                    get: { project.needleSize },
                    set: { newValue in
                        if let index = projectIndex {
                            projects[index].needleSize = newValue
                        }
                    }
                ))

                // Start date
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
                                .foregroundColor(Color(white: 0.6))
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
                                .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                                .foregroundColor(Color(white: 0.6))
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
                                .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                            .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                                        .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                                        .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                            .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                        Text("Legg til teller")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
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
            AddProjectYarnView(projects: $projects, projectId: project.id)
        }
        .onAppear {
            loadYarnEntries()
        }
    }

    func loadYarnEntries() {
        if let data = UserDefaults.standard.data(forKey: "savedYarnStash"),
           let decoded = try? JSONDecoder().decode([YarnStashEntry].self, from: data) {
            yarnEntries = decoded
        }
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
                        .foregroundColor(Color(white: 0.2))

                    Text(recipe.displayCategory)
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
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
                    .foregroundColor(Color(white: 0.2))

                Text(quantityText)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
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
    NavigationView {
        ProjectDetailView(
            project: Project(name: "Test Prosjekt"),
            projects: .constant([]),
            recipes: []
        )
    }
}