//
//  RecipeListView.swift
//  KnitAndCalc
//
//  Recipe management view
//

import SwiftUI

struct RecipeListView: View {
    @State private var recipes: [Recipe] = []
    @State private var selectedCategory: RecipeCategory = .all
    @State private var selectedCustomCategory: String?
    @State private var showAddRecipe: Bool = false
    @State private var recipeToDelete: Recipe?
    @State private var recipeToEdit: Recipe?

    var customCategories: [String] {
        let customs = recipes
            .filter { $0.category == .custom }
            .compactMap { $0.customCategoryName }
        return Array(Set(customs)).sorted()
    }

    var filteredRecipes: [Recipe] {
        if selectedCategory == .all {
            return recipes
        }

        if selectedCategory == .custom {
            if let customName = selectedCustomCategory {
                return recipes.filter { $0.category == .custom && $0.customCategoryName == customName }
            }
            return []
        }

        return recipes.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                categoryTabsView
                recipeContentView
            }
            .navigationTitle("Oppskrifter")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddRecipe = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                    }
                }
            }
            .sheet(isPresented: $showAddRecipe) {
                AddRecipeView(recipes: $recipes)
            }
            .sheet(item: $recipeToEdit) { recipe in
                EditRecipeView(recipes: $recipes, recipe: recipe)
            }
            .alert("Slett oppskrift", isPresented: .constant(recipeToDelete != nil), presenting: recipeToDelete) { recipe in
                Button("Avbryt", role: .cancel) {
                    recipeToDelete = nil
                }
                Button("Slett", role: .destructive) {
                    deleteRecipe(recipe)
                }
            } message: { recipe in
                Text("Er du sikker på at du vil slette \"\(recipe.name)\"?")
            }
            .onChange(of: recipes) { _ in
                saveRecipes()
            }
        }
        .onAppear {
            loadRecipes()
        }
    }

    var categoryTabsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecipeCategory.allCases.filter { $0 != .custom }, id: \.self) { category in
                    CategoryTabButton(
                        title: category.displayName,
                        isSelected: selectedCategory == category,
                        action: {
                            withAnimation {
                                selectedCategory = category
                                selectedCustomCategory = nil
                            }
                        }
                    )
                }

                ForEach(customCategories, id: \.self) { customName in
                    CategoryTabButton(
                        title: customName,
                        isSelected: selectedCategory == .custom && selectedCustomCategory == customName,
                        action: {
                            withAnimation {
                                selectedCategory = .custom
                                selectedCustomCategory = customName
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
    }

    var recipeContentView: some View {
        Group {
            if filteredRecipes.isEmpty {
                emptyStateView
            } else {
                recipeListView
            }
        }
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(Color(white: 0.7))
            Text("Ingen oppskrifter")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(white: 0.5))
            Text("Trykk + for å legge til")
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
    }

    var recipeListView: some View {
        List {
            ForEach(filteredRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    RecipeRowView(recipe: recipe)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        recipeToDelete = recipe
                    } label: {
                        Label("Slett", systemImage: "trash")
                    }

                    Button {
                        recipeToEdit = recipe
                    } label: {
                        Label("Rediger", systemImage: "pencil")
                    }
                    .tint(Color(red: 0.70, green: 0.65, blue: 0.82))
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct CategoryTabButton: View {
    private let titleKey: LocalizedStringKey?
    private let titleString: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: LocalizedStringKey, isSelected: Bool, action: @escaping () -> Void) {
        self.titleKey = title
        self.titleString = nil
        self.isSelected = isSelected
        self.action = action
    }

    init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.titleKey = nil
        self.titleString = title
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let titleKey = titleKey {
                    Text(titleKey)
                } else if let titleString = titleString {
                    Text(titleString)
                } else {
                    Text("")
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(isSelected ? .white : Color(white: 0.45))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ?
                Color(red: 0.70, green: 0.65, blue: 0.82) :
                Color(red: 0.93, green: 0.92, blue: 0.95))
            .cornerRadius(16)
        }
    }
}

extension RecipeListView {
    func deleteRecipe(_ recipe: Recipe) {
        recipes.removeAll { $0.id == recipe.id }
        recipeToDelete = nil
        saveRecipes()
    }

    func loadRecipes() {
        if let data = UserDefaults.standard.data(forKey: "savedRecipes"),
           let decoded = try? JSONDecoder().decode([Recipe].self, from: data) {
            recipes = decoded
        }
    }

    func saveRecipes() {
        if let encoded = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(encoded, forKey: "savedRecipes")
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {
            // Icon based on type
            ZStack {
                Circle()
                    .fill(Color(red: 0.93, green: 0.92, blue: 0.95))
                    .frame(width: 44, height: 44)

                Image(systemName: recipe.type.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(white: 0.2))

                Text(recipe.displayCategory)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.5))
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

enum RecipeCategory: String, CaseIterable, Codable {
    case all = "all"
    case sweaters = "sweaters"
    case pants = "pants"
    case hats = "hats"
    case socks = "socks"
    case mittens = "mittens"
    case custom = "custom"

    var displayName: LocalizedStringKey {
        switch self {
        case .all: return "Alle"
        case .sweaters: return "Gensere"
        case .pants: return "Bukser"
        case .hats: return "Luer"
        case .socks: return "Sokker"
        case .mittens: return "Votter"
        case .custom: return "Egendefinert"
        }
    }
}

enum RecipeType: String, Codable {
    case pdf
    case images
    case link

    var iconName: String {
        switch self {
        case .pdf: return "doc.fill"
        case .images: return "photo.fill"
        case .link: return "link"
        }
    }

    var displayName: String {
        switch self {
        case .pdf: return "PDF"
        case .images: return "Bilder"
        case .link: return "Nettside"
        }
    }
}

struct Recipe: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var category: RecipeCategory
    var customCategoryName: String? // Used when category is .custom
    var type: RecipeType
    var content: String // URL for link, file path for PDF, or JSON array of image paths
    var dateAdded: Date

    init(id: UUID = UUID(), name: String, category: RecipeCategory, customCategoryName: String? = nil, type: RecipeType, content: String, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.category = category
        self.customCategoryName = customCategoryName
        self.type = type
        self.content = content
        self.dateAdded = dateAdded
    }

    var displayCategory: String {
        if category == .custom, let customName = customCategoryName {
            return customName
        }
        switch category {
        case .all: return String(localized: "Alle")
        case .sweaters: return String(localized: "Gensere")
        case .pants: return String(localized: "Bukser")
        case .hats: return String(localized: "Luer")
        case .socks: return String(localized: "Sokker")
        case .mittens: return String(localized: "Votter")
        case .custom: return String(localized: "Egendefinert")
        }
    }
}

#Preview {
    RecipeListView()
}