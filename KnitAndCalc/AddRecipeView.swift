//
//  AddRecipeView.swift
//  KnitAndCalc
//
//  Add new recipe view
//

import SwiftUI
import PhotosUI

struct AddRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var recipes: [Recipe]

    @State private var name: String = ""
    @State private var selectedCategory: RecipeCategory = .sweaters
    @State private var newCategoryName: String = ""
    @State private var selectedType: RecipeType = .pdf
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
                                    .foregroundColor(.appIconTint)
                                Text("Velg bilder")
                                    .foregroundColor(.primary)
                                Spacer()
                                if !selectedImages.isEmpty {
                                    Text("\(selectedImages.count)")
                                        .foregroundColor(.appSecondaryText)
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
                                    .foregroundColor(.appIconTint)
                                Text(pdfURL == nil ? "Velg PDF" : "PDF valgt")
                                    .foregroundColor(.primary)
                                Spacer()
                                if let url = pdfURL {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .foregroundColor(.appSecondaryText)
                                        .font(.system(size: 12))
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ny oppskrift")
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
                    .foregroundColor(canSave ? .appIconTint : .appTertiaryText)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $selectedImages)
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker(pdfURL: $pdfURL)
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
                // Create security-scoped bookmark
                let startedAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if startedAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                if let bookmarkData = try? url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    content = bookmarkData.base64EncodedString()
                } else {
                    // Fallback to URL string
                    content = url.absoluteString
                }
            }
        }

        let recipe = Recipe(
            name: name,
            category: selectedCategory,
            customCategoryName: selectedCategory == .custom ? newCategoryName : nil,
            type: selectedType,
            content: content
        )

        recipes.append(recipe)
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

// Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0 // unlimited

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        DispatchQueue.main.async {
                            self.parent.images.append(image)
                        }
                    }
                }
            }
        }
    }
}

// Document Picker for PDF
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var pdfURL: URL?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.pdfURL = urls.first
            parent.dismiss()
        }
    }
}

#Preview {
    AddRecipeView(recipes: .constant([]))
}