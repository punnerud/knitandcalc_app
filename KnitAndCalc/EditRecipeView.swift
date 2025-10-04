//
//  EditRecipeView.swift
//  KnitAndCalc
//
//  Edit recipe view
//

import SwiftUI
import PhotosUI

struct EditRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [Recipe]
    let recipe: Recipe

    @State private var name: String = ""
    @State private var selectedCategory: RecipeCategory = .sweaters
    @State private var newCategoryName: String = ""
    @State private var selectedType: RecipeType = .link
    @State private var linkURL: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var showDocumentPicker: Bool = false
    @State private var pdfURL: URL?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informasjon")) {
                    TextField("Navn på oppskrift", text: $name)

                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(RecipeCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            if category == .custom {
                                Text("(Ny kategori)").tag(category)
                            } else {
                                Text(category.displayName).tag(category)
                            }
                        }
                    }

                    if selectedCategory == .custom {
                        TextField("Navn på ny kategori", text: $newCategoryName)
                            .autocapitalization(.words)
                    }
                }

                Section(header: Text("Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach([RecipeType.pdf, RecipeType.images, RecipeType.link], id: \.self) { type in
                            Label(type.displayName, systemImage: type.iconName).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Innhold")) {
                    switch selectedType {
                    case .link:
                        TextField("https://eksempel.no/oppskrift", text: $linkURL)
                            .keyboardType(.URL)
                            .autocapitalization(.none)

                    case .images:
                        Button(action: { showImagePicker = true }) {
                            HStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                                Text("Velg bilder")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !selectedImages.isEmpty {
                                    Text("\(selectedImages.count)")
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                        }

                        if !selectedImages.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<selectedImages.count, id: \.self) { index in
                                        Image(uiImage: selectedImages[index])
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                }
                            }
                        }

                    case .pdf:
                        Button(action: { showDocumentPicker = true }) {
                            HStack {
                                Image(systemName: "doc.badge.plus")
                                    .foregroundColor(Color(red: 0.70, green: 0.65, blue: 0.82))
                                Text(pdfURL == nil ? "Velg PDF" : "PDF valgt")
                                    .foregroundColor(.primary)
                                Spacer()
                                if let url = pdfURL {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .foregroundColor(Color(white: 0.5))
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rediger oppskrift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { saveRecipe() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(!canSave)
                    .foregroundColor(canSave ? Color(red: 0.70, green: 0.65, blue: 0.82) : Color(white: 0.7))
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $selectedImages)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(pdfURL: $pdfURL)
            }
            .onAppear {
                loadRecipeData()
            }
        }
    }

    var canSave: Bool {
        if name.isEmpty { return false }

        if selectedCategory == .custom && newCategoryName.isEmpty {
            return false
        }

        switch selectedType {
        case .link:
            return !linkURL.isEmpty && linkURL.starts(with: "http")
        case .images:
            return !selectedImages.isEmpty
        case .pdf:
            return pdfURL != nil
        }
    }

    func loadRecipeData() {
        name = recipe.name
        selectedCategory = recipe.category
        newCategoryName = recipe.customCategoryName ?? ""
        selectedType = recipe.type

        switch recipe.type {
        case .link:
            linkURL = recipe.content

        case .images:
            if let data = recipe.content.data(using: .utf8),
               let paths = try? JSONDecoder().decode([String].self, from: data) {
                selectedImages = paths.compactMap { loadImage($0) }
            }

        case .pdf:
            if let url = URL(string: recipe.content) {
                pdfURL = url
            }
        }
    }

    func loadImage(_ filename: String) -> UIImage? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }

    func saveRecipe() {
        var content = ""

        switch selectedType {
        case .link:
            content = linkURL

        case .images:
            // Save images to documents directory
            let imagePaths = selectedImages.compactMap { saveImage($0) }
            if let jsonData = try? JSONEncoder().encode(imagePaths),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                content = jsonString
            }

        case .pdf:
            if let url = pdfURL {
                content = url.absoluteString
            }
        }

        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index].name = name
            recipes[index].category = selectedCategory
            recipes[index].customCategoryName = selectedCategory == .custom ? newCategoryName : nil
            recipes[index].type = selectedType
            recipes[index].content = content
        }

        dismiss()
    }

    func saveImage(_ image: UIImage) -> String? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }

        let filename = UUID().uuidString + ".jpg"
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)

        try? data.write(to: fileURL)
        return filename
    }
}

#Preview {
    EditRecipeView(recipes: .constant([]), recipe: Recipe(
        name: "Test",
        category: .sweaters,
        type: .link,
        content: "https://example.com"
    ))
}