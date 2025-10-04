//
//  ProjectListView.swift
//  KnitAndCalc
//
//  Project management view
//

import SwiftUI

struct ProjectListView: View {
    @State private var projects: [Project] = []
    @State private var recipes: [Recipe] = []
    @State private var selectedStatus: ProjectStatus = .active
    @State private var selectedCategory: String? = nil
    @State private var showAddProject: Bool = false
    @State private var projectToDelete: Project?
    @State private var projectToEdit: Project?

    var categoriesForCurrentStatus: [String] {
        let projectsInStatus = projects.filter { $0.status == selectedStatus }
        var categories: Set<String> = []

        for project in projectsInStatus {
            if let recipeId = project.recipeId,
               let recipe = recipes.first(where: { $0.id == recipeId }) {
                categories.insert(recipe.displayCategory)
            }
        }

        return Array(categories).sorted()
    }

    var filteredProjects: [Project] {
        let statusFiltered = projects.filter { $0.status == selectedStatus }

        guard let category = selectedCategory else {
            return statusFiltered
        }

        return statusFiltered.filter { project in
            if let recipeId = project.recipeId,
               let recipe = recipes.first(where: { $0.id == recipeId }) {
                return recipe.displayCategory == category
            }
            return false
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            statusTabsView
            if !categoriesForCurrentStatus.isEmpty {
                categoryTabsView
            }
            projectContentView
        }
        .navigationTitle("Prosjekter")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddProject = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                    }
                }
            }
            .sheet(isPresented: $showAddProject) {
                AddProjectView(projects: $projects, recipes: recipes)
            }
            .sheet(item: $projectToEdit) { project in
                EditProjectView(projects: $projects, project: project, recipes: recipes)
            }
            .alert("Slett prosjekt", isPresented: .constant(projectToDelete != nil), presenting: projectToDelete) { project in
                Button("Avbryt", role: .cancel) {
                    projectToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    deleteProject(project)
                }
            } message: { project in
                Text("Er du sikker på at du vil slette \"\(project.name)\"?")
            }
            .onChange(of: projects) { _ in
                saveProjects()
            }
            .onAppear {
                loadProjects()
                loadRecipes()
            }
    }

    var statusTabsView: some View {
        HStack(spacing: 8) {
            ForEach(ProjectStatus.allCases, id: \.self) { status in
                Button(action: {
                    withAnimation {
                        selectedStatus = status
                        selectedCategory = nil
                    }
                }) {
                    Text(status.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(selectedStatus == status ? .white : Color(white: 0.45))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedStatus == status ?
                            Color(red: 0.70, green: 0.65, blue: 0.82) :
                            Color(red: 0.93, green: 0.92, blue: 0.95))
                        .cornerRadius(16)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }

    var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation {
                        selectedCategory = nil
                    }
                }) {
                    Text("Alle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(selectedCategory == nil ? .white : Color(white: 0.45))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == nil ?
                            Color(red: 0.70, green: 0.65, blue: 0.82) :
                            Color(red: 0.93, green: 0.92, blue: 0.95))
                        .cornerRadius(12)
                }

                ForEach(categoriesForCurrentStatus, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .white : Color(white: 0.45))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedCategory == category ?
                                Color(red: 0.70, green: 0.65, blue: 0.82) :
                                Color(red: 0.93, green: 0.92, blue: 0.95))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 40)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }

    var projectContentView: some View {
        Group {
            if filteredProjects.isEmpty {
                emptyStateView
            } else {
                projectListView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(Color(white: 0.7))
            Text("Ingen prosjekter")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(white: 0.5))
            Text("Trykk + for å legge til")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }

    var projectListView: some View {
        List {
            ForEach(filteredProjects) { project in
                NavigationLink(destination: ProjectDetailView(project: project, projects: $projects, recipes: recipes)) {
                    ProjectRowView(project: project, recipes: recipes)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        projectToDelete = project
                    } label: {
                        Label("Slett", systemImage: "trash")
                    }

                    Button {
                        projectToEdit = project
                    } label: {
                        Label("Rediger", systemImage: "pencil")
                    }
                    .tint(Color(red: 0.70, green: 0.65, blue: 0.82))
                }
            }
        }
        .listStyle(PlainListStyle())
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        projectToDelete = nil
        saveProjects()
    }

    func loadProjects() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects"),
           let decoded = try? JSONDecoder().decode([Project].self, from: data) {
            projects = decoded
        }
    }

    func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: "savedRecipes"),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        }
    }

    func saveProjects() {
        if let encoded = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(encoded, forKey: "savedProjects")
        }
    }
}

