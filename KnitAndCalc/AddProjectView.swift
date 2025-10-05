//
//  AddProjectView.swift
//  KnitAndCalc
//
//  Add new project view
//

import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var projects: [Project]
    let recipes: [Recipe]
    var onProjectCreated: ((Project) -> Void)?

    @State private var name: String = ""
    @State private var selectedStatus: ProjectStatus = .active
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informasjon")) {
                    TextField("Prosjektnavn", text: $name)
                        .focused($isNameFieldFocused)

                    Picker("Status", selection: $selectedStatus) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Nytt prosjekt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { saveProject() }) {
                        Text("Lagre")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? .appTertiaryText : .appIconTint)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isNameFieldFocused = true
                }
            }
        }
    }

    func saveProject() {
        let project = Project(
            name: name,
            status: selectedStatus
        )

        projects.append(project)
        onProjectCreated?(project)
        dismiss()
    }
}

#Preview {
    AddProjectView(projects: .constant([]), recipes: [])
}