//
//  AnnotationToolbarView.swift
//  KnitAndCalc
//
//  SwiftUI toolbar for annotation tools
//

import SwiftUI

struct AnnotationToolbarView: View {
    @Binding var activeTool: AnnotationTool
    @Binding var isLocked: Bool
    @Binding var selectedColor: String
    @Binding var lineWidth: CGFloat
    var hasRuler: Bool = false
    var onToggleRuler: () -> Void = {}
    var onClearAll: () -> Void
    var onClearAllPages: () -> Void = {}
    var onUndo: () -> Void
    var onRedo: () -> Void = {}
    var canUndo: Bool = false
    var canRedo: Bool = false

    @State private var showClearAllConfirmation = false

    let colors = ["FF0000", "0000FF", "00AA00", "FFAA00", "000000", "6b52a3"]

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Tool row - scrollable
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    toolButton(tool: .draw, icon: "pencil.tip", label: "Tegn")
                    toolButton(tool: .eraser, icon: "eraser", label: "Viskelær")
                    toolButton(tool: .rectangle, icon: "rectangle", label: "Rektangel")

                    // Ruler on/off
                    Button(action: onToggleRuler) {
                        VStack(spacing: 2) {
                            Image(systemName: "line.horizontal.3")
                                .font(.system(size: 18))
                            Text("Linjal")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : (hasRuler ? .appIconTint : .appSecondaryText))
                        .frame(width: 52, height: 44)
                        .background(hasRuler && !isLocked ? Color.appButtonBackgroundSelected.opacity(0.3) : Color.clear)
                        .cornerRadius(8)
                    }
                    .disabled(isLocked)

                    // Lock
                    Button(action: {
                        isLocked.toggle()
                        if isLocked {
                            activeTool = .none
                        }
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                                .font(.system(size: 18))
                            Text("Lås")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .orange : .appSecondaryText)
                        .frame(width: 52, height: 44)
                        .background(isLocked ? Color.orange.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                    }

                    // Undo
                    Button(action: onUndo) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 18))
                            Text("Angre")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : (canUndo ? .appSecondaryText : .appSecondaryText.opacity(0.3)))
                        .frame(width: 52, height: 44)
                    }
                    .disabled(isLocked || !canUndo)

                    // Redo
                    Button(action: onRedo) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.system(size: 18))
                            Text("Gjør om")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : (canRedo ? .appSecondaryText : .appSecondaryText.opacity(0.3)))
                        .frame(width: 52, height: 44)
                    }
                    .disabled(isLocked || !canRedo)

                    // Clear current page
                    Button(action: onClearAll) {
                        VStack(spacing: 2) {
                            Image(systemName: "trash")
                                .font(.system(size: 18))
                            Text("Slett")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : .red.opacity(0.8))
                        .frame(width: 52, height: 44)
                    }
                    .disabled(isLocked)

                    // Clear all pages
                    Button(action: { showClearAllConfirmation = true }) {
                        VStack(spacing: 2) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                            Text("Slett alt")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : .red.opacity(0.8))
                        .frame(width: 52, height: 44)
                    }
                    .disabled(isLocked)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            // Color row (hidden when locked)
            if !isLocked && (activeTool == .draw || activeTool == .rectangle || activeTool == .eraser) {
                HStack(spacing: 10) {
                    if activeTool != .eraser {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.appSecondaryText.opacity(0.3), lineWidth: 1)
                                )
                                .onTapGesture { selectedColor = color }
                        }
                    }

                    Spacer()

                    if activeTool == .draw || activeTool == .eraser {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(activeTool == .eraser ? Color.appSecondaryText.opacity(0.3) : Color(hex: selectedColor))
                                .frame(width: lineWidth * 2 + 4, height: lineWidth * 2 + 4)

                            Slider(value: $lineWidth, in: 1...8, step: 1)
                                .frame(width: 70)
                                .tint(activeTool == .eraser ? Color.appSecondaryText : Color(hex: selectedColor))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(Color.appSecondaryBackground)
        .alert("Slett alle markeringer", isPresented: $showClearAllConfirmation) {
            Button("Avbryt", role: .cancel) {}
            Button("Slett alt", role: .destructive) {
                onClearAllPages()
            }
        } message: {
            Text("Er du sikker på at du vil slette alle markeringer på alle sider?")
        }
    }

    @ViewBuilder
    func toolButton(tool: AnnotationTool, icon: String, label: String) -> some View {
        Button(action: {
            activeTool = activeTool == tool ? .none : tool
        }) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 9))
            }
            .foregroundColor(isLocked ? .appSecondaryText.opacity(0.25) : (activeTool == tool ? .appIconTint : .appSecondaryText))
            .frame(width: 52, height: 44)
            .background(activeTool == tool && !isLocked ? Color.appButtonBackgroundSelected.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .disabled(isLocked)
    }
}
