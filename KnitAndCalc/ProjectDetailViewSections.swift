//
//  ProjectDetailViewSections.swift
//  KnitAndCalc
//
//  Separate view components for ProjectDetailView
//

import SwiftUI
import Photos

// MARK: - Images Section
struct ProjectImagesSection: View {
    let projectId: UUID
    @Binding var projects: [Project]
    @Binding var showImagePicker: Bool
    @Binding var imageToDelete: String?
    @Binding var showGallery: Bool
    @Binding var selectedImageIndex: Int

    var project: Project {
        projects.first { $0.id == projectId } ?? Project(name: "")
    }

    var projectIndex: Int? {
        projects.firstIndex { $0.id == projectId }
    }

    var body: some View {
        Section(header: Text("Bilder")) {
            if !project.images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(project.images.enumerated()), id: \.offset) { index, imagePath in
                            imageCard(index: index, imagePath: imagePath)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button(action: { showImagePicker = true }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .foregroundColor(.appIconTint)
                    Text("Legg til bilder")
                        .foregroundColor(.primary)
                    Spacer()
                    if !project.images.isEmpty {
                        Text("\(project.images.count)")
                            .foregroundColor(.appSecondaryText)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showGallery) {
            ProjectImageGalleryView(
                projectId: projectId,
                projects: $projects,
                initialIndex: selectedImageIndex,
                onDismiss: { showGallery = false }
            )
        }
    }

    func imageCard(index: Int, imagePath: String) -> some View {
        VStack(spacing: 6) {
            if let image = loadImage(imagePath) {
                Button(action: {
                    selectedImageIndex = index
                    showGallery = true
                }) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(project.primaryImageIndex == index ? Color.appIconTint : Color.clear, lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
            }

            if project.primaryImageIndex == index {
                Text("Hovedbilde")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.appIconTint)
            }

            Button(action: {
                imageToDelete = imagePath
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
    }

    func setPrimaryImage(_ index: Int) {
        guard let idx = projectIndex else { return }
        projects[idx].primaryImageIndex = index
    }

    func loadImage(_ filename: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }
}

// MARK: - Image Gallery
struct ProjectImageGalleryItem: Identifiable {
    let id = UUID()
    let index: Int
}

struct ProjectImageGalleryView: View {
    let projectId: UUID
    @Binding var projects: [Project]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int
    @State private var showSaveConfirmation = false
    @State private var saveError: String?

    var project: Project {
        projects.first { $0.id == projectId } ?? Project(name: "")
    }

    var projectIndex: Int? {
        projects.firstIndex { $0.id == projectId }
    }

    init(projectId: UUID, projects: Binding<[Project]>, initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.projectId = projectId
        self._projects = projects
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(project.images.enumerated()), id: \.offset) { index, imagePath in
                    if let image = loadImage(imagePath) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                HStack {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                            .padding()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        setPrimaryImage(currentIndex)
                    }) {
                        Image(systemName: project.primaryImageIndex == currentIndex ? "star.fill" : "star")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                            .padding()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(action: {
                        showSaveConfirmation = true
                    }) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 3)
                            .padding()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                Spacer()
                    .allowsHitTesting(false)
            }
            .allowsHitTesting(true)
        }
        .alert("Lagre bilde", isPresented: $showSaveConfirmation) {
            Button("Avbryt", role: .cancel) {}
            Button("Lagre") {
                saveCurrentImage()
            }
        } message: {
            Text("Vil du lagre dette bildet til fotoalbum?")
        }
        .alert("Feil", isPresented: .constant(saveError != nil), presenting: saveError) { _ in
            Button("OK") {
                saveError = nil
            }
        } message: { error in
            Text(error)
        }
    }

    func loadImage(_ filename: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        if let data = try? Data(contentsOf: url) {
            return UIImage(data: data)
        }
        return nil
    }

    func setPrimaryImage(_ index: Int) {
        guard let idx = projectIndex else { return }
        projects[idx].primaryImageIndex = index
    }

    func saveCurrentImage() {
        guard currentIndex < project.images.count,
              let image = loadImage(project.images[currentIndex]) else {
            saveError = "Kunne ikke laste bildet"
            return
        }

        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                } else {
                    self.saveError = "Du må gi tilgang til fotoalbum i Innstillinger"
                }
            }
        }
    }
}