struct ProjectRowView: View {
    let project: Project
    let recipes: [Recipe]

    var linkedRecipe: Recipe? {
        if let recipeId = project.recipeId {
            return recipes.first { $0.id == recipeId }
        }
        return nil
    }

    var dateToDisplay: Date? {
        switch project.status {
        case .planned, .active:
            return project.startDate
        case .completed:
            return project.completedDate
        }
    }

    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.93, green: 0.92, blue: 0.95))
                    .frame(width: 44, height: 44)

                Image(systemName: project.status.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(white: 0.2))

                if let recipe = linkedRecipe {
                    Text("\(recipe.name) • \(recipe.displayCategory)")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.5))
                }
            }

            Spacer()

            if let date = dateToDisplay {
                Text(formatDate(date))
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
            }
        }
        .padding(.vertical, 8)
    }
}

enum ProjectStatus: String, CaseIterable, Codable {
    case planned = "planned"
    case active = "active"
    case completed = "completed"

    var displayName: LocalizedStringKey {
        switch self {
        case .planned: return "Planlagt"
        case .active: return "Aktive"
        case .completed: return "Fullført"
        }
    }

    var iconName: String {
        switch self {
        case .planned: return "calendar"
        case .active: return "arrow.right.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
}

struct RowCounter: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var count: Int

    init(id: UUID = UUID(), name: String, count: Int = 0) {
        self.id = id
        self.name = name
        self.count = count
    }
}

enum YarnQuantityType: String, Codable, CaseIterable {
    case skeins = "nøster"
    case meters = "meter"
    case grams = "gram"

    var displayName: LocalizedStringKey {
        switch self {
        case .skeins: return "nøster"
        case .meters: return "meter"
        case .grams: return "gram"
        }
    }
}

struct ProjectYarn: Identifiable, Codable, Equatable {
    var id: UUID
    var yarnStashId: UUID
    var quantityType: YarnQuantityType
    var quantity: Double
    var dateAdded: Date

    init(id: UUID = UUID(), yarnStashId: UUID, quantityType: YarnQuantityType, quantity: Double, dateAdded: Date = Date()) {
        self.id = id
        self.yarnStashId = yarnStashId
        self.quantityType = quantityType
        self.quantity = quantity
        self.dateAdded = dateAdded
    }
}

struct Project: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var status: ProjectStatus
    var recipeId: UUID?
    var size: String
    var gauge: String
    var needleSize: String
    var startDate: Date?
    var completedDate: Date?
    var notes: String
    var rowCounters: [RowCounter]
    var linkedYarns: [ProjectYarn]
    var dateCreated: Date

    init(id: UUID = UUID(), name: String, status: ProjectStatus = .planned, recipeId: UUID? = nil, size: String = "", gauge: String = "", needleSize: String = "", startDate: Date? = nil, completedDate: Date? = nil, notes: String = "", rowCounters: [RowCounter] = [], linkedYarns: [ProjectYarn] = [], dateCreated: Date = Date()) {
        self.id = id
        self.name = name
        self.status = status
        self.recipeId = recipeId
        self.size = size
        self.gauge = gauge
        self.needleSize = needleSize
        self.startDate = startDate
        self.completedDate = completedDate
        self.notes = notes
        self.rowCounters = rowCounters
        self.linkedYarns = linkedYarns
        self.dateCreated = dateCreated
    }
}

#Preview {
    ProjectListView()
}