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

    @State private var name: String = ""
    @State private var selectedStatus: ProjectStatus = .active

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
                    .foregroundColor(name.isEmpty ? Color(white: 0.7) : Color(red: 0.70, green: 0.65, blue: 0.82))
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
        dismiss()
    }
}

#Preview {
    AddProjectView(projects: .constant([]), recipes: [])
}