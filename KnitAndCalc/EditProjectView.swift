//
//  EditProjectView.swift
//  KnitAndCalc
//
//  Edit project view
//

import SwiftUI

struct EditProjectView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var projects: [Project]
    let project: Project
    let recipes: [Recipe]

    @State private var name: String = ""
    @State private var selectedStatus: ProjectStatus = .planned

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informasjon")) {
                    TextField("Prosjektnavn", text: $name)

                    Picker("Status", selection: $selectedStatus) {
                        ForEach(ProjectStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                }
            }
            .navigationTitle("Rediger prosjekt")
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
                loadProjectData()
            }
        }
    }

    func loadProjectData() {
        name = project.name
        selectedStatus = project.status
    }

    func saveProject() {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index].name = name
            projects[index].status = selectedStatus
        }

        dismiss()
    }
}

#Preview {
    EditProjectView(
        projects: .constant([]),
        project: Project(name: "Test"),
        recipes: []
    )
}